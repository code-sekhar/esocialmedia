import '../../core/auth/private_api_error.dart';

Never invalidWire() => throw const PrivateApiFailure(0, 'PROTOCOL');
Map<String, dynamic> wire(Object? x, [List<String> required = const []]) {
  if (x is! Map<String, dynamic> || required.any((k) => !x.containsKey(k))) {
    invalidWire();
  }
  return x;
}

String wireText(Object? x, [int max = 400]) =>
    x is String && x.isNotEmpty && x.runes.length <= max ? x : invalidWire();
String? nullableText(Object? x, [int max = 400]) =>
    x == null ? null : wireText(x, max);
int integer(Object? x, [int min = 0, int max = 2147483647]) =>
    x is num && x.isFinite && x == x.truncate() && x >= min && x <= max
    ? x.toInt()
    : invalidWire();
bool boolean(Object? x) => x is bool ? x : invalidWire();
String choice(Object? x, Set<String> values) =>
    x is String && values.contains(x) ? x : invalidWire();
String uuid(Object? x) {
  final s = wireText(x, 36);
  return RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(s)
      ? s
      : invalidWire();
}

String wireDigest(Object? x) {
  final s = wireText(x, 64);
  return RegExp(r'^[a-f0-9]{64}$').hasMatch(s) ? s : invalidWire();
}

String wireVersion(Object? x) {
  final s = wireText(x, 80);
  return RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(s) ? s : invalidWire();
}

String canonical(Object? x) {
  final s = wireText(x, 40);
  return RegExp(r'^geonames:[1-9][0-9]{0,11}$').hasMatch(s) ? s : invalidWire();
}

String instant(Object? x) {
  final s = wireText(x, 40), d = DateTime.tryParse(s);
  return RegExp(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{3})?Z$').hasMatch(s) &&
          d != null &&
          d.toIso8601String() ==
              (s.contains('.') ? s : s.replaceFirst('Z', '.000Z'))
      ? s
      : invalidWire();
}

bool dateLiteral(String s) {
  if (!RegExp(r'^\d{4}-\d\d-\d\d$').hasMatch(s)) return false;
  final a = s.split('-').map(int.parse).toList();
  final y = a[0],
      m = a[1],
      d = a[2],
      leap = y % 4 == 0 && (y % 100 != 0 || y % 400 == 0);
  return y > 0 &&
      m >= 1 &&
      m <= 12 &&
      d >= 1 &&
      d <= [31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1];
}

bool timeLiteral(String s) => RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(s);
String adultCutoff([DateTime? now]) {
  final day = (now ?? DateTime.now()).toUtc();
  // Only the current policy cutoff uses a calendar DateTime; selected birth
  // literals are never converted to an instant or device timezone.
  final cutoff = DateTime.utc(day.year - 18, day.month, day.day);
  return '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
}

bool validBirth(String date, bool? known, String time) =>
    dateLiteral(date) &&
    date.compareTo(adultCutoff()) <= 0 &&
    known != null &&
    (!known || timeLiteral(time));
String formatOffset(int seconds) {
  final n = seconds.abs();
  return 'UTC${seconds < 0 ? '−' : '+'}${(n ~/ 3600).toString().padLeft(2, '0')}:${(n % 3600 ~/ 60).toString().padLeft(2, '0')}${n % 60 == 0 ? '' : ':${(n % 60).toString().padLeft(2, '0')}'}';
}

enum ConsentPurpose {
  generalTerms,
  astrology;

  String get wireName => this == generalTerms ? 'GENERAL_TERMS' : 'ASTROLOGY';
}

