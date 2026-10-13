import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/l10n/auth_copy.dart';
import 'core/auth/auth_scope.dart';
import 'core/auth/auth_session.dart';
import 'core/auth/auth_api.dart';
import 'core/auth/refresh_store.dart';
import 'package:esocialmedia/screen/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.authSession});
  final AuthSession? authSession;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthSession session =
      widget.authSession ??
      AuthSession(api: AuthApi(), store: createRefreshStore());
  @override
  void initState() {
    super.initState();
    session.restore();
  }

  @override
  void dispose() {
    session.api.dio.close(force: true);
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      session: session,
      child: ValueListenableBuilder<String>(
        valueListenable: AuthCopy.language,
        builder: (context, language, _) => MaterialApp(
          locale: Locale(language),
          supportedLocales: const [Locale('en'), Locale('bn'), Locale('hi')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          title: 'Clean Flutter App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
