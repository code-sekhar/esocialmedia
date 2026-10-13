// Synthetic contract broker for tests only; no real backend or READY fixture.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:esocialmedia/core/auth/auth_api.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';

const receiptId = '11111111-1111-4111-8111-111111111111',
    evidenceId = '22222222-2222-4222-8222-222222222222';
Map<String, Object?> notice(String p) => {
  'purpose': p,
  'version': 'development-${p.toLowerCase()}-v1',
  'digest': 'a' * 64,
  'text': 'DEVELOPMENT TEST ONLY. <b>Original server notice</b>',
  'language': 'en',
  'approval': 'PENDING',
  'developmentOnly': true,
};
Map<String, Object?> receipt(
  String p, {
  String action = 'GRANTED',
  int revision = 1,
}) => {
  'receiptId': receiptId,
  'purpose': p,
  'action': action,
  'noticeVersion': notice(p)['version'],
  'noticeDigest': notice(p)['digest'],
  'consentRevision': revision,
  'adultAttestation': p == 'ASTROLOGY' && action == 'GRANTED'
      ? 'SELF_DECLARED_ADULT'
      : null,
  'createdAt': '2026-10-14T00:00:00.000Z',
};
Map<String, Object?> current(String p, [Map<String, Object?>? r]) => {
  'purpose': p,
  'consentRevision': r?['consentRevision'] ?? 0,
  'receipt': r,
};
Map<String, Object?> eligibility(String state, int revision) => {
  'state': state,
  'requirementsSatisfied': false,
  'socialAccessAllowed': true,
  'enforcementMode': 'OFF',
  'policyVersion': 'development-onboarding-v1',
  'inputRevision': revision,
  'missingRequirements':
      state == 'CONSENT_REQUIRED' || state == 'CONSENT_WITHDRAWN'
      ? ['ASTROLOGY_CONSENT']
      : state == 'DETAILS_REQUIRED'
      ? ['EXACT_BIRTH_TIME']
      : state == 'LOCATION_UNRESOLVED'
      ? ['LOCATION_EVIDENCE']
      : ['SOURCE_APPROVAL', 'NOTICE_APPROVAL'],
  'nextAction': state == 'CONSENT_REQUIRED' || state == 'CONSENT_WITHDRAWN'
      ? 'REVIEW_CONSENT'
      : state == 'DETAILS_REQUIRED'
      ? 'PROVIDE_BIRTH_DETAILS'
      : state == 'LOCATION_UNRESOLVED'
      ? 'SELECT_BIRTHPLACE'
      : 'REVIEW_ONBOARDING',
};
Map<String, Object?> candidate(String id, String name, String district) => {
  'canonicalId': id,
  'name': name,
  'countryCode': 'IN',
  'featureCode': 'PPL',
  'hierarchy': {
    'country': 'India',
    'state': 'West Bengal',
    'district': district,
    'stateCode': null,
    'districtCode': null,
  },
  'coordinates': {
    'latitude': 22.56,
    'longitude': 88.36,
    'precision': 'LOCALITY_REPRESENTATIVE',
  },
};
Map<String, Object?> get places => {
  'releaseId': 'synthetic-test-release',
  'requiresSelection': true,
  'items': [
    candidate('geonames:1275004', 'Kolkata', 'Kolkata'),
    candidate('geonames:1275005', 'Kolkata', 'Synthetic different district'),
  ],
};
ResponseBody jsonResponse(Object? body, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

class ContractBroker implements HttpClientAdapter {
  bool enabled = true;
  int revision = 0, refreshes = 0;
  String userId = 'synthetic-owner', resolutionStatus = 'RESOLVED';
  final requests = <RequestOptions>[];
  final states = <String, Map<String, Object?>>{};
  final retries = <String, Map<String, Object?>>{};
  Map<String, Object?>? birth, evidence;
  Future<ResponseBody>? Function(RequestOptions)? respondOverride;
  Map<String, Object?> get user => {
    'id': userId,
    'email': 'owner@example.invalid',
    'username': 'synthetic_owner',
  };
  Map<String, Object?> get draft => {
    'inputRevision': revision,
    'consentReceiptId': receiptId,
    'policyVersion': 'development-onboarding-v1',
    'draft': birth,
    'evidence': evidence,
  };
  bool get granted => states['ASTROLOGY']?['action'] == 'GRANTED';
  Map<String, Object?> get status => eligibility(
    states['ASTROLOGY']?['action'] == 'WITHDRAWN'
        ? 'CONSENT_WITHDRAWN'
        : !granted
        ? 'CONSENT_REQUIRED'
        : birth == null || birth!['birthTimeKnown'] != true
        ? 'DETAILS_REQUIRED'
        : evidence == null
        ? 'LOCATION_UNRESOLVED'
        : 'REVIEW_REQUIRED',
    revision,
  );
  ResponseBody failure(int status, String code) => jsonResponse({
    'statusCode': status,
    'code': code,
    'message': 'Synthetic fixture error',
    'error': 'Fixture',
  }, status);
  AuthSession session({RefreshStore? store}) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1/'));
    dio.httpClientAdapter = this;
    return AuthSession(
      api: AuthApi(client: dio),
      store: store ?? MemoryRefreshStore(),
    );
  }

  Future<void> login(AuthSession session) =>
      session.login('owner@example.invalid', 'synthetic browser passphrase');
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(o);
    final replacement = respondOverride?.call(o);
    if (replacement != null) return replacement;
    final p = o.path;
    final b = o.data is Map
        ? Map<String, Object?>.from(o.data as Map)
        : <String, Object?>{};
    if (p == 'auth/login') return jsonResponse({...userPair, 'user': user});
    if (p == 'auth/refresh') {
      refreshes++;
      return jsonResponse(userPair);
    }
    if (p == 'auth/logout' || p == 'auth/logout-all') {
      return jsonResponse({'message': 'Synthetic revoked'});
    }
    if (p == 'users/me') return jsonResponse(user);
    if (!enabled) return failure(404, 'API_DISABLED');
    if (p.contains('/consent/notices/')) {
      return jsonResponse(notice(p.split('/').last));
    }
    if (p == 'users/me/social-eligibility') return jsonResponse(status);
    if (o.method == 'GET' && p.startsWith('users/me/consent/receipts/')) {
      if (p.split('/').last != receiptId || states['ASTROLOGY'] == null) {
        return failure(404, 'RESOURCE_UNAVAILABLE');
      }
      return jsonResponse(states['ASTROLOGY']);
    }
    if (o.method == 'GET' && p.contains('/consent/')) {
      return jsonResponse(
        current(p.split('/').last, states[p.split('/').last]),
      );
    }
    if (p == 'users/me/consent' || p == 'users/me/consent/withdraw') {
      final key = b['idempotencyKey'] as String;
      if (retries.containsKey(key)) return jsonResponse(retries[key], 201);
      final purpose = b['purpose'] as String,
          rev = states[purpose]?['consentRevision'] ?? 0;
      if (b['expectedConsentRevision'] != rev) {
        return failure(409, 'CONSENT_REVISION_CONFLICT');
      }
      final action = p.endsWith('/withdraw')
              ? 'WITHDRAWN'
              : b['action'] as String,
          r = receipt(purpose, action: action, revision: (rev as int) + 1);
      states[purpose] = r;
      retries[key] = r;
      if (purpose == 'ASTROLOGY' && action != 'GRANTED') {
        revision++;
        evidence = null;
      }
      return jsonResponse(r, 201);
    }
    if (!granted) return failure(403, 'ASTROLOGY_CONSENT_REQUIRED');
    if (p == 'users/me/astrology/onboarding') {
      if (o.method == 'PATCH') {
        if (b['expectedRevision'] != revision) {
          return failure(409, 'INPUT_REVISION_CONFLICT');
        }
        revision++;
        birth = {
          'birthDate': b['birthDate'],
          'birthTimeKnown': b['birthTimeKnown'],
          'birthTime': b['birthTime'],
          'birthPlace': null,
          'birthCountry': null,
          'birthState': null,
        };
        evidence = null;
        return jsonResponse({
          'message': 'Synthetic draft saved',
          'inputRevision': revision,
          'complete': false,
        });
      }
      return jsonResponse(draft);
    }
    if (p == 'users/me/astrology/places/search') {
      return jsonResponse(places, 201);
    }
    if (p == 'users/me/astrology/resolve') {
      if (b['expectedRevision'] != revision) {
        return failure(409, 'INPUT_REVISION_CONFLICT');
      }
      if (resolutionStatus == 'GAP') return failure(400, 'GAP');
      if (resolutionStatus == 'FOLD' && b['offsetSeconds'] == null) {
        revision++;
        return jsonResponse({
          'status': 'FOLD',
          'inputRevision': revision,
          'complete': false,
          'benchmarkOnly': true,
          'productionApproved': false,
          'evidenceId': evidenceId,
          'offsetChoices': [-18000, -14400],
        }, 201);
      }
      revision++;
      birth = {
        ...birth!,
        'birthPlace': 'Kolkata',
        'birthCountry': 'IN',
        'birthState': 'West Bengal',
      };
      evidence = {
        'evidenceId': evidenceId,
        'inputRevision': revision,
        'canonicalPlaceId': b['canonicalPlaceId'],
        'catalogueReleaseId': b['catalogueReleaseId'],
        'validationStatus': 'RESOLVED',
        'reasonCode': 'BENCHMARK_ONLY',
        'timezoneId': 'Asia/Kolkata',
        'offsetSeconds': 19800,
        'resolvedInstant': '2000-01-01T07:00:00.000Z',
        'confirmedAt': null,
        'benchmarkOnly': true,
      };
      return jsonResponse({
        'status': 'RESOLVED',
        'inputRevision': revision,
        'complete': false,
        'benchmarkOnly': true,
        'productionApproved': false,
        'evidenceId': evidenceId,
      }, 201);
    }
    if (p == 'users/me/astrology/confirm') {
      if (b['expectedRevision'] != revision || evidence == null) {
        return failure(409, 'EVIDENCE_STALE');
      }
      evidence!['confirmedAt'] ??= '2026-10-14T00:00:00.000Z';
      return jsonResponse({
        'evidenceId': evidenceId,
        'inputRevision': revision,
        'confirmedAt': evidence!['confirmedAt'],
        'benchmarkOnly': true,
        'productionApproved': false,
        'requirementsSatisfied': false,
      }, 201);
    }
    return failure(404, 'RESOURCE_UNAVAILABLE');
  }

  static Map<String, String> get userPair => {
    'accessToken': 'synthetic-access',
    'refreshToken': 'a' * 128,
  };
}
