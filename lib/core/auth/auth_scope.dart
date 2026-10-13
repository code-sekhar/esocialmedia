import 'package:flutter/material.dart';
import '../../screen/login_screen.dart';
import 'auth_session.dart';

class AuthScope extends InheritedNotifier<AuthSession> {
  const AuthScope({
    super.key,
    required AuthSession session,
    required super.child,
  }) : super(notifier: session);
  static AuthSession of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
  static AuthSession? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
}

class ProtectedSession extends StatelessWidget {
  final Widget child;
  const ProtectedSession({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final session = AuthScope.maybeOf(context);
    if (session == null || !session.authenticated) return const LoginScreen();
    return child;
  }
}
