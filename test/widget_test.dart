import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/auth_api.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';
import 'package:esocialmedia/main.dart';
import 'package:esocialmedia/screen/onboarding_screen.dart';
import 'package:esocialmedia/screen/splash_screen.dart';

void main() {
  testWidgets('Splash navigates to existing onboarding after three seconds', (
    tester,
  ) async {
    final session = AuthSession(api: AuthApi(), store: MemoryRefreshStore());
    await session.restore();
    await tester.pumpWidget(MyApp(authSession: session));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Eastalya'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
