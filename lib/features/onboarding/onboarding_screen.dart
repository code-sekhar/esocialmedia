import 'package:flutter/material.dart';
import '../../core/auth/auth_scope.dart';
import '../../core/auth/auth_session.dart';
import '../../core/l10n/auth_copy.dart';
import '../privacy/privacy_screen.dart';
import '../../screen/account_screen.dart';
import '../../screen/dashboard/home_screen.dart';
import 'onboarding_api.dart';
import 'onboarding_controller.dart';
import 'onboarding_copy.dart';
import 'onboarding_models.dart';

class AstrologyOnboardingScreen extends StatefulWidget {
  const AstrologyOnboardingScreen({super.key});
  @override
  State<AstrologyOnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<AstrologyOnboardingScreen> {
  OnboardingController? model;
  AuthSession? session;
  bool controllerDisposed = false;
  final date = TextEditingController(),
      time = TextEditingController(),
      query = TextEditingController(),
      country = TextEditingController();
  String t(String key) => OnboardingCopy.text(key);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = AuthScope.of(context);
    if (session != current) {
      if (!controllerDisposed) model?.dispose();
      session = current;
      model = OnboardingController(OnboardingApi(current))
        ..addListener(_changed);
      controllerDisposed = false;
      model!.load();
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _sync(TextEditingController c, String value) {
    if (c.text != value) {
      c.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void dispose() {
    model?.removeListener(_changed);
    if (!controllerDisposed) model?.dispose();
    controllerDisposed = true;
    for (final c in [date, time, query, country]) {
      c.clear();
      c.dispose();
    }
    super.dispose();
  }

  Future<void> navigate(Widget screen) async {
    // Routes pushed on top keep their predecessor mounted. Erase private state
    // before leaving and create a fresh owner-scoped controller on return.
    model?.removeListener(_changed);
    if (!controllerDisposed) model?.dispose();
    controllerDisposed = true;
    for (final c in [date, time, query, country]) {
      c.clear();
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    final current = AuthScope.of(context);
    session = current;
    model = OnboardingController(OnboardingApi(current))..addListener(_changed);
    controllerDisposed = false;
    setState(() {});
    await model!.load();
  }

  Widget button(
    String key,
    String label,
    VoidCallback? action, {
    bool primary = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8, right: 8),
    child: primary
        ? FilledButton(
            key: ValueKey(key),
            onPressed: action,
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(label),
          )
        : OutlinedButton(
            key: ValueKey(key),
            onPressed: action,
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(label),
          ),
  );
  Widget card(String title, List<Widget> children, {Key? key}) => Card(
    key: key,
    margin: const EdgeInsets.only(bottom: 20),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
  Widget announce(String value) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(value),
    ),
  );
  String failureLabel(String code) => t(switch (code) {
    'SESSION_UNAVAILABLE' || 'SESSION_CHANGED' => 'session',
    'API_DISABLED' => 'disabled',
    'RATE_LIMITED' => 'rate',
    'GAP' => 'gap',
    'INVALID_DISAMBIGUATION' => 'invalidOffset',
    'NETWORK_UNCERTAIN' || 'TIMEOUT_UNCERTAIN' => 'uncertain',
    'PROTOCOL' => 'protocol',
    'ASTROLOGY_CONSENT_REQUIRED' ||
    'FORBIDDEN' ||
    'ADULT_ATTESTATION_REQUIRED' ||
    'ADULT_ELIGIBILITY_REQUIRED' ||
    'SOURCE_APPROVAL_REQUIRED' => 'permission',
    _ => code.contains('UNAVAILABLE') ? 'unavailable' : 'invalid',
  });
  Widget consentCard(ConsentPurpose p, OnboardingController m) {
    final n = m.notices[p],
        r = m.consents[p]?.receipt,
        isTerms = p == ConsentPurpose.generalTerms;
    return card(t(isTerms ? 'terms' : 'astrology'), [
      Text(
        '${t('currentConsent')}: ${t(r?.action == 'GRANTED'
            ? 'granted'
            : r?.action == 'REFUSED'
            ? 'refused'
            : r?.action == 'WITHDRAWN'
            ? 'inactive'
            : 'notGranted')}',
      ),
      if (n != null) ...[
        Text('${t('noticeVersion')}: ${n.version}'),
        const SizedBox(height: 12),
        Text(n.text, textDirection: TextDirection.ltr),
        CheckboxListTile(
          key: ValueKey('accept-${p.wireName}'),
          contentPadding: EdgeInsets.zero,
          title: Text(t('accept')),
          value: isTerms ? m.termsAccepted : m.astrologyAccepted,
          onChanged: m.actionable ? (v) => m.acceptance(p, v == true) : null,
        ),
        if (!isTerms)
          CheckboxListTile(
            key: const ValueKey('adult'),
            contentPadding: EdgeInsets.zero,
            title: Text(t('adult')),
            value: m.adult,
            onChanged: m.actionable ? (v) => m.attest(v == true) : null,
          ),
        Wrap(
          children: [
            button(
              'grant-${p.wireName}',
              t(r?.action == 'WITHDRAWN' ? 'reconsent' : 'grant'),
              m.actionable &&
                      (isTerms
                          ? m.termsAccepted
                          : m.astrologyAccepted && m.adult)
                  ? () => m.decide(p, 'GRANTED')
                  : null,
              primary: true,
            ),
            button(
              'refuse-${p.wireName}',
              t('refuse'),
              m.actionable ? () => m.decide(p, 'REFUSED') : null,
            ),
            if (r?.action == 'GRANTED')
              button(
                'withdraw-${p.wireName}',
                t('withdraw'),
                m.actionable ? () => m.withdraw(p) : null,
              ),
          ],
        ),
      ],
    ]);
  }

  Widget birthCard(OnboardingController m) => card(t('details'), [
    Text(t('adultHelp')),
    TextFormField(
      key: const ValueKey('birth-date'),
      controller: date,
      enabled: m.actionable,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) =>
          v == null || !dateLiteral(v) || v.compareTo(adultCutoff()) > 0
          ? t('validation')
          : null,
      decoration: InputDecoration(
        labelText: t('birthDate'),
        hintText: 'YYYY-MM-DD',
      ),
      keyboardType: TextInputType.datetime,
      maxLength: 10,
      onChanged: (v) => m.birthChanged(dateValue: v),
    ),
    Text(t('knowledge')),
    // Explicit three-state choice: no default time knowledge and no implied midnight.
    Wrap(
      spacing: 12,
      children: [
        ChoiceChip(
          key: const ValueKey('time-known'),
          label: Text(t('known')),
          selected: m.known == true,
          onSelected: m.actionable
              ? (_) => m.birthChanged(knownValue: true)
              : null,
        ),
        ChoiceChip(
          key: const ValueKey('time-unknown'),
          label: Text(t('unknown')),
          selected: m.known == false,
          onSelected: m.actionable
              ? (_) => m.birthChanged(knownValue: false)
              : null,
        ),
      ],
    ),
    if (m.known == true)
      TextFormField(
        key: const ValueKey('birth-time'),
        controller: time,
        enabled: m.actionable,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) => v == null || !timeLiteral(v) ? t('validation') : null,
        decoration: InputDecoration(
          labelText: '${t('birthTime')} · HH:MM',
          hintText: 'HH:MM',
        ),
        maxLength: 5,
        keyboardType: TextInputType.datetime,
        onChanged: (v) => m.birthChanged(timeValue: v),
      ),
    if (m.known == false) Text(t('unknownHelp')),
    button(
      'save-birth',
      t('save'),
      m.actionable ? m.saveBirth : null,
      primary: true,
    ),
  ]);
  Widget placeCard(OnboardingController m) => card(t('place'), [
    TextFormField(
      key: const ValueKey('place-query'),
      controller: query,
      enabled: m.actionable,
      decoration: InputDecoration(labelText: t('query')),
      maxLength: 160,
      onChanged: (v) => m.searchChanged(queryValue: v),
      onFieldSubmitted: (_) => m.search(deliberate: true),
    ),
    TextFormField(
      key: const ValueKey('country'),
      controller: country,
      enabled: m.actionable,
      decoration: InputDecoration(labelText: t('country'), hintText: 'IN'),
      maxLength: 2,
      textCapitalization: TextCapitalization.characters,
      onChanged: (v) => m.searchChanged(countryValue: v.toUpperCase()),
    ),
    DropdownButtonFormField<String>(
      key: ValueKey('place-language-${m.searchLanguage}'),
      initialValue: m.searchLanguage,
      decoration: InputDecoration(labelText: t('searchLanguage')),
      items: const [
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
        DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
      ],
      onChanged: m.actionable ? (v) => m.searchChanged(languageValue: v) : null,
    ),
    button(
      'search',
      t('searchAction'),
      m.actionable && !m.searchBusy ? () => m.search(deliberate: true) : null,
    ),
    if (m.searchBusy) ...[
      const LinearProgressIndicator(),
      announce(t('searching')),
    ],
    if (m.searchFailure != null) announce(failureLabel(m.searchFailure!)),
    if (m.results != null) ...[
      announce('${t('candidateCount')}: ${m.results!.items.length}'),
      if (m.results!.items.isEmpty) Text(t('empty')),
      for (final place in m.results!.items)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Semantics(
            selected: m.selected?.id == place.id,
            child: OutlinedButton(
              key: ValueKey('place-${place.id}'),
              onPressed: m.actionable ? () => m.select(place) : null,
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(16),
                backgroundColor: m.selected?.id == place.id
                    ? const Color(0xFFEFE5FF)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(place.hierarchy),
                  Text('${place.id} · ${place.featureCode}'),
                  Text(t('select')),
                ],
              ),
            ),
          ),
        ),
    ],
    if (m.selected != null)
      Text('${t('selected')}: ${m.selected!.name} · ${m.selected!.hierarchy}'),
    if (!m.exactSaved) Text(t('noDetails')),
    if (m.resolution != null) ...[
      announce(
        t(switch (m.resolution!.status) {
          'RESOLVED' => 'resolved',
          'FOLD' => 'fold',
          'LOCALITY_REQUIRED' => 'locality',
          'REVIEW_REQUIRED' => 'sourceBlocked',
          'UNSUPPORTED_DATE' || 'UNSUPPORTED_ZONE' => 'historical',
          _ => 'unresolved',
        }),
      ),
      if (m.resolution!.status == 'FOLD')
        DropdownButtonFormField<int>(
          key: ValueKey('offset-${m.resolution!.revision}-${m.offset}'),
          initialValue: m.offset,
          decoration: InputDecoration(
            labelText: t('offset'),
            hintText: t('chooseOffset'),
          ),
          items: m.resolution!.offsets
              .map(
                (v) => DropdownMenuItem(value: v, child: Text(formatOffset(v))),
              )
              .toList(),
          onChanged: m.actionable ? m.selectOffset : null,
        ),
    ],
    button(
      'resolve',
      t('resolve'),
      m.canResolve ? m.resolve : null,
      primary: true,
    ),
  ]);
  Widget reviewCard(OnboardingController m) {
    final d = m.draft, b = d?.birth, e = d?.evidence;
    return card(t('review'), [
      if (b != null) ...[
        Text('${t('birthDate')}: ${b.date}'),
        Text('${t('birthTime')}: ${b.time ?? t('unknownValue')}'),
        Text('${t('place')}: ${b.place ?? t('unknownValue')}'),
        Text('${t('revision')}: ${d!.revision}'),
      ],
      if (e != null) ...[
        Text('Timezone: ${e.timezone}'),
        Text(
          '${t('offset')}: ${e.offset == null ? t('unknownValue') : formatOffset(e.offset!)}',
        ),
        Text('UTC (private): ${e.utc ?? t('unknownValue')}'),
        Text('Evidence: ${e.status} · ${e.reason ?? t('unknownValue')}'),
        Text(t('benchmark')),
        announce(t(e.confirmedAt == null ? 'notConfirmed' : 'confirmed')),
        CheckboxListTile(
          key: const ValueKey('review'),
          contentPadding: EdgeInsets.zero,
          title: Text(t('reviewAccept')),
          value: m.review,
          onChanged: m.actionable ? (v) => m.setReview(v == true) : null,
        ),
        button(
          'confirm',
          t('confirm'),
          m.canConfirm ? m.confirm : null,
          primary: true,
        ),
      ] else
        Text(t('noEvidence')),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final m = model!;
    _sync(date, m.date);
    _sync(time, m.time);
    _sync(query, m.query);
    _sync(country, m.country);
    return ProtectedSession(
      child: ValueListenableBuilder<String>(
        valueListenable: AuthCopy.language,
        builder: (context, language, _) => Scaffold(
          backgroundColor: const Color(0xFFF4EFFF),
          appBar: AppBar(
            title: Text(t('title')),
            actions: [
              PopupMenuButton<String>(
                tooltip: t('language'),
                initialValue: language,
                onSelected: (v) => AuthCopy.language.value = v,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'en', child: Text('English')),
                  PopupMenuItem(value: 'bn', child: Text('বাংলা')),
                  PopupMenuItem(value: 'hi', child: Text('हिन्दी')),
                ],
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: EdgeInsets.all(
                      constraints.maxWidth < 600 ? 16 : 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF23133E), Color(0xFF67438D)],
                            ),
                          ),
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t('private')),
                                Text(
                                  t('intro'),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(t('rollout')),
                                Wrap(
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          navigate(const HomeScreen()),
                                      child: Text(
                                        t('feed'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          navigate(const AccountScreen()),
                                      child: Text(
                                        t('account'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      key: const ValueKey('rights'),
                                      onPressed: () =>
                                          navigate(const PrivacyScreen()),
                                      child: Text(
                                        t('rights'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (m.busy) ...[
                          const LinearProgressIndicator(),
                          announce(t('loading')),
                        ],
                        if (m.disabled)
                          card(t('disabled'), [
                            Text(t('disabledHelp')),
                            button(
                              'reload-disabled',
                              t('reload'),
                              !m.busy ? m.load : null,
                            ),
                          ], key: const ValueKey('api-disabled'))
                        else ...[
                          if (m.failure != null)
                            announce(failureLabel(m.failure!)),
                          if (m.message != null) announce(t(m.message!)),
                          if (m.reconcile)
                            card(t('uncertain'), [
                              button(
                                'reconcile',
                                t('reload'),
                                !m.busy ? m.load : null,
                              ),
                            ]),
                          if (m.pending != null && !m.reconcile)
                            button(
                              'retry-consent',
                              t('retryConsent'),
                              m.canRetryConsent ? m.retryConsent : null,
                            ),
                          if (m.eligibility != null)
                            card(t('status'), [
                              Text(
                                t(switch (m.eligibility!.state) {
                                  'CONSENT_REQUIRED' => 'consentRequired',
                                  'DETAILS_REQUIRED' => 'detailsRequired',
                                  'LOCATION_UNRESOLVED' => 'locationUnresolved',
                                  'REVIEW_REQUIRED' => 'reviewRequired',
                                  'CONSENT_WITHDRAWN' => 'withdrawn',
                                  _ => 'ready',
                                }),
                              ),
                              Text(
                                t(
                                  m.eligibility!.satisfied
                                      ? 'satisfied'
                                      : 'notReady',
                                ),
                              ),
                              if (m.eligibility!.allowed &&
                                  !m.eligibility!.satisfied)
                                Text(t('socialAllowed')),
                              Text(
                                '${m.eligibility!.mode} · ${t('revision')} ${m.eligibility!.revision}',
                              ),
                              for (final code in m.eligibility!.missing)
                                Text(requirement(code)),
                            ]),
                          Semantics(
                            label: t('status'),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                for (final pair in [
                                  (1, 'consent'),
                                  (2, 'details'),
                                  (3, 'place'),
                                  (4, 'review'),
                                ])
                                  Container(
                                    key: ValueKey('stage-${pair.$2}'),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: activeStage(m) == pair.$2
                                          ? const Color(0xFFE4D5F5)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${pair.$1} · ${t(pair.$2)}',
                                      style: TextStyle(
                                        fontWeight: activeStage(m) == pair.$2
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (constraints.maxWidth >= 900)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: consentCard(
                                    ConsentPurpose.generalTerms,
                                    m,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: consentCard(
                                    ConsentPurpose.astrology,
                                    m,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            consentCard(ConsentPurpose.generalTerms, m),
                            consentCard(ConsentPurpose.astrology, m),
                          ],
                          Text(t('noticeWarning')),
                          if (!m.granted)
                            card(t('consent'), [Text(t('noConsent'))])
                          else ...[
                            birthCard(m),
                            placeCard(m),
                            reviewCard(m),
                          ],
                          button(
                            'reload',
                            t('reload'),
                            !m.busy ? m.load : null,
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(t('memory')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String activeStage(OnboardingController m) =>
      switch (m.eligibility?.nextAction) {
        'PROVIDE_BIRTH_DETAILS' => 'details',
        'SELECT_BIRTHPLACE' => 'place',
        'REVIEW_ONBOARDING' || 'SOCIAL_ACCESS' => 'review',
        _ => 'consent',
      };
  String requirement(String code) => t(switch (code) {
    'ASTROLOGY_CONSENT' => 'consentRequired',
    'BIRTH_DATE' => 'birthDate',
    'EXACT_BIRTH_TIME' => 'birthTime',
    'ADULT_ELIGIBILITY' => 'adultHelp',
    'LOCATION_EVIDENCE' => 'place',
    'HISTORICAL_TIME_REVIEW' => 'historical',
    'DST_FOLD_SELECTION' => 'fold',
    'SOURCE_APPROVAL' => 'pending',
    'NOTICE_APPROVAL' => 'noticeWarning',
    'REVIEW_CONFIRMATION' => 'review',
    _ => 'reviewRequired',
  });
}
