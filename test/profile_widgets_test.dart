import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/core/auth/auth_api.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/auth_scope.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';
import 'package:esocialmedia/features/profiles/profile_settings_screen.dart';
import 'package:esocialmedia/screen/dashboard/profile/profile_screen.dart';

class ProfileAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final user = {
      'id': 'synthetic',
      'email': 'synthetic@example.invalid',
      'username': 'synthetic',
      'profile': {
        'displayName': 'Real account fixture',
        'bio': 'Real bio fixture',
        'avatarUrl': null,
        'visibility': 'PRIVATE',
        'revision': 0,
      },
      'astrologyProfile': null,
      'completeness': {'completed': 2, 'total': 3},
    };
    return ResponseBody.fromString(
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
  }
}

Future<AuthSession> session() async {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1/'));
  dio.httpClientAdapter = ProfileAdapter();
  final auth = AuthSession(
    api: AuthApi(client: dio),
    store: MemoryRefreshStore(),
  );
  await auth.login('synthetic@example.invalid', 'synthetic secure passphrase');
  return auth;
}

void main() {
  for (final width in [320.0, 768.0, 1440.0]) {
    for (final astrology in [false, true]) {
      testWidgets(
        'authenticated settings $astrology render at $width without default consent',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final auth = (await tester.runAsync(session))!;
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
            expect(
              tester
                  .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
                  .every((box) => box.value == false),
              isTrue,
            );
          } else {
            expect(
              find.widgetWithText(TextFormField, 'Real account fixture'),
              findsOneWidget,
            );
          }
          await tester.pumpWidget(const SizedBox());
          auth.api.dio.close(force: true);
          auth.dispose();
        },
      );
    }
  }
  testWidgets(
    'existing own-profile design renders actual account identity and honest chart status',
    (tester) async {
      final auth = (await tester.runAsync(session))!;
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
      expect(find.text('Real account fixture'), findsOneWidget);
      expect(find.text('Real bio fixture'), findsOneWidget);
      expect(find.text('Salena Gomes'), findsNothing);
      expect(find.text('☀️ ♌ Leo'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.api.dio.close(force: true);
      auth.dispose();
    },
  );
}
