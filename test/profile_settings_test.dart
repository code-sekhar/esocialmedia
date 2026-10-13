import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:esocialmedia/screen/dashboard/profile/profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/core/auth/auth_models.dart';
import 'package:esocialmedia/core/auth/auth_api.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/auth_scope.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';
import 'package:esocialmedia/features/profiles/profile_settings_screen.dart';

class ProfileTransport implements HttpClientAdapter {
  final user = {
    'id': 'synthetic',
    'email': 'synthetic@example.invalid',
    'username': 'synthetic',
    'profile': {
      'displayName': 'Actual Account Name',
      'bio': 'Actual private bio',
      'avatarUrl': null,
      'visibility': 'PRIVATE',
      'revision': 0,
    },
    'astrologyProfile': null,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => ResponseBody.fromString(
    jsonEncode(
      options.path == 'auth/login'
          ? {'user': user, 'accessToken': 'access', 'refreshToken': 'a' * 128}
          : user,
    ),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  test('unknown-time request never sends invented minutes', () {
    final body = AstrologyPatch(
      date: '2000-01-01',
      known: false,
      place: '',
      timezone: '',
      consent: true,
      adult: true,
      revision: 0,
    ).toJson();
    expect(body.containsKey('birthTimeMinutes'), isFalse);
    expect(body['visibility'], 'PRIVATE');
  });
  test(
    'profile request excludes username, birth data and arbitrary avatar paths',
    () {
      final body = ProfilePatch('Name', 'Bio', 'PRIVATE', 1).toJson();
      expect(body.keys.toSet(), {
        'displayName',
        'bio',
        'visibility',
        'expectedRevision',
      });
    },
  );
  testWidgets('private settings require an authenticated session', (
    tester,
  ) async {
    final auth = AuthSession(api: AuthApi(), store: MemoryRefreshStore());
    await tester.pumpWidget(
      AuthScope(
        session: auth,
        child: const MaterialApp(home: ProfileSettingsScreen(astrology: true)),
      ),
    );
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('Log in'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    auth.api.dio.close(force: true);
    auth.dispose();
  });
  for (final width in [320.0, 768.0, 1440.0]) {
    for (final astrology in [false, true]) {
      testWidgets(
        'authenticated settings $astrology render at $width without overflow',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1/'));
          dio.httpClientAdapter = ProfileTransport();
          final auth = AuthSession(
            api: AuthApi(client: dio),
            store: MemoryRefreshStore(),
          );
          await tester.runAsync(
            () => auth.login(
              'synthetic@example.invalid',
              'synthetic secure passphrase',
            ),
          );
          await tester.pumpWidget(
            AuthScope(
              session: auth,
              child: MaterialApp(
                home: ProfileSettingsScreen(astrology: astrology),
              ),
            ),
          );
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (astrology) {
            expect(find.byType(CheckboxListTile), findsNWidgets(3));
            expect(
              (tester.widget<CheckboxListTile>(
                find.byType(CheckboxListTile).last,
              )).value,
              isFalse,
            );
          }
          await tester.pumpWidget(const SizedBox());
          dio.close(force: true);
          auth.dispose();
        },
      );
    }
  }
  testWidgets(
    'existing profile header uses the authenticated identity and bio',
    (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1/'));
      dio.httpClientAdapter = ProfileTransport();
      final auth = AuthSession(
        api: AuthApi(client: dio),
        store: MemoryRefreshStore(),
      );
      await tester.runAsync(
        () => auth.login(
          'synthetic@example.invalid',
          'synthetic secure passphrase',
        ),
      );
      await tester.pumpWidget(
        AuthScope(
          session: auth,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Actual Account Name'), findsOneWidget);
      expect(find.text('Actual private bio'), findsOneWidget);
      expect(find.text('Salena Gomes'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      dio.close(force: true);
      auth.dispose();
    },
  );
}
