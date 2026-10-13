import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/auth/auth_session.dart';
import '../../core/auth/private_api_error.dart';
import 'onboarding_api.dart';
import 'onboarding_models.dart';

// Component-scoped private state; never retained in application storage.
class OnboardingController extends ChangeNotifier {
  final OnboardingApi api;
  final AuthSession session;
  late int _epoch;
  late String? _owner;
  bool _disposed = false;
  int _searchSerial = 0;
  Timer? _timer;
  bool busy = false,
      searchBusy = false,
      disabled = false,
      reconcile = false,
      termsAccepted = false,
      astrologyAccepted = false,
      adult = false,
      review = false;
  String? failure, message, searchFailure;
  String date = '', time = '', query = '', country = '', searchLanguage = 'en';
  bool? known;
  int? offset;
  Map<ConsentPurpose, ConsentNotice> notices = {};
  Map<ConsentPurpose, ConsentState> consents = {};
  OnboardingDraft? draft;
  SocialEligibility? eligibility;
  PlaceSearchResult? results;
  PlaceCandidate? selected;
  PlaceResolution? resolution;
  ConsentRequest? pending;
  OnboardingController(this.api) : session = api.session {
    _epoch = session.identityEpoch;
    _owner = session.account?.id;
    session.addListener(_identityChanged);
  }
  bool _current(int epoch) => !_disposed && session.identityEpoch == epoch;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _identityChanged() {
    if (_owner != session.account?.id || _epoch != session.identityEpoch) {
      clearPrivate();
      _owner = session.account?.id;
      _epoch = session.identityEpoch;
      failure = 'SESSION_CHANGED';
      _emit();
    }
  }

  void _clearSearch() {
    _searchSerial++;
    searchBusy = false;
    results = null;
    selected = null;
    resolution = null;
    offset = null;
    searchFailure = null;
    review = false;
  }

  void clearPrivate() {
    _timer?.cancel();
    _clearSearch();
    notices = {};
    consents = {};
    draft = null;
    eligibility = null;
    pending = null;
    date = '';
    time = '';
    known = null;
    query = '';
    country = '';
    searchLanguage = 'en';
    termsAccepted = false;
    astrologyAccepted = false;
    adult = false;
    review = false;
    busy = false;
    disabled = false;
    reconcile = false;
    message = null;
  }

  bool get granted {
    final r = consents[ConsentPurpose.astrology]?.receipt,
        n = notices[ConsentPurpose.astrology];
    return r?.action == 'GRANTED' &&
        r?.adultAttestation == 'SELF_DECLARED_ADULT' &&
        r?.noticeVersion == n?.version &&
        r?.noticeDigest == n?.digest;
  }

  bool get actionable =>
      session.authenticated && !busy && !disabled && !reconcile;
  bool get exactSaved =>
      draft?.birth?.known == true &&
      draft?.birth?.time != null &&
      validBirth(date, known, time) &&
      date == draft?.birth?.date &&
      known == true &&
      time == draft?.birth?.time;
  bool get canResolve =>
      actionable &&
      granted &&
      exactSaved &&
      selected != null &&
      (resolution?.status != 'FOLD' || offset != null);
  bool get canConfirm =>
      actionable &&
      granted &&
      exactSaved &&
      draft?.evidence?.status == 'RESOLVED' &&
      review;
  bool get canRetryConsent =>
      actionable &&
      pending != null &&
      (pending!.withdrawal ||
          (pending!.noticeVersion == notices[pending!.purpose]?.version &&
              pending!.noticeDigest == notices[pending!.purpose]?.digest));
  static String _key() {
    final random = Random.secure(),
        a = List.generate(16, (_) => random.nextInt(256));
    a[6] = (a[6] & 15) | 64;
    a[8] = (a[8] & 63) | 128;
    final s = a.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
  }