class ConsentNotice {
  final ConsentPurpose purpose;
  final String version, digest, text;
  const ConsentNotice(this.purpose, this.version, this.digest, this.text);
  factory ConsentNotice.fromJson(Object? value, ConsentPurpose purpose) {
    final x = wire(value);
    if (x['purpose'] != purpose.wireName ||
        x['language'] != 'en' ||
        x['approval'] != 'PENDING' ||
        x['developmentOnly'] != true) {
      invalidWire();
    }
    return ConsentNotice(
      purpose,
      wireVersion(x['version']),
      wireDigest(x['digest']),
      wireText(x['text'], 20000),
    );
  }
}

class ConsentReceipt {
  final ConsentPurpose purpose;
  final String id, action, noticeVersion, noticeDigest, createdAt;
  final int revision;
  final String? adultAttestation;
  const ConsentReceipt(
    this.purpose,
    this.id,
    this.action,
    this.noticeVersion,
    this.noticeDigest,
    this.revision,
    this.adultAttestation,
    this.createdAt,
  );
  factory ConsentReceipt.fromJson(Object? value, ConsentPurpose purpose) {
    final x = wire(value, ['adultAttestation']);
    if (x['purpose'] != purpose.wireName) invalidWire();
    final a = choice(x['action'], {'GRANTED', 'REFUSED', 'WITHDRAWN'}),
        adult = x['adultAttestation'] == null
            ? null
            : choice(x['adultAttestation'], {'SELF_DECLARED_ADULT'});
    if ((purpose == ConsentPurpose.astrology &&
            a == 'GRANTED' &&
            adult == null) ||
        (purpose == ConsentPurpose.generalTerms && adult != null)) {
      invalidWire();
    }
    return ConsentReceipt(
      purpose,
      uuid(x['receiptId']),
      a,
      wireVersion(x['noticeVersion']),
      wireDigest(x['noticeDigest']),
      integer(x['consentRevision'], 1),
      adult,
      instant(x['createdAt']),
    );
  }
}

class ConsentState {
  final ConsentPurpose purpose;
  final int revision;
  final ConsentReceipt? receipt;
  const ConsentState(this.purpose, this.revision, this.receipt);
  factory ConsentState.fromJson(Object? value, ConsentPurpose purpose) {
    final x = wire(value, ['receipt']);
    if (x['purpose'] != purpose.wireName) invalidWire();
    final rev = integer(x['consentRevision']),
        r = x['receipt'] == null
            ? null
            : ConsentReceipt.fromJson(x['receipt'], purpose);
    if (r == null ? rev != 0 : r.revision != rev) invalidWire();
    return ConsentState(purpose, rev, r);
  }
}

class ConsentRequest {
  final ConsentPurpose purpose;
  final int revision;
  final String key;
  final String? action, noticeVersion, noticeDigest;
  final bool adult;
  const ConsentRequest({
    required this.purpose,
    required this.revision,
    required this.key,
    this.action,
    this.noticeVersion,
    this.noticeDigest,
    this.adult = false,
  });
  bool get withdrawal => action == null;
  Map<String, Object> toJson() => {
    'purpose': purpose.wireName,
    'expectedConsentRevision': revision,
    'idempotencyKey': key,
    'action': ?action,
    'noticeVersion': ?noticeVersion,
    'noticeDigest': ?noticeDigest,
    if (adult) 'adultConfirmed': true,
  };
}

class BirthInput {
  final int revision;
  final String receiptId, date;
  final bool known;
  final String? time;
  const BirthInput(
    this.revision,
    this.receiptId,
    this.date,
    this.known,
    this.time,
  );
  Map<String, Object> toJson() => {
    'expectedRevision': revision,
    'consentReceiptId': receiptId,
    'birthDate': date,
    'birthTimeKnown': known,
    if (known && time != null) 'birthTime': time!,
  };
}

