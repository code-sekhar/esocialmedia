// Explicit invocation only: real isolated backend + synthetic Mailpit recipients.
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/core/auth/auth_api.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/auth_models.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';

void main() {
  const base = String.fromEnvironment('AUTH_TEST_API');
  const mail = String.fromEnvironment('AUTH_TEST_MAIL');
  if (!base.startsWith('http://127.0.0.1:') ||
      !mail.startsWith('http://127.0.0.1:')) {
    throw StateError('Explicit isolated loopback services required');
  }
  AuthSession client() => AuthSession(
    api: AuthApi(baseUrl: base),
    store: MemoryRefreshStore(),
  );
  Future<dynamic> json(String path) async {
    final http = HttpClient();
    try {
      final req = await http.getUrl(Uri.parse('$mail$path'));
      final res = await req.close();
      return jsonDecode(await utf8.decoder.bind(res).join());
    } finally {
      http.close(force: true);
    }
  }

  Future<String> code(String email, [String subject = 'Verification']) async {
    for (var retry = 0; retry < 100; retry++) {
      final list = await json('/api/v1/messages');
      for (final m in list['messages'] as List) {
        if ((m['To'] as List).any((t) => t['Address'] == email) &&
            (m['Subject'] as String).contains(subject)) {
          final detail = await json('/api/v1/message/${m['ID']}');
          final found = RegExp(
            r'>([0-9]{6})</',
          ).firstMatch(detail['HTML'] as String);
          if (found != null) return found.group(1)!;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('Synthetic mail delivery timed out');
  }

  test(
    'real profile, optional astrology consent and validated avatar persistence',
    () async {
      final auth = client();
      final id = DateTime.now().microsecondsSinceEpoch;
      final email = 'privacy_$id@example.invalid';
      try {
        await auth.register(
          Registration(
            email: email,
            username: 'privacy_$id',
            displayName: 'Synthetic Privacy',
            password: 'synthetic secure passphrase',
          ),
        );
        await auth.verifyEmail(email, await code(email));
        await auth.login(email, 'synthetic secure passphrase');
        await auth.change(
          'users/me/profile',
          ProfilePatch(
            'Updated Flutter',
            'Synthetic bio',
            'PUBLIC',
            0,
          ).toJson(),
        );
        expect(auth.account!.displayName, 'Updated Flutter');
        expect(auth.account!.visibility, 'PUBLIC');
        await auth.change(
          'users/me/astrology',
          AstrologyPatch(
            date: '2000-01-01',
            known: false,
            place: 'Synthetic birthplace',
            timezone: 'Asia/Kolkata',
            consent: true,
            adult: true,
            revision: 0,
          ).toJson(),
        );
        expect(auth.account!.astrology!.known, isFalse);
        expect(auth.account!.astrology!.minutes, isNull);
        expect(auth.account!.astrology!.consentAt, isNotNull);
        await auth.change('users/me/astrology/withdraw', {
          'expectedRevision': 1,
        }, method: 'POST');
        expect(auth.account!.astrology!.consentAt, isNull);
        expect(auth.account!.astrology!.place, 'Synthetic birthplace');
        const fixture = String.fromEnvironment('PROFILE_TEST_AVATAR');
        if (fixture.isEmpty) {
          throw StateError('Real synthetic PNG fixture required');
        }
        await auth.change(
          'users/me/avatar',
          FormData.fromMap({
            'avatar': MultipartFile.fromBytes(
              await File(fixture).readAsBytes(),
              filename: 'avatar.png',
              contentType: DioMediaType('image', 'png'),
            ),
          }),
          method: 'POST',
        );
        expect(auth.account!.avatarUrl, startsWith('/api/v1/users/avatar/'));
        expect((await auth.avatar())!.length, greaterThan(0));
        await auth.change('users/me/avatar', {}, method: 'DELETE');
        expect(auth.account!.avatarUrl, isNull);
        final exported = await auth.privacy(
          'export',
          password: 'synthetic secure passphrase',
        );
        expect((exported['account'] as Map)['email'], email);
        expect((exported['account'] as Map).containsKey('password'), isFalse);
        final receipt = await auth.privacy(
          'deletion-request',
          password: 'synthetic secure passphrase',
        );
        expect(receipt['erasureEnabled'], isFalse);
        expect(auth.authenticated, isFalse);
        await auth.login(email, 'synthetic secure passphrase');
        await auth.privacy(
          'deletion-request/cancel',
          password: 'synthetic secure passphrase',
        );
        await auth.logout();
      } finally {
        auth.api.dio.close(force: true);
        auth.dispose();
      }
    },
  );
}
