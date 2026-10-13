import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/features/onboarding/onboarding_models.dart';
import 'package:esocialmedia/core/auth/private_api_error.dart';
import 'onboarding_fixtures.dart' as f;

void main() {
  final protocol = throwsA(
    isA<PrivateApiFailure>().having((e) => e.code, 'code', 'PROTOCOL'),
  );
  test(
    'immutable notice contracts preserve server text and reject legal approval substitution',
    () {
      final n = ConsentNotice.fromJson(
        f.notice('ASTROLOGY'),
        ConsentPurpose.astrology,
      );
      expect(n.text, contains('<b>'));
      expect(
        () => ConsentNotice.fromJson({
          ...f.notice('ASTROLOGY'),
          'approval': 'APPROVED',
        }, ConsentPurpose.astrology),
        protocol,
      );
      expect(
        () => ConsentNotice.fromJson(
          f.notice('GENERAL_TERMS'),
          ConsentPurpose.astrology,
        ),
        protocol,
      );
    },
  );
  test(
    'consent decoder rejects mismatched purpose/revision and missing adult attestation',
    () {
      expect(
        () => ConsentReceipt.fromJson({
          ...f.receipt('ASTROLOGY'),
          'adultAttestation': null,
        }, ConsentPurpose.astrology),
        protocol,
      );
      expect(
        () => ConsentState.fromJson({
          ...f.current('ASTROLOGY', f.receipt('ASTROLOGY')),
          'consentRevision': 2,
        }, ConsentPurpose.astrology),
        protocol,
      );
      expect(
        () => ConsentState.fromJson({
          'purpose': 'ASTROLOGY',
          'consentRevision': 0,
        }, ConsentPurpose.astrology),
        protocol,
      );
    },
  );
  test(
    'strict Gregorian dates, explicit midnight, unknown and provisional adult validation',
    () {
      expect(dateLiteral('2000-02-29'), isTrue);
      expect(dateLiteral('1900-02-29'), isFalse);
      expect(dateLiteral('2000-04-31'), isFalse);
      expect(validBirth('2000-01-01', true, '00:00'), isTrue);
      expect(validBirth('2000-01-01', null, ''), isFalse);
      expect(validBirth('2000-01-01', true, ''), isFalse);
      expect(validBirth('2000-01-01', false, ''), isTrue);
      expect(validBirth('2099-01-01', true, '12:30'), isFalse);
    },
  );
  test(
    'birth input only serializes literal writable fields and omits unknown time',
    () {
      expect(
        const BirthInput(1, f.receiptId, '2000-01-01', false, null).toJson(),
        {
          'expectedRevision': 1,
          'consentReceiptId': f.receiptId,
          'birthDate': '2000-01-01',
          'birthTimeKnown': false,
        },
      );
      expect(
        const BirthInput(
          1,
          f.receiptId,
          '2000-01-01',
          true,
          '00:00',
        ).toJson()['birthTime'],
        '00:00',
      );
    },
  );
  test(
    'legacy known time null stays an incomplete draft; unknown is never midnight',
    () {
      final b = {
        'birthDate': '2000-01-01',
        'birthTimeKnown': true,
        'birthTime': null,
        'birthPlace': null,
        'birthCountry': null,
        'birthState': null,
      };
      expect(BirthDraft.fromJson(b).time, isNull);
      expect(
        () => BirthDraft.fromJson({
          ...b,
          'birthTimeKnown': false,
          'birthTime': '00:00',
        }),
        protocol,
      );
    },
  );
  test(
    'place decoder preserves duplicate names with distinct canonical selection and immutable lists',
    () {
      final p = PlaceSearchResult.fromJson(f.places);
      expect(p.items.map((p) => p.name), ['Kolkata', 'Kolkata']);
      expect(p.items[0].id, isNot(p.items[1].id));
      expect(() => p.items.clear(), throwsUnsupportedError);
      expect(
        () => PlaceSearchResult.fromJson({
          ...f.places,
          'items': [
            f.candidate('geonames:1', 'A', 'A'),
            f.candidate('geonames:1', 'B', 'B'),
          ],
        }),
        protocol,
      );
      expect(
        () => PlaceSearchResult.fromJson({
          ...f.places,
          'items': List.generate(
            21,
            (i) => f.candidate('geonames:${i + 1}', 'A', 'A'),
          ),
        }),
        protocol,
      );
    },
  );
  test('invalid coordinates and missing hierarchy fields fail closed', () {
    final p = f.candidate('geonames:1', 'A', 'A');
    expect(
      () => PlaceCandidate.fromJson({
        ...p,
        'coordinates': {
          'latitude': 91,
          'longitude': 0,
          'precision': 'LOCALITY_REPRESENTATIVE',
        },
      }),
      protocol,
    );
    expect(
      () => PlaceCandidate.fromJson({
        ...p,
        'hierarchy': {'country': 'India'},
      }),
      protocol,
    );
  });
  test(
    'fold requires distinct actual second-precision offsets and evidence',
    () {
      final base = {
        'status': 'FOLD',
        'inputRevision': 2,
        'complete': false,
        'benchmarkOnly': true,
        'productionApproved': false,
        'evidenceId': f.evidenceId,
        'offsetChoices': [-2670, 1800],
      };
      expect(PlaceResolution.fromJson(base).offsets, [-2670, 1800]);
      expect(formatOffset(-2670), 'UTC−00:44:30');
      expect(
        () => PlaceResolution.fromJson({
          ...base,
          'offsetChoices': [1800, 1800],
        }),
        protocol,
      );
      expect(
        () => PlaceResolution.fromJson({...base, 'productionApproved': true}),
        protocol,
      );
    },
  );
  test(
    'all incomplete resolution states decode without fabricated instant',
    () {
      for (final s in [
        'LOCALITY_REQUIRED',
        'LOCATION_UNRESOLVED',
        'REVIEW_REQUIRED',
        'UNSUPPORTED_DATE',
        'UNSUPPORTED_ZONE',
      ]) {
        expect(
          PlaceResolution.fromJson({
            'status': s,
            'inputRevision': 2,
            'complete': false,
            'benchmarkOnly': true,
            'productionApproved': false,
          }).status,
          s,
        );
      }
    },
  );
  test(
    'OFF effective access is not READY; inconsistent completion and action are rejected',
    () {
      final e = SocialEligibility.fromJson(f.eligibility('REVIEW_REQUIRED', 2));
      expect(e.allowed, isTrue);
      expect(e.satisfied, isFalse);
      expect(
        () => SocialEligibility.fromJson({
          ...f.eligibility('REVIEW_REQUIRED', 2),
          'requirementsSatisfied': true,
        }),
        protocol,
      );
      expect(
        () => SocialEligibility.fromJson({
          ...f.eligibility('CONSENT_REQUIRED', 0),
          'nextAction': 'SOCIAL_ACCESS',
        }),
        protocol,
      );
    },
  );
  test(
    'confirmation rejects promoted benchmark evidence and invalid ISO dates',
    () {
      final c = {
        'evidenceId': f.evidenceId,
        'inputRevision': 2,
        'confirmedAt': '2026-10-14T00:00:00.000Z',
        'benchmarkOnly': true,
        'productionApproved': false,
        'requirementsSatisfied': false,
      };
      expect(OnboardingConfirmation.fromJson(c).revision, 2);
      expect(
        () => OnboardingConfirmation.fromJson({
          ...c,
          'requirementsSatisfied': true,
        }),
        protocol,
      );
      expect(
        () => OnboardingConfirmation.fromJson({
          ...c,
          'confirmedAt': '2026-02-30T00:00:00.000Z',
        }),
        protocol,
      );
    },
  );
  test(
    'unknown wire secret fields are not retained; private failures are redacted',
    () {
      final n = ConsentNotice.fromJson({
        ...f.notice('ASTROLOGY'),
        'secret': 'never-retain',
      }, ConsentPurpose.astrology);
      expect(n.toString(), isNot(contains('never-retain')));
      expect(
        const PrivateApiFailure(403, 'ASTROLOGY_CONSENT_REQUIRED').toString(),
        isNot(contains('ASTROLOGY')),
      );
    },
  );
}