  Future<void> _fetch(int epoch, {bool keepSelection = false}) async {
    if (!_current(epoch)) return;
    final values = await Future.wait<Object>([
      api.notice(ConsentPurpose.generalTerms),
      api.notice(ConsentPurpose.astrology),
      api.current(ConsentPurpose.generalTerms),
      api.current(ConsentPurpose.astrology),
      api.eligibility(),
    ]);
    if (!_current(epoch)) return;
    final nt = values[0] as ConsentNotice,
        na = values[1] as ConsentNotice,
        ct = values[2] as ConsentState,
        ca = values[3] as ConsentState,
        e = values[4] as SocialEligibility;
    final r = ca.receipt,
        valid =
            r?.action == 'GRANTED' &&
            r?.adultAttestation == 'SELF_DECLARED_ADULT' &&
            r?.noticeVersion == na.version &&
            r?.noticeDigest == na.digest;
    final d = valid ? await api.draft() : null;
    if (!_current(epoch)) return;
    if (d != null && d.receiptId != r!.id) {
      throw const PrivateApiFailure(409, 'CONSENT_REVISION_CONFLICT');
    }
    if (d != null && d.revision != e.revision) {
      throw const PrivateApiFailure(409, 'INPUT_REVISION_CONFLICT');
    }
    notices = {ConsentPurpose.generalTerms: nt, ConsentPurpose.astrology: na};
    consents = {ConsentPurpose.generalTerms: ct, ConsentPurpose.astrology: ca};
    eligibility = e;
    draft = d;
    date = d?.birth?.date ?? '';
    time = d?.birth?.time ?? '';
    known = d?.birth?.known;
    review = false;
    if (!keepSelection || !valid) _clearSearch();
    if (!valid) {
      query = '';
      country = '';
      searchLanguage = 'en';
    }
    disabled = false;
    reconcile = false;
  }

  void _handle(Object error) {
    final e = PrivateApiFailure.from(error);
    failure = e.code;
    if (e.status == 401 || e.code == 'API_DISABLED') {
      clearPrivate();
      failure = e.code;
      disabled = e.code == 'API_DISABLED';
    }
  }

  Future<void> load() async {
    if (busy || _disposed) return;
    final epoch = session.identityEpoch;
    busy = true;
    failure = null;
    _emit();
    try {
      await _fetch(epoch);
    } catch (e) {
      if (_current(epoch)) _handle(e);
    } finally {
      if (_current(epoch)) {
        busy = false;
        _emit();
      }
    }
  }

  Future<void> _mutate(Future<void> Function(int) work) async {
    if (!actionable) return;
    final epoch = session.identityEpoch;
    busy = true;
    failure = null;
    message = null;
    _emit();
    try {
      await work(epoch);
      if (_current(epoch)) message = 'saved';
    } catch (error) {
      if (!_current(epoch)) return;
      final e = PrivateApiFailure.from(error);
      _handle(e);
      if (e.uncertain) {
        reconcile = true;
        message = 'uncertain';
      } else if (e.status == 409 || e.code == 'ASTROLOGY_CONSENT_REQUIRED') {
        try {
          await _fetch(epoch);
          if (_current(epoch)) message = 'conflict';
        } catch (e) {
          if (_current(epoch)) {
            _handle(e);
            reconcile = true;
          }
        }
      }
    } finally {
      if (_current(epoch)) {
        busy = false;
        _emit();
      }
    }
  }

  void acceptance(ConsentPurpose p, bool value) {
    if (p == ConsentPurpose.generalTerms) {
      termsAccepted = value;
    } else {
      astrologyAccepted = value;
    }
    _emit();
  }

  void attest(bool value) {
    adult = value;
    _emit();
  }

  Future<void> decide(ConsentPurpose p, String action) async {
    if (action != 'GRANTED' && action != 'REFUSED') return;
    if (action == 'GRANTED' &&
        (!(p == ConsentPurpose.generalTerms
                ? termsAccepted
                : astrologyAccepted) ||
            (p == ConsentPurpose.astrology && !adult))) {
      return;
    }
    final n = notices[p], c = consents[p];
    if (n == null || c == null) return;
    final request = ConsentRequest(
      purpose: p,
      revision: c.revision,
      key: _key(),
      action: action,
      noticeVersion: n.version,
      noticeDigest: n.digest,
      adult: p == ConsentPurpose.astrology && action == 'GRANTED',
    );
    await _mutate((epoch) async {
      pending = request;
      await api.consent(request);
      if (!_current(epoch)) return;
      pending = null;
      termsAccepted = false;
      astrologyAccepted = false;
      adult = false;
      await _fetch(epoch);
    });
  }

  Future<void> withdraw(ConsentPurpose p) async {
    final c = consents[p];
    if (c == null) return;
    final request = ConsentRequest(
      purpose: p,
      revision: c.revision,
      key: _key(),
    );
    await _mutate((epoch) async {
      pending = request;
      await api.consent(request);
      if (!_current(epoch)) return;
      pending = null;
      termsAccepted = false;
      astrologyAccepted = false;
      adult = false;
      await _fetch(epoch);
    });
  }

