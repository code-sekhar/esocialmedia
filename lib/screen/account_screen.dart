import '../features/privacy/privacy_screen.dart';
import 'package:flutter/material.dart';
import '../core/auth/auth_scope.dart';
import '../core/l10n/auth_copy.dart';
import 'login_screen.dart';
import '../features/profiles/profile_settings_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool initialized = false;
  bool busy = false;
  String? error;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized && AuthScope.of(context).authenticated) {
      initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    final session = AuthScope.of(context);
    busy = true;
    try {
      await session.profile();
    } catch (e) {
      error = AuthCopy.error(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _logout(bool all) async {
    if (busy) return;
    final session = AuthScope.of(context);
    setState(() => busy = true);
    try {
      await session.logout(all: all);
    } catch (e) {
      error = AuthCopy.error(e);
    } finally {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context);
    final user = session.account;
    return ProtectedSession(
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0328),
        appBar: AppBar(title: const Text('Your Eastalya account')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButton<String>(
              value: AuthCopy.language.value,
              dropdownColor: const Color(0xFF30104B),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
                DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
              ],
              onChanged: (value) {
                if (value != null) AuthCopy.language.value = value;
              },
            ),
            Text(
              user?.displayName ?? user?.username ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 26),
            ),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              '@${user?.username ?? ''}',
              style: const TextStyle(color: Colors.white70),
            ),
            const Text(
              'Birth information is optional and private.',
              style: TextStyle(color: Colors.white70),
            ),
            if (error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            if (busy) const LinearProgressIndicator(),
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                    ),
              child: const Text('Privacy lifecycle'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileSettingsScreen(),
                      ),
                    ),
              child: const Text('Edit profile & privacy'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ProfileSettingsScreen(astrology: true),
                      ),
                    ),
              child: const Text('Optional astrology & consent'),
            ),
            TextButton(
              onPressed: busy ? null : _load,
              child: const Text('Reload profile'),
            ),
            TextButton(
              onPressed: busy ? null : () => _logout(false),
              child: const Text('Sign out'),
            ),
            TextButton(
              onPressed: busy ? null : () => _logout(true),
              child: const Text('Sign out from all devices'),
            ),
          ],
        ),
      ),
    );
  }
}
