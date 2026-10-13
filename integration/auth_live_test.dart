// Explicit invocation only: real isolated backend + synthetic Mailpit recipients.
import 'dart:convert';
import 'dart:io';
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
    'real registration verification login profile rotation and current logout',
    () async {
      final auth = client();
      final id = DateTime.now().microsecondsSinceEpoch;
      final email = 'flutter_$id@example.invalid';
      try {
        await auth.register(
          Registration(
            email: email,
            username: 'flutter_$id',
            displayName: 'Synthetic Flutter',
            password: 'synthetic secure passphrase',
          ),
        );
        expect(auth.authenticated, isFalse);
        await expectLater(
          auth.login(email, 'synthetic secure passphrase'),
          throwsA(isA<AuthFailure>()),
        );
        await auth.verifyEmail(email, await code(email));
        await auth.login(email, 'synthetic secure passphrase');
        expect((await auth.profile()).email, email);
        await Future.wait([auth.rotate(), auth.rotate()]);
        expect((await auth.profile()).email, email);
        await auth.logout();
        expect(auth.authenticated, isFalse);
      } finally {
        auth.api.dio.close(force: true);
        auth.dispose();
      }
    },
  );
  test(
    'real password recovery revokes previous sessions and permits new password',
    () async {
      final auth = client();
      final id = DateTime.now().microsecondsSinceEpoch;
      final email = 'reset_$id@example.invalid';
      try {
        await auth.register(
          Registration(
            email: email,
            username: 'reset_$id',
            displayName: 'Synthetic Recovery',
            password: 'synthetic secure passphrase',
          ),
        );
        await auth.verifyEmail(email, await code(email));
        await auth.login(email, 'synthetic secure passphrase');
        await auth.forgot(email);
        final grant = await auth.verifyReset(
          email,
          await code(email, 'Password'),
        );
        await auth.reset(grant, 'replacement secure passphrase');
        await expectLater(
          auth.login(email, 'synthetic secure passphrase'),
          throwsA(isA<AuthFailure>()),
        );
        await auth.login(email, 'replacement secure passphrase');
        expect((await auth.profile()).email, email);
        await auth.logout();
      } finally {
        auth.api.dio.close(force: true);
        auth.dispose();
      }
    },
  );
  test(
    'real logout-all invalidates another client on next authorization',
    () async {
      final first = client(), second = client();
      final id = DateTime.now().microsecondsSinceEpoch;
      final email = 'all_$id@example.invalid';
      try {
        await first.register(
          Registration(
            email: email,
            username: 'all_$id',
            displayName: 'Synthetic Devices',
            password: 'synthetic secure passphrase',
          ),
        );
        await first.verifyEmail(email, await code(email));
        await first.login(email, 'synthetic secure passphrase');
        await second.login(email, 'synthetic secure passphrase');
        await first.logout(all: true);
        await expectLater(second.profile(), throwsA(isA<AuthFailure>()));
        expect(second.authenticated, isFalse);
      } finally {
        for (final auth in [first, second]) {
          auth.api.dio.close(force: true);
          auth.dispose();
        }
      }
    },
  );
}
