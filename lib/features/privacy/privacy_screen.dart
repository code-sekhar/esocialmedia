import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/auth/auth_scope.dart';
import '../../core/l10n/auth_copy.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyState();
}

class _PrivacyState extends State<PrivacyScreen> {
  final password = TextEditingController();
  bool busy = false, confirmed = false, initialized = false;
  String message = '', status = '', export = '';
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      run('status');
    }
  }

  Future<void> run(String action) async {
    if (busy) return;
    if (action != 'status' && password.text.isEmpty) {
      setState(() => message = 'Confirm your current password.');
      return;
    }
    if (action == 'deletion-request' && !confirmed) return;
    final session = AuthScope.of(context);
    setState(() => busy = true);
    try {
      final result = await session.privacy(action, password: password.text);
      if (action == 'export') {
        export = const JsonEncoder.withIndent('  ').convert(result);
        message =
            'Your personal data is shown below in memory. Native file export is not enabled. Keep this information private.';
      } else {
        status = jsonEncode(result);
        message = action == 'status' ? '' : 'Request updated. No data erased.';
        export = '';
      }
    } catch (e) {
      message = AuthCopy.error(e);
    } finally {
      if (mounted) {
        password.clear();
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0328),
    appBar: AppBar(title: Text(AuthCopy.text('privacyTitle'))),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Export contains private personal data. Deletion is on hold pending approved policy: a request revokes current sessions but does not erase or close your account. Sign in again to inspect or cancel. Consent withdrawal retains private, inactive birth inputs.',
          style: TextStyle(color: Colors.white70),
        ),
        if (AuthScope.of(context).authenticated) ...[
          TextField(
            controller: password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: AuthCopy.text('currentPassword'),
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: busy ? null : () => run('export'),
            child: Text(AuthCopy.text('exportData')),
          ),
          CheckboxListTile(
            value: confirmed,
            onChanged: busy
                ? null
                : (value) => setState(() => confirmed = value ?? false),
            title: const Text(
              'I understand this requests review, not erasure.',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: busy || !confirmed
                ? null
                : () => run('deletion-request'),
            child: Text(AuthCopy.text('requestDeletion')),
          ),
          TextButton(
            onPressed: busy ? null : () => run('deletion-request/cancel'),
            child: Text(AuthCopy.text('cancelDeletion')),
          ),
          TextButton(
            onPressed: busy ? null : () => run('status'),
            child: Text(AuthCopy.text('refreshStatus')),
          ),
        ] else
          const Text(
            'Sign in from your account screen to inspect/cancel.',
            style: TextStyle(color: Colors.white),
          ),
        if (busy) const LinearProgressIndicator(),
        Semantics(
          liveRegion: true,
          child: Text(message, style: const TextStyle(color: Colors.white)),
        ),
        Text(status, style: const TextStyle(color: Colors.white70)),
        if (export.isNotEmpty && AuthScope.of(context).authenticated)
          SelectableText(export, style: const TextStyle(color: Colors.white70)),
      ],
    ),
  );
}
