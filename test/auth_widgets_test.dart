import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/core/auth/auth_api.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/auth_scope.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';
import 'package:esocialmedia/screen/login_screen.dart';
import 'package:esocialmedia/screen/onboarding_cosmic_identity_screen.dart';
import 'package:esocialmedia/screen/forgot/forgot_password_screen.dart';
import 'package:esocialmedia/screen/forgot/otp_verification_screen.dart';
import 'package:esocialmedia/screen/forgot/create_new_password_screen.dart';
import 'package:esocialmedia/screen/dashboard/home_screen.dart';

void main() {
  for (final width in [320.0, 768.0, 1440.0]) {
    for (final entry in <String, Widget>{
      'login': const LoginScreen(),
      'registration': const OnboardingCosmicIdentityScreen(),
      'forgot': const ForgotPasswordScreen(),
      'verification': const OtpVerificationScreen(
        email: 'synthetic@example.invalid',
        verification: true,
      ),
      'reset': const CreateNewPasswordScreen(
        resetToken: 'synthetic-test-grant',
      ),
    }.entries) {
      testWidgets('${entry.key} preserves layout at $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final session = AuthSession(
          api: AuthApi(),
          store: MemoryRefreshStore(),
        );
        await tester.pumpWidget(
          AuthScope(
            session: session,
            child: MaterialApp(home: entry.value),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        session.api.dio.close(force: true);
        session.dispose();
      });
    }
  }
  testWidgets('protected home renders sign-in for a guest', (tester) async {
    final session = AuthSession(api: AuthApi(), store: MemoryRefreshStore());
    await tester.pumpWidget(
      AuthScope(
        session: session,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.api.dio.close(force: true);
    session.dispose();
  });
  testWidgets('invalid login does not navigate or send credentials', (
    tester,
  ) async {
    final session = AuthSession(api: AuthApi(), store: MemoryRefreshStore());
    await tester.pumpWidget(
      AuthScope(
        session: session,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.tap(find.text('Log in').last);
    await tester.pump();
    expect(session.authenticated, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.api.dio.close(force: true);
    session.dispose();
  });
}