class BirthDraft {
  final String date;
  final bool known;
  final String? time, place, country, state;
  const BirthDraft(
    this.date,
    this.known,
    this.time,
    this.place,
    this.country,
    this.state,
  );
  factory BirthDraft.fromJson(Object? value) {
    final x = wire(value, [
          'birthTime',
          'birthPlace',
          'birthCountry',
          'birthState',
        ]),
        d = wireText(x['birthDate'], 10),
        k = boolean(x['birthTimeKnown']),
        t = nullableText(x['birthTime'], 5);
    if (!dateLiteral(d) ||
        (k && t != null && !timeLiteral(t)) ||
        (!k && t != null)) {
      invalidWire();
    }
    return BirthDraft(
      d,
      k,
      t,
      nullableText(x['birthPlace']),
      nullableText(x['birthCountry']),
      nullableText(x['birthState']),
    );
  }
}

class OnboardingEvidence {
  final String id, canonicalId, releaseId, status, timezone;
  final int revision;
  final String? reason, utc, confirmedAt;
  final int? offset;
  const OnboardingEvidence(
    this.id,
    this.revision,
    this.canonicalId,
    this.releaseId,
    this.status,
    this.reason,
    this.timezone,
    this.offset,
    this.utc,
    this.confirmedAt,
  );
  factory OnboardingEvidence.fromJson(Object? value) {
    final x = wire(value, [
      'reasonCode',
      'offsetSeconds',
      'resolvedInstant',
      'confirmedAt',
    ]);
    if (x['benchmarkOnly'] != true) invalidWire();
    final status = choice(x['validationStatus'], {
          'RESOLVED',
          'REVIEW_REQUIRED',
          'UNSUPPORTED',
        }),
        offset = x['offsetSeconds'] == null
            ? null
            : integer(x['offsetSeconds'], -93600, 93600),
        utc = x['resolvedInstant'] == null
            ? null
            : instant(x['resolvedInstant']);
    if (status == 'RESOLVED' && (offset == null || utc == null)) invalidWire();
    return OnboardingEvidence(
      uuid(x['evidenceId']),
      integer(x['inputRevision']),
      canonical(x['canonicalPlaceId']),
      wireText(x['catalogueReleaseId'], 100),
      status,
      nullableText(x['reasonCode']),
      wireText(x['timezoneId'], 100),
      offset,
      utc,
      x['confirmedAt'] == null ? null : instant(x['confirmedAt']),
    );
  }
}

class OnboardingDraft {
  final int revision;
  final String receiptId, policy;
  final BirthDraft? birth;
  final OnboardingEvidence? evidence;
  const OnboardingDraft(
    this.revision,
    this.receiptId,
    this.policy,
    this.birth,
    this.evidence,
  );
  factory OnboardingDraft.fromJson(Object? value) {
    final x = wire(value, ['draft', 'evidence']),
        rev = integer(x['inputRevision']),
        birth = x['draft'] == null ? null : BirthDraft.fromJson(x['draft']),
        e = x['evidence'] == null
            ? null
            : OnboardingEvidence.fromJson(x['evidence']);
    if (e != null && (birth == null || e.revision != rev)) invalidWire();
    return OnboardingDraft(
      rev,
      uuid(x['consentReceiptId']),
      wireVersion(x['policyVersion']),
      birth,
      e,
    );
  }
}

class PlaceCandidate {
  final String id, name, countryCode, featureCode, country, precision;
  final String? state, district, stateCode, districtCode;
  final double latitude, longitude;
  const PlaceCandidate(
    this.id,
    this.name,
    this.countryCode,
    this.featureCode,
    this.country,
    this.state,
    this.district,
    this.stateCode,
    this.districtCode,
    this.latitude,
    this.longitude,
    this.precision,
  );
  String get hierarchy =>
      [district, state, country].whereType<String>().join(' · ');
  factory PlaceCandidate.fromJson(Object? value) {
    final x = wire(value),
        h = wire(x['hierarchy'], [
          'state',
          'district',
          'stateCode',
          'districtCode',
        ]),
        c = wire(x['coordinates']);
    double coordinate(Object? v, int max) =>
        v is num && v.isFinite && v.abs() <= max ? v.toDouble() : invalidWire();
    final country = wireText(x['countryCode'], 2);
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(country)) invalidWire();
    return PlaceCandidate(
      canonical(x['canonicalId']),
      wireText(x['name']),
      country,
      wireText(x['featureCode'], 16),
      wireText(h['country']),
      nullableText(h['state']),
      nullableText(h['district']),
      nullableText(h['stateCode']),
      nullableText(h['districtCode']),
      coordinate(c['latitude'], 90),
      coordinate(c['longitude'], 180),
      choice(c['precision'], {
        'LOCALITY_REPRESENTATIVE',
        'ADMINISTRATIVE_REPRESENTATIVE',
      }),
    );
  }
}

