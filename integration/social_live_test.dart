// Explicit invocation only: real isolated backend + synthetic Mailpit recipients.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/core/auth/auth_api.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/auth_models.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';
import 'package:esocialmedia/features/social/social_api.dart';

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
    'real text posts, private/public audience, edit, removal and export',
    () async {
      final owner = client(), viewer = client();
      final nonce = DateTime.now().microsecondsSinceEpoch;
      Future<void> signup(AuthSession auth, String suffix) async {
        final email = 'social_${nonce}_$suffix@example.invalid';
        await auth.register(
          Registration(
            email: email,
            username: 'social_${nonce}_$suffix',
            displayName: 'Synthetic Social',
            password: 'synthetic secure passphrase',
          ),
        );
        await auth.verifyEmail(email, await code(email));
        await auth.login(email, 'synthetic secure passphrase');
      }

      try {
        await signup(owner, 'a');
        await signup(viewer, 'b');
        final api = SocialApi(owner), other = SocialApi(viewer);
        final private = await api.create(
          'বাংলা हिन्दी <script>inert text</script>',
          'PRIVATE',
        );
        expect(
          (await api.page(mine: true)).items.any((p) => p.id == private.id),
          isTrue,
        );
        expect(
          (await other.page()).items.any((p) => p.id == private.id),
          isFalse,
        );
        final public = await api.edit(private, 'Updated public text', 'PUBLIC');
        expect(public.revision, 1);
        final seen = (await other.page()).items.firstWhere(
          (p) => p.id == private.id,
        );
        expect(seen.displayName, isNull);
        expect(seen.username, owner.account!.username);
        await expectLater(
          other.edit(public, 'Forbidden', 'PUBLIC'),
          throwsA(isA<AuthFailure>()),
        );
        await api.remove(public);
        expect(
          (await other.page()).items.any((p) => p.id == private.id),
          isFalse,
        );
        final exported = await owner.privacy(
          'export',
          password: 'synthetic secure passphrase',
        );
        expect(
          (exported['posts'] as List).any(
            (p) => (p as Map)['id'] == private.id,
          ),
          isTrue,
        );
        await owner.logout();
        await viewer.logout();
      } finally {
        owner.dispose();
        viewer.dispose();
      }
    },
  );
}
