// Explicit opt-in smoke test with a previously verified synthetic account.
// No registration, account deletion, password mutation or SMTP operations.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/core/auth/auth_api.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';

void main() {
  const file = String.fromEnvironment('LOCAL_LOGIN_ACTOR_FILE');
  const api = String.fromEnvironment('LOCAL_LOGIN_API');
  test(
    'real login, owner profile, feed, rotation, logout and memory restoration',
    () async {
      final uri = Uri.parse(api);
      expect(uri.scheme, 'http');
      expect(['127.0.0.1', 'localhost'], contains(uri.host));
      expect(uri.path, '/api/v1/');
      expect(file, isNotEmpty);
      final actor =
          jsonDecode(await File(file).readAsString()) as Map<String, dynamic>;
      final session = AuthSession(
        api: AuthApi(baseUrl: api),
        store: MemoryRefreshStore(),
      );
      try {
        await session.restore();
        expect(session.authenticated, isFalse);
        await session.login(
          actor['email'] as String,
          actor['password'] as String,
        );
        expect(session.authenticated, isTrue);
        await session.profile();
        await session.social('feed/home', method: 'GET');
        await session.rotate();
        await session.profile();
        expect(session.authenticated, isTrue);
        await session.logout();
        expect(session.authenticated, isFalse);
        expect(session.account, isNull);
        final fresh = AuthSession(
          api: AuthApi(baseUrl: api),
          store: MemoryRefreshStore(),
        );
        await fresh.restore();
        expect(fresh.authenticated, isFalse);
        fresh.dispose();
      } finally {
        if (session.authenticated) await session.logout();
        session.dispose();
      }
    },
    skip: file.isEmpty || api.isEmpty
        ? 'Requires explicit loopback API and protected synthetic account file'
        : false,
  );
}