class PlaceSearchResult {
  final String releaseId;
  final List<PlaceCandidate> items;
  PlaceSearchResult(this.releaseId, Iterable<PlaceCandidate> items)
    : items = List.unmodifiable(items);
  factory PlaceSearchResult.fromJson(Object? value) {
    final x = wire(value), a = x['items'];
    if (x['requiresSelection'] != true || a is! List || a.length > 20) {
      invalidWire();
    }
    final items = a.map(PlaceCandidate.fromJson).toList();
    if (items.map((p) => p.id).toSet().length != items.length) invalidWire();
    return PlaceSearchResult(wireText(x['releaseId'], 100), items);
  }
}

class PlaceSearchInput {
  final String query, language;
  final String? country;
  final int limit;
  const PlaceSearchInput(
    this.query, {
    this.language = 'en',
    this.country,
    this.limit = 10,
  });
  Map<String, Object> toJson() => {
    'query': query,
    'language': language,
    'limit': limit,
    'countryCode': ?country,
  };
}

class ResolutionInput {
  final int revision;
  final String receiptId, releaseId, placeId;
  final int? offset;
  const ResolutionInput(
    this.revision,
    this.receiptId,
    this.releaseId,
    this.placeId,
    this.offset,
  );
  Map<String, Object> toJson() => {
    'expectedRevision': revision,
    'consentReceiptId': receiptId,
    'catalogueReleaseId': releaseId,
    'canonicalPlaceId': placeId,
    'offsetSeconds': ?offset,
  };
}

class PlaceResolution {
  final String status;
  final int revision;
  final String? evidenceId, reason;
  final List<int> offsets;
  PlaceResolution(
    this.status,
    this.revision,
    this.evidenceId,
    this.reason,
    Iterable<int> offsets,
  ) : offsets = List.unmodifiable(offsets);
  factory PlaceResolution.fromJson(Object? value) {
    final x = wire(value);
    if (x['complete'] != false ||
        x['benchmarkOnly'] != true ||
        x['productionApproved'] != false) {
      invalidWire();
    }
    final s = choice(x['status'], {
          'RESOLVED',
          'FOLD',
          'LOCALITY_REQUIRED',
          'LOCATION_UNRESOLVED',
          'REVIEW_REQUIRED',
          'UNSUPPORTED_DATE',
          'UNSUPPORTED_ZONE',
        }),
        e = x.containsKey('evidenceId') ? uuid(x['evidenceId']) : null;
    var offsets = <int>[];
    if (x.containsKey('offsetChoices')) {
      final a = x['offsetChoices'];
      if (a is! List || a.length < 2 || a.length > 256) invalidWire();
      offsets = a.map((v) => integer(v, -93600, 93600)).toList();
      if (offsets.toSet().length != offsets.length) invalidWire();
    }
    if ((s == 'FOLD' && (e == null || offsets.isEmpty)) ||
        (s == 'RESOLVED' && e == null)) {
      invalidWire();
    }
    return PlaceResolution(
      s,
      integer(x['inputRevision']),
      e,
      x.containsKey('reason') ? wireText(x['reason']) : null,
      offsets,
    );
  }
}

