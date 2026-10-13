import 'package:dio/dio.dart';

class PrivateApiFailure implements Exception {
  final int status;
  final String code;
  const PrivateApiFailure(this.status, this.code);
  bool get uncertain => status == 0 || status >= 500;
  static const codes = {
    'INVALID_INPUT',
    'SESSION_UNAVAILABLE',
    'FORBIDDEN',
    'API_DISABLED',
    'RESOURCE_UNAVAILABLE',
    'NOTICE_CHANGED',
    'ADULT_ATTESTATION_REQUIRED',
    'ADULT_ELIGIBILITY_REQUIRED',
    'ASTROLOGY_CONSENT_REQUIRED',
    'IDEMPOTENCY_CONFLICT',
    'CONSENT_REVISION_CONFLICT',
    'INPUT_REVISION_CONFLICT',
    'BIRTH_DETAILS_REQUIRED',
    'CATALOGUE_CHANGED',
    'POLICY_CHANGED',
    'EVIDENCE_STALE',
    'RATE_LIMITED',
    'CATALOGUE_UNAVAILABLE',
    'RESOLVER_UNAVAILABLE',
    'ONBOARDING_UNAVAILABLE',
    'DEPENDENCY_UNAVAILABLE',
    'INTERNAL_ERROR',
    'SOURCE_APPROVAL_REQUIRED',
    'GAP',
    'INVALID_DISAMBIGUATION',
    'CONFLICT',
  };
  factory PrivateApiFailure.from(Object error) {
    if (error is PrivateApiFailure) return error;
    if (error is DioException) {
      final status = error.response?.statusCode ?? 0;
      if (status == 0) {
        return PrivateApiFailure(0, switch (error.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.sendTimeout => 'TIMEOUT_UNCERTAIN',
          _ => 'NETWORK_UNCERTAIN',
        });
      }
      final data = error.response?.data;
      if (data is Map<String, dynamic> &&
          data['statusCode'] == status &&
          codes.contains(data['code'])) {
        return PrivateApiFailure(status, data['code'] as String);
      }
      return PrivateApiFailure(
        status,
        status == 401 ? 'SESSION_UNAVAILABLE' : 'PROTOCOL',
      );
    }
    return const PrivateApiFailure(0, 'PROTOCOL');
  }
  @override
  String toString() => 'Private API request could not be confirmed';
}
