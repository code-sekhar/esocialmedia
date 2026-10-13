import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/core/auth/auth_scope.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/l10n/auth_copy.dart';
import 'package:esocialmedia/features/onboarding/onboarding_screen.dart';
import 'package:esocialmedia/screen/account_screen.dart';
import 'package:esocialmedia/features/privacy/privacy_screen.dart';
import 'onboarding_fixtures.dart' as f;

void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester,
    f.ContractBroker b,
    AuthSession auth, {
    Widget? screen,
  }) async {
    await tester.pumpWidget(
      AuthScope(
        session: auth,
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: screen ?? const AstrologyOnboardingScreen(),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> tap(WidgetTester t, String key) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    final target = find.byKey(ValueKey(key));
    await t.ensureVisible(target);
    await t.pumpAndSettle();
    await t.tap(target);
    await settle(t);
  }

  Future<void> grant(WidgetTester t) async {
    await tap(t, 'accept-ASTROLOGY');
    await tap(t, 'adult');
    await tap(t, 'grant-ASTROLOGY');
  }

  Future<void> close(WidgetTester t, AuthSession auth) async {
    await t.pumpWidget(const SizedBox());
    auth.api.dio.close(force: true);
    auth.dispose();
    AuthCopy.language.value = 'en';
  }

  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets(
      'consent screen is responsive at $width, unchecked, labelled and pending approval',
      (t) async {
        t.view.physicalSize = Size(width, 1000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final b = f.ContractBroker(), auth = b.session();
        await t.runAsync(() => b.login(auth));
        await open(t, b, auth);
        expect(
          t
              .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
              .every((x) => x.value == false),
          isTrue,
        );
        expect(find.byKey(const ValueKey('birth-date')), findsNothing);
        expect(find.textContaining('not legally approved'), findsOneWidget);
        final semantics = t.ensureSemantics();
        await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
        expect(t.takeException(), isNull);
        await close(t, auth);
      },
    );
  }
  testWidgets(
    'full widget journey saves literal birth inputs, explicitly selects place, confirms benchmark and withdraws',
    (t) async {
      final b = f.ContractBroker(), auth = b.session();
      await t.runAsync(() => b.login(auth));
      await open(t, b, auth);
      await grant(t);
      await t.enterText(find.byKey(const ValueKey('birth-date')), '2000-01-01');
      await tap(t, 'time-known');
      await t.enterText(find.byKey(const ValueKey('birth-time')), '00:00');
      await tap(t, 'save-birth');
      expect(b.birth!['birthTime'], '00:00');
      await t.enterText(find.byKey(const ValueKey('place-query')), 'Kolkata');
      await t.pump(const Duration(milliseconds: 550));
      await settle(t);
      expect(
        b.requests.where((o) => o.path.endsWith('/places/search')).length,
        1,
      );
      expect(
        t.widget<FilledButton>(find.byKey(const ValueKey('resolve'))).onPressed,
        isNull,
      );
      await tap(t, 'place-geonames:1275005');
      await tap(t, 'resolve');
      expect(b.evidence!['canonicalPlaceId'], 'geonames:1275005');
      expect(
        t.widget<FilledButton>(find.byKey(const ValueKey('confirm'))).onPressed,
        isNull,
      );
      await tap(t, 'review');
      await tap(t, 'confirm');
      expect(
        find.textContaining('Requirements are not yet satisfied.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Confirmed benchmark evidence'),
        findsOneWidget,
      );
      await tap(t, 'withdraw-ASTROLOGY');
      expect(find.byKey(const ValueKey('birth-date')), findsNothing);
      expect(find.byKey(const ValueKey('rights')), findsOneWidget);
      expect(auth.authenticated, isTrue);
      expect(t.takeException(), isNull);
      await close(t, auth);
    },
  );
  testWidgets(
    'unknown-time draft omits time and invalid date/time displays validation',
    (t) async {
      final b = f.ContractBroker(), auth = b.session();
      await t.runAsync(() => b.login(auth));
      await open(t, b, auth);
      await grant(t);
      await t.enterText(find.byKey(const ValueKey('birth-date')), '2000-02-30');
      await tap(t, 'time-unknown');
      await tap(t, 'save-birth');
      expect(b.birth, isNull);
      await t.enterText(find.byKey(const ValueKey('birth-date')), '2000-02-29');
      await tap(t, 'save-birth');
      expect(b.birth!['birthTime'], isNull);
      expect(find.textContaining('Unknown stays unknown'), findsOneWidget);
      expect(
        t.widget<FilledButton>(find.byKey(const ValueKey('resolve'))).onPressed,
        isNull,
      );
      await close(t, auth);
    },
  );
  testWidgets(
    'disabled API has retry and account rights without consent or login loss',
    (t) async {
      final b = f.ContractBroker()..enabled = false, auth = b.session();
      await t.runAsync(() => b.login(auth));
      await open(t, b, auth);
      expect(find.byKey(const ValueKey('api-disabled')), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byKey(const ValueKey('rights')), findsOneWidget);
      b.enabled = true;
      await tap(t, 'reload-disabled');
      expect(find.byKey(const ValueKey('accept-ASTROLOGY')), findsOneWidget);
      expect(auth.authenticated, isTrue);
      await close(t, auth);
    },
  );
  testWidgets(
    'account route opens onboarding while existing profile/privacy/sign-out controls survive',
    (t) async {
      final b = f.ContractBroker(), auth = b.session();
      await t.runAsync(() => b.login(auth));
      await open(t, b, auth, screen: const AccountScreen());
      expect(find.text('Edit profile & privacy'), findsOneWidget);
      expect(find.text('Sign out from all devices'), findsOneWidget);
      await t.tap(find.text('Astrology onboarding'));
      await settle(t);
      expect(find.byType(AstrologyOnboardingScreen), findsOneWidget);
      await close(t, auth);
    },
  );
  testWidgets(
    'English Bengali Hindi UI follows existing language notifier, server notice remains original',
    (t) async {
      final b = f.ContractBroker(), auth = b.session();
      await t.runAsync(() => b.login(auth));
      await open(t, b, auth);
      for (final language in ['bn', 'hi', 'en']) {
        AuthCopy.language.value = language;
        await t.pumpAndSettle();
        expect(
          find.text('DEVELOPMENT TEST ONLY. <b>Original server notice</b>'),
          findsNWidgets(2),
        );
        expect(t.takeException(), isNull);
      }
      await close(t, auth);
    },
  );
  testWidgets(
    'logout clears birth inputs and protected screen returns existing login',
    (t) async {
      final b = f.ContractBroker(), auth = b.session();
      await t.runAsync(() => b.login(auth));
      await open(t, b, auth);
      await grant(t);
      await t.enterText(find.byKey(const ValueKey('birth-date')), '2000-01-01');
      await t.runAsync(() => auth.clear());
      await settle(t);
      expect(find.byKey(const ValueKey('birth-date')), findsNothing);
      expect(find.text('Log in'), findsOneWidget);
      await close(t, auth);
    },
  );
  testWidgets(
    'account rights navigation clears covered private form and refetches on return',
    (t) async {
      final b = f.ContractBroker(), auth = b.session();
      await t.runAsync(() => b.login(auth));
      await open(t, b, auth);
      await grant(t);
      await t.enterText(find.byKey(const ValueKey('birth-date')), '2000-01-01');
      await tap(t, 'rights');
      expect(find.byType(PrivacyScreen), findsOneWidget);
      final hidden = find.byKey(
        const ValueKey('birth-date'),
        skipOffstage: false,
      );
      if (hidden.evaluate().isNotEmpty) {
        expect(t.widget<TextFormField>(hidden).controller!.text, '');
      }
      Navigator.of(t.element(find.byType(PrivacyScreen))).pop();
      await settle(t);
      expect(find.byType(AstrologyOnboardingScreen), findsOneWidget);
      expect(
        t
            .widget<TextFormField>(find.byKey(const ValueKey('birth-date')))
            .controller!
            .text,
        '',
      );
      expect(t.takeException(), isNull);
      await close(t, auth);
    },
  );
}
