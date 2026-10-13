// Separate test entrypoint only. Never ship build/c2-contract-browser.
// No environment flag, application route or backend API activates this broker.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:esocialmedia/core/auth/auth_scope.dart';
import 'package:esocialmedia/core/l10n/auth_copy.dart';
import 'package:esocialmedia/features/onboarding/onboarding_screen.dart';
import 'onboarding_fixtures.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final broker = ContractBroker(), session = broker.session();
  await broker.login(session);
  runApp(
    AuthScope(
      session: session,
      child: ValueListenableBuilder<String>(
        valueListenable: AuthCopy.language,
        builder: (context, language, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: Locale(language),
          supportedLocales: const [Locale('en'), Locale('bn'), Locale('hi')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const AstrologyOnboardingScreen(),
        ),
      ),
    ),
  );
}
