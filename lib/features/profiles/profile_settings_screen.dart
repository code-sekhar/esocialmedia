import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_scope.dart';
import '../../core/l10n/auth_copy.dart';
import '../onboarding/onboarding_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final bool astrology;
  const ProfileSettingsScreen({super.key, this.astrology = false});
  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettingsScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      bio = TextEditingController(),
      date = TextEditingController(),
      time = TextEditingController(),
      place = TextEditingController(),
      zone = TextEditingController();
  bool initialized = false,
      busy = false,
      known = false,
      consent = false,
      adult = false;
  String visibility = 'PRIVATE', message = '';
  int revision = 0;
  Uint8List? image;
  @override
  void dispose() {
    for (final c in [name, bio, date, time, place, zone]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized && AuthScope.of(context).authenticated) {
      initialized = true;
      load();
    }
  }

  Future<void> load() async {
    if (busy) return;
    setState(() => busy = true);
    final session = AuthScope.of(context);
    try {
      final user = await session.profile();
      if (!mounted) return;
      name.text = user.displayName ?? user.username;
      bio.text = user.bio ?? '';
      visibility = user.visibility;
      final a = user.astrology;
      date.text = a?.birthDate.substring(0, 10) ?? '';
      place.text = a?.place ?? '';
      zone.text = a?.timezone ?? '';
      known = a?.known ?? false;
      time.text = a?.minutes == null
          ? ''
          : '${(a!.minutes! ~/ 60).toString().padLeft(2, '0')}:${(a.minutes! % 60).toString().padLeft(2, '0')}';
      revision = widget.astrology ? a?.revision ?? 0 : user.revision;
      consent = false;
      adult = false;
      if (!widget.astrology) {
        image = await session.avatar();
      }
    } catch (e) {
      message = AuthCopy.error(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    if (widget.astrology && (!consent || !adult)) {
      setState(
        () => message = 'Explicit consent and adult confirmation are required.',
      );
      return;
    }
    final session = AuthScope.of(context);
    final payload = widget.astrology
        ? AstrologyPatch(
            date: date.text,
            known: known,
            minutes: known
                ? int.parse(time.text.substring(0, 2)) * 60 +
                      int.parse(time.text.substring(3))
                : null,
            place: place.text,
            timezone: zone.text,
            consent: consent,
            adult: adult,
            revision: revision,
          ).toJson()
        : ProfilePatch(
            name.text.trim(),
            bio.text,
            visibility,
            revision,
          ).toJson();
    setState(() => busy = true);
    try {
      await session.change(
        'users/me/${widget.astrology ? 'astrology' : 'profile'}',
        payload,
      );
      revision = widget.astrology
          ? session.account!.astrology!.revision
          : session.account!.revision;
      message = 'Saved.';
      consent = false;
      adult = false;
    } catch (e) {
      message = AuthCopy.error(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> withdraw() async {
    if (busy) return;
    final session = AuthScope.of(context);
    setState(() => busy = true);
    try {
      await session.change('users/me/astrology/withdraw', {
        'expectedRevision': revision,
      }, method: 'POST');
      revision = session.account?.astrology?.revision ?? 0;
      consent = false;
      message =
          'Consent withdrawn. Retained birth inputs remain private and inactive.';
    } catch (e) {
      message = AuthCopy.error(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> upload() async {
    if (busy) return;
    final session = AuthScope.of(context);
    setState(() => busy = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      if (await file.length() > 5 * 1024 * 1024) {
        throw const AuthFailure(AuthProblem.validation);
      }
      final extension = file.name.split('.').last.toLowerCase();
      final subtype = extension == 'jpg' ? 'jpeg' : extension;
      if (!['png', 'jpeg', 'webp'].contains(subtype)) {
        throw const AuthFailure(AuthProblem.validation);
      }
      await session.change(
        'users/me/avatar',
        FormData.fromMap({
          'avatar': MultipartFile.fromBytes(
            await file.readAsBytes(),
            filename: 'avatar.$extension',
            contentType: DioMediaType('image', subtype),
          ),
        }),
        method: 'POST',
      );
      image = await session.avatar();
      revision = session.account!.revision;
      message = 'Avatar uploaded.';
    } catch (e) {
      message = AuthCopy.error(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove() async {
    if (busy) return;
    final session = AuthScope.of(context);
    setState(() => busy = true);
    try {
      await session.change('users/me/avatar', {}, method: 'DELETE');
      image = null;
      revision = session.account!.revision;
      message = 'Avatar removed.';
    } catch (e) {
      message = AuthCopy.error(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(
    String label,
    TextEditingController controller, {
    int max = 120,
    int lines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: TextFormField(
      controller: controller,
      maxLength: max,
      maxLines: lines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
        ),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context);
    return ProtectedSession(
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0328),
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: 'Astrology onboarding',
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AstrologyOnboardingScreen(),
                ),
              ),
            ),
          ],
          title: Text(
            widget.astrology
                ? AuthCopy.text('astrologyTitle')
                : AuthCopy.text('profileTitle'),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '@${session.account?.username ?? ''} · username is read-only',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (busy) const LinearProgressIndicator(),
                Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!widget.astrology) ...[
                        Text(
                          'Completeness: ${session.account?.completed ?? 0}/3. Birth data never affects this score.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (image != null)
                          Center(
                            child: ClipOval(
                              child: Image.memory(
                                image!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        TextButton(
                          onPressed: busy ? null : upload,
                          child: const Text(
                            'Upload avatar · JPG/PNG/WebP, up to 5 MiB',
                          ),
                        ),
                        TextButton(
                          onPressed: busy ? null : remove,
                          child: const Text('Remove avatar'),
                        ),
                        field(
                          'Display name',
                          name,
                          max: 100,
                          validator: (v) => (v?.trim().length ?? 0) < 2
                              ? 'Use 2–100 characters'
                              : null,
                        ),
                        field('Bio', bio, max: 500, lines: 3),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: visibility,
                          dropdownColor: const Color(0xFF30104B),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Profile visibility',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'PRIVATE',
                              child: Text('Private — only you'),
                            ),
                            DropdownMenuItem(
                              value: 'PUBLIC',
                              child: Text('Public to signed-in members'),
                            ),
                          ],
                          onChanged: busy
                              ? null
                              : (v) =>
                                    setState(() => visibility = v ?? 'PRIVATE'),
                        ),
                        const Text(
                          'Only username, display name, bio and avatar may be public. Email and birth inputs remain private.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ] else ...[
                        const Text(
                          'Optional, adult-only pending child-privacy review. Birth data stays private, is not used for advertising, and no KP calculations are performed. Unknown birth time remains unknown.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Consent: ${session.account?.astrology?.consentAt == null ? 'Not active' : 'Active'} · Private',
                          style: const TextStyle(color: Colors.white),
                        ),
                        field(
                          'Birth date (YYYY-MM-DD)',
                          date,
                          max: 10,
                          validator: (v) =>
                              RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v ?? '')
                              ? null
                              : 'Enter a date as YYYY-MM-DD',
                        ),
                        CheckboxListTile(
                          value: known,
                          onChanged: busy
                              ? null
                              : (v) => setState(() => known = v ?? false),
                          title: const Text(
                            'I know my exact birth time',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        if (known)
                          field(
                            'Local birth time (HH:MM, 24-hour)',
                            time,
                            max: 5,
                            validator: (v) =>
                                RegExp(
                                  r'^([01]\d|2[0-3]):[0-5]\d$',
                                ).hasMatch(v ?? '')
                                ? null
                                : 'Use HH:MM',
                          ),
                        field('Birthplace (optional)', place),
                        field('IANA timezone (optional)', zone, max: 80),
                        CheckboxListTile(
                          value: adult,
                          onChanged: busy
                              ? null
                              : (v) => setState(() => adult = v ?? false),
                          title: const Text(
                            'I am at least 18 (not verified age assurance)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        CheckboxListTile(
                          value: consent,
                          onChanged: busy
                              ? null
                              : (v) => setState(() => consent = v ?? false),
                          title: const Text(
                            'I consent to private astrology input storage under notice astrology-input-v1. I may withdraw; retained inputs remain private and inactive. No advertising use.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      ElevatedButton(
                        onPressed: busy ? null : save,
                        child: Text(
                          busy
                              ? AuthCopy.text('busy')
                              : AuthCopy.text('saveProfile'),
                        ),
                      ),
                      TextButton(
                        onPressed: busy ? null : load,
                        child: const Text('Reload'),
                      ),
                      if (widget.astrology)
                        TextButton(
                          onPressed: busy ? null : withdraw,
                          child: Text(AuthCopy.text('withdrawAstrology')),
                        ),
                    ],
                  ),
                ),
                if (message.isNotEmpty)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
