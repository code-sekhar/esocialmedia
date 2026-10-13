// Explicit D1 invocation: real isolated HTTP, PostgreSQL/Redis + capture SMTP.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/core/auth/auth_api.dart';
import 'package:esocialmedia/core/auth/auth_models.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';
import 'package:esocialmedia/features/onboarding/onboarding_api.dart';
import 'package:esocialmedia/features/onboarding/onboarding_controller.dart';
import 'package:esocialmedia/features/onboarding/onboarding_models.dart';

void main() {
  const base = String.fromEnvironment('AUTH_TEST_API'),
      mail = String.fromEnvironment('AUTH_TEST_MAIL');
  if (!base.startsWith('http://127.0.0.1:') ||
      base.contains(':3000/') ||
      !mail.startsWith('http://127.0.0.1:'))
    throw StateError('Dedicated isolated loopback services required');
  Future<Object?> get(String url) async {
    final h = HttpClient();
    try {
      final req = await h.getUrl(Uri.parse(url)), res = await req.close();
      return jsonDecode(await utf8.decoder.bind(res).join());
    } finally {
      h.close(force: true);
    }
  }

  Future<String> code(String email) async {
    for (var i = 0; i < 200; i++) {
      final list = await get('$mail/api/v1/messages') as Map<String, dynamic>;
      for (final m in list['messages'] as List) {
        if (!(m['To'] as List).any((t) => t['Address'] == email)) continue;
        final detail =
            await get('$mail/api/v1/message/${m['ID']}')
                as Map<String, dynamic>;
        final match = RegExp(
          r'>([0-9]{6})</',
        ).firstMatch(detail['HTML'] as String);
        if (match != null) return match.group(1)!;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('Synthetic mail timeout');
  }

  Future<AuthSession> actor() async {
    final tag = DateTime.now().microsecondsSinceEpoch,
        email = 'd1_dart_$tag@example.invalid';
    final auth = AuthSession(
      api: AuthApi(baseUrl: base),
      store: MemoryRefreshStore(),
    );
    await auth.register(
      Registration(
        email: email,
        username: 'd1_dart_$tag',
        displayName: 'Synthetic Dart D1',
        password: 'synthetic secure passphrase',
      ),
    );
    await auth.verifyEmail(email, await code(email));
    await auth.login(email, 'synthetic secure passphrase');
    return auth;
  }

  Future<void> grant(OnboardingController c, ConsentPurpose p) async {
    c.acceptance(p, true);
    if (p == ConsentPurpose.astrology) c.attest(true);
    await c.decide(p, 'GRANTED');
    expect(c.failure, isNull, reason: 'Real consent contract must decode');
  }

  test(
    'real Flutter typed client lifecycle and exact persisted onboarding revisions',
    () async {
      final auth = await actor(),
          api = OnboardingApi(auth),
          c = OnboardingController(api);
      try {
        await c.load();
        expect(c.failure, isNull);
        expect(c.granted, isFalse);
        await c.decide(ConsentPurpose.astrology, 'REFUSED');
        expect(c.draft, isNull);
        expect(auth.authenticated, isTrue);
        await grant(c, ConsentPurpose.generalTerms);
        await grant(c, ConsentPurpose.astrology);
        c.birthChanged(
          dateValue: '2000-01-01',
          knownValue: true,
          timeValue: '00:00',
        );
        await c.saveBirth();
        expect(c.failure, isNull);
        expect(c.draft!.birth!.time, '00:00');
        c.searchChanged(
          queryValue: 'কলকাতা',
          languageValue: 'bn',
          countryValue: 'IN',
        );
        await c.search();
        expect(c.searchFailure, isNull);
        expect(c.selected, isNull);
        c.select(
          c.results!.items.firstWhere((p) => p.id == 'geonames:1275004'),
        );
        await c.resolve();
        expect(c.failure, isNull);
        expect(c.draft!.evidence!.offset, 19800);
        c.setReview(true);
        await c.confirm();
        expect(c.failure, isNull);
        expect(c.eligibility!.state, 'REVIEW_REQUIRED');
        expect(c.eligibility!.satisfied, isFalse);
        expect(c.eligibility!.allowed, isTrue);
        await auth.rotate();
        await c.load();
        expect(c.granted, isTrue);
        await c.withdraw(ConsentPurpose.astrology);
        expect(c.draft, isNull);
        expect(c.date, '');
        expect(c.eligibility!.state, 'CONSENT_WITHDRAWN');
        await grant(c, ConsentPurpose.astrology);
        expect(c.draft!.evidence, isNull);
        expect(c.canConfirm, isFalse);
        await auth.privacy('export', password: 'synthetic secure passphrase');
        await auth.privacy(
          'deletion-request',
          password: 'synthetic secure passphrase',
        );
        expect(auth.authenticated, isFalse);
        expect(c.draft, isNull);
      } finally {
        c.dispose();
        auth.api.dio.close(force: true);
        auth.dispose();
      }
    },
  );
  test(
    'real Flutter DST fold/gap, unsupported history and sequential stale recovery',
    () async {
      final auth = await actor(), c = OnboardingController(OnboardingApi(auth));
      try {
        await c.load();
        await grant(c, ConsentPurpose.astrology);
        c.birthChanged(
          dateValue: '2000-10-29',
          knownValue: true,
          timeValue: '01:30',
        );
        await c.saveBirth();
        c.searchChanged(queryValue: 'New York');
        await c.search();
        expect(c.searchFailure, isNull);
        c.select(
          c.results!.items.firstWhere((p) => p.id == 'geonames:5128581'),
        );
        await c.resolve();
        expect(c.failure, isNull);
        expect(c.resolution!.status, 'FOLD');
        expect(c.resolution!.offsets.toSet(), {-18000, -14400});
        expect(c.canResolve, isFalse);
        c.selectOffset(-18000);
        await c.resolve();
        expect(c.draft!.revision, 3);
        expect(c.draft!.evidence!.offset, -18000);
        c.birthChanged(dateValue: '2000-04-02', timeValue: '02:30');
        await c.saveBirth();
        c.searchChanged(queryValue: 'New York');
        await c.search();
        c.select(
          c.results!.items.firstWhere((p) => p.id == 'geonames:5128581'),
        );
        await c.resolve();
        expect(c.failure, 'GAP');
        expect(c.draft!.evidence, isNull);
        c.birthChanged(dateValue: '1900-01-01', timeValue: '12:30');
        await c.saveBirth();
        c.searchChanged(queryValue: 'Kolkata');
        await c.search();
        c.select(
          c.results!.items.firstWhere((p) => p.id == 'geonames:1275004'),
        );
        await c.resolve();
        expect(c.resolution!.status, 'UNSUPPORTED_DATE');
        expect(c.draft!.evidence!.utc, isNull);
        expect(c.canConfirm, isFalse);
        final d = c.draft!,
            receipt = c.consents[ConsentPurpose.astrology]!.receipt!;
        await c.api.save(
          BirthInput(d.revision, receipt.id, '2000-01-01', true, '12:30'),
        );
        c.birthChanged(timeValue: '13:30');
        await c.saveBirth();
        expect(c.message, 'conflict');
        expect(c.time, '12:30');
        await auth.logout();
        expect(c.draft, isNull);
        expect(c.notices, isEmpty);
      } finally {
        c.dispose();
        auth.api.dio.close(force: true);
        auth.dispose();
      }
    },
  );
}
