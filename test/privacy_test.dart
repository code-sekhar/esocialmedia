import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/auth_scope.dart';
import 'package:esocialmedia/core/auth/auth_api.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';
import 'package:esocialmedia/features/privacy/privacy_screen.dart';
import 'package:esocialmedia/core/l10n/auth_copy.dart';
import 'package:esocialmedia/core/auth/auth_models.dart';

void main() {
  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('guest privacy is protected and readable at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = AuthSession(api: AuthApi(), store: MemoryRefreshStore());
      addTearDown(session.dispose);
      await tester.pumpWidget(
        AuthScope(
          session: session,
          child: const MaterialApp(home: PrivacyScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('Sign in from your account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('Bengali and Hindi provide privacy action and error copy', () {
    final previous = AuthCopy.language.value;
    try {
      AuthCopy.language.value = 'bn';
      expect(
        AuthCopy.text('currentPassword'),
        isNot(AuthCopy.english['currentPassword']),
      );
      AuthCopy.language.value = 'hi';
      expect(
        AuthCopy.text('cancelDeletion'),
        isNot(AuthCopy.english['cancelDeletion']),
      );
      expect(
        AuthCopy.error(const AuthFailure(AuthProblem.conflict)),
        isNot(AuthCopy.english['conflict']),
      );
    } finally {
      AuthCopy.language.value = previous;
    }
  });
}
