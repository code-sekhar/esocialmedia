import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_session.dart';
import '../../core/auth/private_api_error.dart';
import 'onboarding_models.dart';

class OnboardingApi {
  final AuthSession session;
  const OnboardingApi(this.session);
  Future<T> request<T>(
    String method,
    String path,
    T Function(Object?) decode, [
    Object? input,
  ]) async {
    try {
      return decode(
        await session.privateRequest(
          'users/me/$path',
          method: method,
          body: input,
        ),
      );
    } on AuthFailure catch (error) {
      throw switch (error.problem) {
        AuthProblem.credentials || AuthProblem.expired =>
          const PrivateApiFailure(401, 'SESSION_UNAVAILABLE'),
        AuthProblem.rate => const PrivateApiFailure(429, 'RATE_LIMITED'),
        AuthProblem.unavailable => const PrivateApiFailure(
          503,
          'DEPENDENCY_UNAVAILABLE',
        ),
        AuthProblem.protocol => const PrivateApiFailure(0, 'PROTOCOL'),
        _ => const PrivateApiFailure(0, 'NETWORK_UNCERTAIN'),
      };
    } catch (error) {
      throw PrivateApiFailure.from(error);
    }
  }

  Future<ConsentNotice> notice(ConsentPurpose p) => request(
    'GET',
    'consent/notices/${p.wireName}',
    (x) => ConsentNotice.fromJson(x, p),
  );
  Future<ConsentState> current(ConsentPurpose p) => request(
    'GET',
    'consent/${p.wireName}',
    (x) => ConsentState.fromJson(x, p),
  );
  Future<ConsentReceipt> receipt(String id, ConsentPurpose p) => request(
    'GET',
    'consent/receipts/${uuid(id)}',
    (x) => ConsentReceipt.fromJson(x, p),
  );
  Future<ConsentReceipt> consent(ConsentRequest input) => request(
    'POST',
    input.withdrawal ? 'consent/withdraw' : 'consent',
    (x) => ConsentReceipt.fromJson(x, input.purpose),
    input.toJson(),
  );
  Future<OnboardingDraft> draft() =>
      request('GET', 'astrology/onboarding', OnboardingDraft.fromJson);
  Future<SavedBirth> save(BirthInput input) => request(
    'PATCH',
    'astrology/onboarding',
    SavedBirth.fromJson,
    input.toJson(),
  );
  Future<PlaceSearchResult> search(PlaceSearchInput input) => request(
    'POST',
    'astrology/places/search',
    PlaceSearchResult.fromJson,
    input.toJson(),
  );
  Future<PlaceResolution> resolve(ResolutionInput input) => request(
    'POST',
    'astrology/resolve',
    PlaceResolution.fromJson,
    input.toJson(),
  );
  Future<OnboardingConfirmation> confirm(ConfirmationInput input) => request(
    'POST',
    'astrology/confirm',
    OnboardingConfirmation.fromJson,
    input.toJson(),
  );
  Future<SocialEligibility> eligibility() =>
      request('GET', 'social-eligibility', SocialEligibility.fromJson);
}
