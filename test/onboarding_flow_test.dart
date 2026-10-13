import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/private_api_error.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';
import 'package:esocialmedia/features/onboarding/onboarding_api.dart';
import 'package:esocialmedia/features/onboarding/onboarding_controller.dart';
import 'package:esocialmedia/features/onboarding/onboarding_models.dart';
import 'onboarding_fixtures.dart' as f;

class PersistentTestStore extends MemoryRefreshStore {
  @override
  bool get persistent => true;
}

void main() {
  late f.ContractBroker b;
  late AuthSession auth;
  late OnboardingApi api;
  late OnboardingController c;
  setUp(() async {
    b = f.ContractBroker();
    auth = b.session();
    await b.login(auth);
    api = OnboardingApi(auth);
    c = OnboardingController(api);
    await c.load();
  });
  tearDown(() {
    c.dispose();
    auth.api.dio.close(force: true);
    auth.dispose();
  });
  Future<void> grant() async {
    c.acceptance(ConsentPurpose.astrology, true);
    c.attest(true);
    await c.decide(ConsentPurpose.astrology, 'GRANTED');
  }

  Future<void> saved() async {
    await grant();
    c.birthChanged(
      dateValue: '2000-01-01',
      knownValue: true,
      timeValue: '12:30',
    );
    await c.saveBirth();
    c.searchChanged(queryValue: 'Kolkata');
    await c.search();
    c.select(c.results!.items.first);
  }

  test('consent-first load requests no birth draft and begins unchecked', () {
    expect(c.granted, isFalse);
    expect(c.adult, isFalse);
    expect(c.termsAccepted, isFalse);
    expect(c.astrologyAccepted, isFalse);
    expect(
      b.requests.any((o) => o.path.endsWith('/astrology/onboarding')),
      isFalse,
    );
  });
  test(
    'grant requires unchecked explicit acceptance/adult and independent terms',
    () async {
      await c.decide(ConsentPurpose.astrology, 'GRANTED');
      expect(b.states, isEmpty);
      await grant();
      expect(c.granted, isTrue);
      expect(b.states.containsKey('GENERAL_TERMS'), isFalse);
      expect(c.adult, isFalse);
    },
  );
  test(
    'refusal requires no birth inputs and owner account rights remain accessible',
    () async {
      await c.decide(ConsentPurpose.astrology, 'REFUSED');
      expect(c.granted, isFalse);
      expect(c.draft, isNull);
      expect(auth.authenticated, isTrue);
      expect((await auth.profile()).id, b.userId);
    },
  );
  test(
    'unknown-time draft remains incomplete and explicit midnight is preserved',
    () async {
      await grant();
      c.birthChanged(dateValue: '2000-02-29', knownValue: false);
      await c.saveBirth();
      final request = b.requests.lastWhere((o) => o.method == 'PATCH');
      expect((request.data as Map).containsKey('birthTime'), isFalse);
      expect(c.draft!.birth!.time, isNull);
      expect(c.exactSaved, isFalse);
      c.birthChanged(knownValue: true, timeValue: '00:00');
      await c.saveBirth();
      expect(c.draft!.birth!.time, '00:00');
    },
  );
  test(
    'place search is bounded and never selects a duplicate name automatically',
    () async {
      await grant();
      c.searchChanged(
        queryValue: 'কলকাতা',
        countryValue: 'IN',
        languageValue: 'bn',
      );
      await c.search();
      expect(c.selected, isNull);
      expect(c.results!.items.length, 2);
      expect(b.requests.last.data, {
        'query': 'কলকাতা',
        'countryCode': 'IN',
        'language': 'bn',
        'limit': 10,
      });
      c.select(c.results!.items.last);
      expect(c.selected!.hierarchy, contains('different district'));
    },
  );
  test(
    'fold preserves returned revision and requires actual explicit offset',
    () async {
      await saved();
      b.resolutionStatus = 'FOLD';
      await c.resolve();
      expect(c.draft!.revision, 2);
      expect(c.offset, isNull);
      expect(c.canResolve, isFalse);
      c.selectOffset(1800);
      expect(c.canResolve, isFalse);
      c.selectOffset(-18000);
      await c.resolve();
      expect(c.draft!.revision, 3);
      final r =
          b.requests.lastWhere((o) => o.path.endsWith('/resolve')).data as Map;
      expect(r['expectedRevision'], 2);
      expect(r['offsetSeconds'], -18000);
    },
  );
  test(
    'gap rolls back resolution, displays code and does not invent evidence',
    () async {
      await saved();
      b.resolutionStatus = 'GAP';
      await c.resolve();
      expect(c.failure, 'GAP');
      expect(c.draft!.revision, 1);
      expect(c.draft!.evidence, isNull);
    },
  );
  test(
    'private review confirms benchmark only and derived eligibility never becomes READY',
    () async {
      await saved();
      await c.resolve();
      expect(c.canConfirm, isFalse);
      c.setReview(true);
      await c.confirm();
      expect(c.draft!.evidence!.confirmedAt, isNotNull);
      expect(c.eligibility!.state, 'REVIEW_REQUIRED');
      expect(c.eligibility!.satisfied, isFalse);
      expect(c.eligibility!.allowed, isTrue);
      expect(c.review, isFalse);
    },
  );
  test(
    'withdrawal invalidates retained review and re-consent does not revive it',
    () async {
      await saved();
      await c.resolve();
      c.setReview(true);
      await c.confirm();
      await c.withdraw(ConsentPurpose.astrology);
      expect(c.granted, isFalse);
      expect(c.draft, isNull);
      expect(c.date, '');
      expect(c.results, isNull);
      expect(auth.authenticated, isTrue);
      await grant();
      expect(c.draft!.evidence, isNull);
      expect(c.canConfirm, isFalse);
    },
  );
  test(
    '409 stale revisions refetch authoritative state without replay',
    () async {
      await saved();
      b.revision = 2;
      c.birthChanged(timeValue: '13:30');
      await c.saveBirth();
      expect(b.requests.where((o) => o.method == 'PATCH').length, 2);
      expect(c.draft!.revision, 2);
      expect(c.time, '12:30');
      expect(c.message, 'conflict');
    },
  );
  test(
    'uncertain save blocks further mutation until deliberate server readback',
    () async {
      await grant();
      c.birthChanged(dateValue: '2000-01-01', knownValue: false);
      b.respondOverride = (o) => o.method == 'PATCH'
          ? Future.error(
              DioException(
                requestOptions: o,
                type: DioExceptionType.receiveTimeout,
              ),
            )
          : null;
      await c.saveBirth();
      expect(c.reconcile, isTrue);
      await c.saveBirth();
      expect(b.requests.where((o) => o.method == 'PATCH').length, 1);
      b.respondOverride = null;
      await c.load();
      expect(c.reconcile, isFalse);
      expect(c.draft!.birth, isNull);
    },
  );
  test(
    'uncertain consent allows exact-key payload retry after readback, never automatic replay',
    () async {
      var attempts = 0;
      b.respondOverride = (o) {
        if (o.path == 'users/me/consent' && attempts++ == 0) {
          return Future.error(
            DioException(
              requestOptions: o,
              type: DioExceptionType.connectionError,
            ),
          );
        }
        return null;
      };
      await grant();
      final p = c.pending!;
      expect(c.reconcile, isTrue);
      await c.load();
      await c.retryConsent();
      final requests = b.requests
          .where((o) => o.path == 'users/me/consent')
          .toList();
      expect(requests.length, 2);
      expect(requests[0].data, requests[1].data);
      expect((requests.last.data as Map)['idempotencyKey'], p.key);
      expect(c.pending, isNull);
    },
  );
  test(
    'search withdrawal refetches consent and immediately clears private birth draft',
    () async {
      await saved();
      b.states['ASTROLOGY'] = f.receipt(
        'ASTROLOGY',
        action: 'WITHDRAWN',
        revision: 2,
      );
      b.respondOverride = (o) => o.path.endsWith('/places/search')
          ? Future.value(b.failure(403, 'ASTROLOGY_CONSENT_REQUIRED'))
          : null;
      c.searchChanged(queryValue: 'Kolkata');
      await c.search();
      expect(c.granted, isFalse);
      expect(c.draft, isNull);
      expect(c.query, '');
    },
  );
  test(
    'disabled API returns a typed private failure without expiring authentication',
    () async {
      b.enabled = false;
      await c.load();
      expect(c.disabled, isTrue);
      expect(c.notices, isEmpty);
      expect(auth.authenticated, isTrue);
      expect(c.failure, 'API_DISABLED');
    },
  );
  test(
    'logout clears private state and a late response cannot restore an old account',
    () async {
      await saved();
      final done = Completer<ResponseBody>();
      b.respondOverride = (o) => o.method == 'PATCH' ? done.future : null;
      c.birthChanged(timeValue: '13:30');
      final save = c.saveBirth();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await auth.logout();
      expect(c.draft, isNull);
      expect(c.date, '');
      expect(c.pending, isNull);
      done.complete(
        f.jsonResponse({
          'message': 'Synthetic saved',
          'inputRevision': 2,
          'complete': false,
        }),
      );
      await save;
      expect(c.draft, isNull);
      expect(c.notices, isEmpty);
    },
  );
  test(
    'account switch clears private state before new session is used',
    () async {
      await saved();
      b.userId = 'different-synthetic';
      await b.login(auth);
      expect(c.draft, isNull);
      expect(c.date, '');
      expect(c.query, '');
    },
  );
  test(
    'revoked mutation returns 401, clears credentials and is not refreshed or replayed',
    () async {
      await grant();
      c.birthChanged(dateValue: '2000-01-01', knownValue: false);
      b.respondOverride = (o) => o.method == 'PATCH'
          ? Future.value(b.failure(401, 'SESSION_UNAVAILABLE'))
          : null;
      await c.saveBirth();
      expect(auth.authenticated, isFalse);
      expect(c.draft, isNull);
      expect(b.refreshes, 0);
      expect(b.requests.where((o) => o.method == 'PATCH').length, 1);
    },
  );
  test(
    'parallel private reads coordinate the existing refresh flight',
    () async {
      var fresh = false, rotations = 0;
      b.respondOverride = (o) {
        if (o.path == 'users/me' && !fresh) {
          return Future.value(b.failure(401, 'SESSION_UNAVAILABLE'));
        }
        if (o.path == 'auth/refresh') {
          rotations++;
          return Future<ResponseBody>.delayed(
            const Duration(milliseconds: 20),
            () {
              fresh = true;
              return f.jsonResponse(f.ContractBroker.userPair);
            },
          );
        }
        return null;
      };
      await Future.wait([
        api.notice(ConsentPurpose.astrology),
        api.current(ConsentPurpose.astrology),
      ]);
      expect(rotations, 1);
      expect(auth.authenticated, isTrue);
    },
  );
  test(
    'native restoration uses existing store then fetches authoritative state without caching completion',
    () async {
      final store = PersistentTestStore();
      await store.write('a' * 128);
      final restored = b.session(store: store);
      await restored.restore();
      expect(restored.authenticated, isTrue);
      final screen = OnboardingController(OnboardingApi(restored));
      await screen.load();
      expect(screen.eligibility!.state, 'CONSENT_REQUIRED');
      screen.dispose();
      await restored.logout();
      expect(await store.read(), isNull);
      restored.dispose();
    },
  );
  test(
    'machine 429 and 503 error contracts retain codes without raw payload leakage',
    () async {
      for (final status in [429, 503]) {
        b.respondOverride = (o) => o.path.contains('/notices/')
            ? Future.value(
                b.failure(
                  status,
                  status == 429 ? 'RATE_LIMITED' : 'DEPENDENCY_UNAVAILABLE',
                ),
              )
            : null;
        try {
          await api.notice(ConsentPurpose.astrology);
          fail('Expected typed failure');
        } on PrivateApiFailure catch (e) {
          expect(e.status, status);
          expect(e.toString(), isNot(contains('Synthetic fixture')));
        }
      }
    },
  );
  test(
    'stale search replies are discarded after query replacement and teardown',
    () async {
      await grant();
      final done = Completer<ResponseBody>();
      b.respondOverride = (o) =>
          o.path.endsWith('/places/search') ? done.future : null;
      c.searchChanged(queryValue: 'Kolkata');
      final search = c.search();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      c.searchChanged(queryValue: 'x');
      expect(c.searchBusy, isFalse);
      done.complete(f.jsonResponse(f.places));
      await search;
      expect(c.results, isNull);
      expect(c.selected, isNull);
    },
  );
  test(
    'unsupported historical resolution stays incomplete without UTC or confirmation',
    () async {
      await saved();
      c.birthChanged(dateValue: '1900-01-01');
      await c.saveBirth();
      c.searchChanged(queryValue: 'Kolkata');
      await c.search();
      c.select(c.results!.items.first);
      b.respondOverride = (o) {
        if (!o.path.endsWith('/resolve')) return null;
        b.revision++;
        b.evidence = {
          'evidenceId': f.evidenceId,
          'inputRevision': b.revision,
          'canonicalPlaceId': 'geonames:1275004',
          'catalogueReleaseId': 'synthetic-test-release',
          'validationStatus': 'UNSUPPORTED',
          'reasonCode': 'UNSUPPORTED_DATE',
          'timezoneId': 'Asia/Kolkata',
          'offsetSeconds': null,
          'resolvedInstant': null,
          'confirmedAt': null,
          'benchmarkOnly': true,
        };
        return Future.value(
          f.jsonResponse({
            'status': 'UNSUPPORTED_DATE',
            'inputRevision': b.revision,
            'complete': false,
            'benchmarkOnly': true,
            'productionApproved': false,
            'evidenceId': f.evidenceId,
          }),
        );
      };
      await c.resolve();
      expect(c.resolution!.status, 'UNSUPPORTED_DATE');
      expect(c.draft!.evidence!.utc, isNull);
      c.setReview(true);
      expect(c.canConfirm, isFalse);
    },
  );
  test(
    'changed notice prevents an uncertain consent replay with obsolete notice intent',
    () async {
      b.respondOverride = (o) => o.path == 'users/me/consent'
          ? Future.error(
              DioException(
                requestOptions: o,
                type: DioExceptionType.connectionError,
              ),
            )
          : null;
      await grant();
      await c.load();
      final old = c.pending!;
      c.notices[ConsentPurpose.astrology] = ConsentNotice(
        ConsentPurpose.astrology,
        'development-astrology-v2',
        'b' * 64,
        'Original changed test notice',
      );
      expect(c.canRetryConsent, isFalse);
      await c.retryConsent();
      expect(c.pending, same(old));
      expect(b.requests.where((o) => o.path == 'users/me/consent').length, 1);
    },
  );
  test(
    'general terms grant and withdrawal use their own revision without adult attestation',
    () async {
      c.acceptance(ConsentPurpose.generalTerms, true);
      await c.decide(ConsentPurpose.generalTerms, 'GRANTED');
      final body =
          b.requests.lastWhere((o) => o.path == 'users/me/consent').data as Map;
      expect(body['purpose'], 'GENERAL_TERMS');
      expect(body.containsKey('adultConfirmed'), isFalse);
      expect(c.granted, isFalse);
      await grant();
      await c.withdraw(ConsentPurpose.generalTerms);
      expect(c.granted, isTrue);
      expect(
        c.consents[ConsentPurpose.generalTerms]!.receipt!.action,
        'WITHDRAWN',
      );
      expect(auth.authenticated, isTrue);
    },
  );
  test(
    'owned receipt inspection uses raw private contract and foreign resources remain unavailable',
    () async {
      await grant();
      final owned = await api.receipt(f.receiptId, ConsentPurpose.astrology);
      expect(owned.id, f.receiptId);
      await expectLater(
        api.receipt(
          '33333333-3333-4333-8333-333333333333',
          ConsentPurpose.astrology,
        ),
        throwsA(
          isA<PrivateApiFailure>().having((e) => e.status, 'status', 404),
        ),
      );
      expect(auth.authenticated, isTrue);
    },
  );
}