  Future<void> retryConsent() async {
    if (!canRetryConsent) return;
    final request = pending!;
    await _mutate((epoch) async {
      await api.consent(request);
      if (!_current(epoch)) return;
      pending = null;
      await _fetch(epoch);
    });
  }

  void birthChanged({String? dateValue, String? timeValue, bool? knownValue}) {
    if (dateValue != null) date = dateValue;
    if (timeValue != null) time = timeValue;
    if (knownValue != null) {
      known = knownValue;
      if (!knownValue) time = '';
    }
    review = false;
    _emit();
  }

  Future<void> saveBirth() async {
    if (!granted || !validBirth(date, known, time)) {
      failure = 'INVALID_INPUT';
      _emit();
      return;
    }
    final request = BirthInput(
      draft?.revision ?? 0,
      consents[ConsentPurpose.astrology]!.receipt!.id,
      date,
      known!,
      known! ? time : null,
    );
    await _mutate((epoch) async {
      await api.save(request);
      await _fetch(epoch);
    });
  }

  void searchChanged({
    String? queryValue,
    String? countryValue,
    String? languageValue,
  }) {
    if (queryValue != null) query = queryValue;
    if (countryValue != null) country = countryValue;
    if (languageValue != null) searchLanguage = languageValue;
    _clearSearch();
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), () => search());
    _emit();
  }

  Future<void> search({bool deliberate = false}) async {
    _timer?.cancel();
    if (!granted || !actionable) return;
    final q = query.trim();
    if (q.runes.length < 2 ||
        q.runes.length > 80 ||
        query.length > 160 ||
        (country.isNotEmpty && !RegExp(r'^[A-Z]{2}$').hasMatch(country))) {
      if (deliberate) {
        searchFailure = 'INVALID_INPUT';
        _emit();
      }
      return;
    }
    final serial = ++_searchSerial, epoch = session.identityEpoch;
    searchBusy = true;
    searchFailure = null;
    results = null;
    selected = null;
    _emit();
    try {
      final result = await api.search(
        PlaceSearchInput(
          q,
          language: searchLanguage,
          country: country.isEmpty ? null : country,
        ),
      );
      if (_current(epoch) && serial == _searchSerial) results = result;
    } catch (error) {
      if (_current(epoch) && serial == _searchSerial) {
        final e = PrivateApiFailure.from(error);
        searchFailure = e.code;
        if (e.status == 401) {
          _handle(e);
        } else if (e.code == 'ASTROLOGY_CONSENT_REQUIRED') {
          await load();
        }
      }
    } finally {
      if (_current(epoch) && serial == _searchSerial) {
        searchBusy = false;
        _emit();
      }
    }
  }

  void select(PlaceCandidate place) {
    if (!actionable || results?.items.any((p) => p.id == place.id) != true) {
      return;
    }
    selected = place;
    resolution = null;
    offset = null;
    review = false;
    _emit();
  }

  void selectOffset(int? value) {
    offset = resolution?.offsets.contains(value) == true ? value : null;
    _emit();
  }

  void setReview(bool value) {
    review = value;
    _emit();
  }

  Future<void> resolve() async {
    if (!canResolve) return;
    final request = ResolutionInput(
      draft!.revision,
      consents[ConsentPurpose.astrology]!.receipt!.id,
      results!.releaseId,
      selected!.id,
      offset,
    );
    await _mutate((epoch) async {
      final r = await api.resolve(request);
      await _fetch(epoch, keepSelection: true);
      if (_current(epoch)) {
        if (draft?.revision != r.revision) {
          throw const PrivateApiFailure(409, 'INPUT_REVISION_CONFLICT');
        }
        resolution = r;
        offset = null;
      }
    });
  }

  Future<void> confirm() async {
    if (!canConfirm) return;
    final d = draft!,
        request = ConfirmationInput(
          d.revision,
          consents[ConsentPurpose.astrology]!.receipt!.id,
          d.evidence!.id,
          d.policy,
        );
    await _mutate((epoch) async {
      await api.confirm(request);
      await _fetch(epoch, keepSelection: true);
    });
  }

  @override
  void dispose() {
    session.removeListener(_identityChanged);
    _disposed = true;
    clearPrivate();
    super.dispose();
  }
}