class SavedBirth {
  final String message;
  final int revision;
  const SavedBirth(this.message, this.revision);
  factory SavedBirth.fromJson(Object? value) {
    final x = wire(value);
    if (x['complete'] != false) invalidWire();
    return SavedBirth(wireText(x['message']), integer(x['inputRevision'], 1));
  }
}

class ConfirmationInput {
  final int revision;
  final String receiptId, evidenceId, policy;
  const ConfirmationInput(
    this.revision,
    this.receiptId,
    this.evidenceId,
    this.policy,
  );
  Map<String, Object> toJson() => {
    'expectedRevision': revision,
    'consentReceiptId': receiptId,
    'evidenceId': evidenceId,
    'policyVersion': policy,
    'reviewConfirmed': true,
  };
}

class OnboardingConfirmation {
  final String evidenceId, confirmedAt;
  final int revision;
  const OnboardingConfirmation(
    this.evidenceId,
    this.revision,
    this.confirmedAt,
  );
  factory OnboardingConfirmation.fromJson(Object? value) {
    final x = wire(value);
    if (x['benchmarkOnly'] != true ||
        x['productionApproved'] != false ||
        x['requirementsSatisfied'] != false) {
      invalidWire();
    }
    return OnboardingConfirmation(
      uuid(x['evidenceId']),
      integer(x['inputRevision']),
      instant(x['confirmedAt']),
    );
  }
}

class SocialEligibility {
  final String state, mode, policy, nextAction;
  final bool satisfied, allowed;
  final int revision;
  final List<String> missing;
  SocialEligibility(
    this.state,
    this.satisfied,
    this.allowed,
    this.mode,
    this.policy,
    this.revision,
    Iterable<String> missing,
    this.nextAction,
  ) : missing = List.unmodifiable(missing);
  factory SocialEligibility.fromJson(Object? value) {
    final x = wire(value),
        s = choice(x['state'], {
          'CONSENT_REQUIRED',
          'DETAILS_REQUIRED',
          'LOCATION_UNRESOLVED',
          'REVIEW_REQUIRED',
          'READY',
          'CONSENT_WITHDRAWN',
        }),
        satisfied = boolean(x['requirementsSatisfied']),
        allowed = boolean(x['socialAccessAllowed']),
        mode = choice(x['enforcementMode'], {'OFF', 'OBSERVE', 'ENFORCE'}),
        a = x['missingRequirements'];
    if (a is! List || a.length > 20) invalidWire();
    final missing = a
        .map(
          (v) => choice(v, {
            'ASTROLOGY_CONSENT',
            'BIRTH_DATE',
            'EXACT_BIRTH_TIME',
            'ADULT_ELIGIBILITY',
            'LOCATION_EVIDENCE',
            'HISTORICAL_TIME_REVIEW',
            'DST_FOLD_SELECTION',
            'SOURCE_APPROVAL',
            'NOTICE_APPROVAL',
            'REVIEW_CONFIRMATION',
          }),
        )
        .toList();
    final expected = s == 'READY'
        ? 'SOCIAL_ACCESS'
        : s == 'CONSENT_REQUIRED' || s == 'CONSENT_WITHDRAWN'
        ? 'REVIEW_CONSENT'
        : s == 'DETAILS_REQUIRED'
        ? 'PROVIDE_BIRTH_DETAILS'
        : s == 'LOCATION_UNRESOLVED'
        ? 'SELECT_BIRTHPLACE'
        : 'REVIEW_ONBOARDING';
    if (satisfied != (s == 'READY') ||
        (satisfied && missing.isNotEmpty) ||
        allowed != (mode == 'ENFORCE' ? satisfied : true) ||
        x['nextAction'] != expected) {
      invalidWire();
    }
    return SocialEligibility(
      s,
      satisfied,
      allowed,
      mode,
      wireVersion(x['policyVersion']),
      integer(x['inputRevision']),
      missing,
      expected,
    );
  }
}
