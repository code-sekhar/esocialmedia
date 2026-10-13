import 'dart:typed_data';
import '../../../core/l10n/auth_copy.dart';
import '../../../features/profiles/profile_settings_screen.dart';
import 'package:esocialmedia/core/auth/auth_scope.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String? profileImage;
  final String? coverImage;

  const ProfileScreen({
    super.key,
    this.userName = 'Your profile',
    this.profileImage,
    this.coverImage,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool loaded = false;
  String? loadError;
  Uint8List? savedAvatar;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded && AuthScope.of(context).authenticated) {
      loaded = true;
      _loadOwnProfile();
    }
  }

  Future<void> _loadOwnProfile() async {
    final session = AuthScope.of(context);
    try {
      await session.profile();
      final bytes = await session.avatar();
      if (mounted) setState(() => savedAvatar = bytes);
    } catch (error) {
      if (mounted) setState(() => loadError = AuthCopy.error(error));
    }
  }

  final List<String> tabs = [
    'All',
    'Photos',
    'Charts',
    'Dasha',
    'Moon Reports',
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProtectedSession(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),

        body: SafeArea(
          child: NestedScrollView(
            physics: const BouncingScrollPhysics(),

            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // ==========================================
                // PROFILE HEADER
                // ==========================================
                SliverToBoxAdapter(child: _profileHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        if (loadError != null) Text(loadError!),
                        const Text(
                          'Your name, bio and avatar come from your account. Social/chart sections below retain existing preview layouts; no social counts or KP chart have been calculated.',
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileSettingsScreen(),
                            ),
                          ),
                          child: const Text('Edit your profile & privacy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ProfileSettingsScreen(astrology: true),
                            ),
                          ),
                          child: const Text(
                            'Optional private astrology & consent',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ==========================================
                // STICKY TAB BAR
                // ==========================================
                SliverPersistentHeader(
                  pinned: true,

                  delegate: _ProfileTabBarDelegate(child: _tabBar()),
                ),
              ];
            },

            body: TabBarView(
              controller: _tabController,

              children: [
                _allTab(),
                _photosTab(),
                _chartsTab(),
                _dashaTab(),
                _moonReportsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // TOP HEADER
  // ===========================================================

  // ===========================================================
  // PROFILE HEADER
  // ===========================================================

  Widget _profileHeader() {
    return SizedBox(
      height: 338,

      child: Stack(
        clipBehavior: Clip.none,

        children: [
          // ==========================================
          // COVER IMAGE
          // ==========================================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 145,

            child:
                widget.coverImage != null &&
                    widget.coverImage!.trim().isNotEmpty
                ? Image.network(
                    widget.coverImage!,
                    fit: BoxFit.cover,

                    errorBuilder: (_, _, _) {
                      return _coverPlaceholder();
                    },
                  )
                : _coverPlaceholder(),
          ),

          // ==========================================
          // BACK
          // ==========================================
          Positioned(
            top: 14,
            left: 18,

            child: _coverIcon(
              Icons.arrow_back_ios_new_rounded,

              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),

          // ==========================================
          // SEARCH
          // ==========================================
          Positioned(
            top: 14,
            right: 54,

            child: _coverIcon(Icons.search, onTap: () {}),
          ),

          // ==========================================
          // MORE
          // ==========================================
          Positioned(
            top: 14,
            right: 18,

            child: _coverIcon(Icons.more_horiz, onTap: () {}),
          ),

          // ==========================================
          // WHITE PROFILE CARD
          // ==========================================
          Positioned(
            top: 88,
            left: 6,
            right: 6,
            bottom: 0,

            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),

              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // ==================================
                    // PROFILE IMAGE
                    // ==================================
                    Transform.translate(
                      offset: const Offset(0, -32),

                      child: Container(
                        width: 76,
                        height: 76,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,

                          color: Colors.black,

                          border: Border.all(color: Colors.white, width: 3),
                        ),

                        child: ClipOval(
                          child: savedAvatar != null
                              ? Image.memory(savedAvatar!, fit: BoxFit.cover)
                              : _avatarPlaceholder(),
                        ),
                      ),
                    ),

                    // ==================================
                    // NAME
                    // ==================================
                    Transform.translate(
                      offset: const Offset(0, -25),

                      child: Text(
                        AuthScope.of(context).account?.displayName ??
                            AuthScope.of(context).account?.username ??
                            'Your profile',

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // ==================================
                    // FRIENDS / FOLLOWERS
                    // ==================================
                    Transform.translate(
                      offset: const Offset(0, -21),

                      child: Row(
                        children: [
                          const Text(
                            '—',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const Text(
                            ' friends',
                            style: TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontSize: 10,
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 9),

                            child: Text(
                              '•',
                              style: TextStyle(
                                color: Color(0xFFB5B5B5),
                                fontSize: 9,
                              ),
                            ),
                          ),

                          const Text(
                            '—',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const Text(
                            ' followers',
                            style: TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 2),

                    // ==================================
                    // BIO
                    // ==================================
                    Text(
                      AuthScope.of(context).account?.bio ?? 'No bio added',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: Color(0xFF5D4085),
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ==================================
                    // ZODIAC
                    // ==================================
                    Row(
                      children: [
                        _zodiacChip('☀️ —'),

                        const SizedBox(width: 7),

                        _zodiacChip('🌙 —'),

                        const SizedBox(width: 7),

                        _zodiacChip('⬆️ —'),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ==================================
                    // BUTTONS
                    // ==================================
                    Row(
                      children: [
                        Expanded(
                          child: _profileButton(
                            title: 'Message',
                            icon: Icons.chat_bubble_outline,
                            filled: false,

                            onTap: () {},
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _profileButton(
                            title: 'Match',
                            icon: Icons.auto_awesome,
                            filled: true,

                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // ALL TAB
  // ===========================================================

  Widget _allTab() {
    return ListView(
      padding: const EdgeInsets.all(16),

      children: [
        _sectionTitle('Details', icon: Icons.edit_outlined),

        _detailItem(Icons.work_outline, 'Work: ', 'Not added'),

        _detailItem(Icons.school_outlined, 'Education: ', 'Not added'),

        _detailItem(Icons.home_outlined, 'Location not shared'),

        _detailItem(Icons.location_on_outlined, 'Birthplace remains private'),

        _detailItem(Icons.favorite_border, 'Relationship status not shared'),

        _detailItem(Icons.more_horiz, 'See your About info'),

        const SizedBox(height: 12),

        const Divider(),

        const SizedBox(height: 10),

        Row(
          children: [
            const Text(
              'Friends',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),

            const Spacer(),

            const Text(
              'See all',
              style: TextStyle(color: Color(0xFF8F19E8), fontSize: 10),
            ),
          ],
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 90,

          child: ListView.separated(
            scrollDirection: Axis.horizontal,

            itemCount: 5,

            separatorBuilder: (_, _) => const SizedBox(width: 12),

            itemBuilder: (_, index) {
              return _friendItem();
            },
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 42,

          child: ElevatedButton.icon(
            onPressed: () {},

            icon: const Icon(Icons.chat_bubble_outline, size: 16),

            label: const Text('Manage posts', style: TextStyle(fontSize: 11)),

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD1D2D4),

              foregroundColor: Colors.black,

              elevation: 0,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================
  // PHOTOS TAB
  // ===========================================================

  Widget _photosTab() {
    final photos = [
      'https://images.unsplash.com/photo-1462331940025-496dfbfc7564',
      'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa',
      'https://images.unsplash.com/photo-1511497584788-876760111969',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e',

      'https://images.unsplash.com/photo-1462331940025-496dfbfc7564',
      'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa',
      'https://images.unsplash.com/photo-1511497584788-876760111969',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e',

      'https://images.unsplash.com/photo-1462331940025-496dfbfc7564',
      'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa',
      'https://images.unsplash.com/photo-1511497584788-876760111969',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e',
    ];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),

      itemCount: photos.length,

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,

        crossAxisSpacing: 5,

        mainAxisSpacing: 5,

        childAspectRatio: 1,
      ),

      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),

          child: Image.network(
            photos[index],

            fit: BoxFit.cover,

            errorBuilder: (_, _, _) {
              return Container(
                color: const Color(0xFFE5E5E5),

                child: const Icon(Icons.image_outlined, color: Colors.grey),
              );
            },
          ),
        );
      },
    );
  }

  // ===========================================================
  // CHARTS TAB
  // ===========================================================

  Widget _chartsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),

      children: [
        Container(
          height: 280,

          decoration: BoxDecoration(
            color: const Color(0xFFFBFAFF),
            borderRadius: BorderRadius.circular(10),
          ),

          child: Center(
            child: CustomPaint(
              size: const Size(260, 260),

              painter: _BirthChartPainter(),
            ),
          ),
        ),

        const SizedBox(height: 14),

        _planetCard('Sun', 'Leo • H10 • Magha', 'OWN'),

        _planetCard('Moon', 'Cancer • H9 • Pushya', 'OWN'),

        _planetCard('Mars', 'Capricorn • H3', 'EXALTED'),

        _planetCard('Mercury', 'Virgo • H11 • Hasta', 'EXALTED'),
      ],
    );
  }

  // ===========================================================
  // DASHA TAB
  // ===========================================================

  Widget _dashaTab() {
    return ListView(
      padding: const EdgeInsets.all(16),

      children: [
        Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: const Color(0xFFF5F2FF),
            borderRadius: BorderRadius.circular(8),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFF8F19E8),
                      borderRadius: BorderRadius.circular(18),
                    ),

                    child: const Text(
                      'Jupiter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    '2020-01 — 2036-01',
                    style: TextStyle(color: Color(0xFF8B91A5), fontSize: 10),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              const Text(
                'A period of wisdom, growth, and spiritual '
                'expansion. Blessings in education and family.',

                style: TextStyle(
                  color: Color(0xFF5A4C7D),
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        const Text(
          'MAJOR PERIODS',
          style: TextStyle(
            color: Color(0xFF9297A9),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 10),

        _periodBar('Saturn', '2004–2023', 0.65),

        _periodBar('Jupiter', '2020–2036', 0.45, active: true),

        _periodBar('Sun', '2036–2042', 0.30),

        const SizedBox(height: 22),

        const Text(
          'ANTARDASHAS (SUB-PERIODS)',
          style: TextStyle(
            color: Color(0xFF9297A9),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 10),

        GridView.count(
          crossAxisCount: 2,

          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          crossAxisSpacing: 8,

          mainAxisSpacing: 8,

          childAspectRatio: 2.0,

          children: [
            _antardasha('Jupiter', '2020-01 — 2022-03'),
            _antardasha('Saturn', '2022-03 — 2024-09'),
            _antardasha('Mercury', '2024-09 — 2027-01', active: true),
            _antardasha('Ketu', '2027-01 — 2028-01'),
          ],
        ),
      ],
    );
  }

  // ===========================================================
  // MOON REPORTS TAB
  // ===========================================================

  Widget _moonReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),

      children: [
        _infoCard(
          icon: Icons.person_outline,
          title: 'Personality',
          text:
              'Deeply intuitive and emotionally intelligent. '
              'You process the world through feelings first, '
              'making you an empathetic soul who can sense '
              'the moods of others.',
        ),

        _infoCard(
          icon: Icons.psychology_outlined,
          title: 'Mind & Thinking',
          text:
              'Your mind works in cycles, much like the Moon itself. '
              'Creative bursts are followed by contemplative retreats. '
              'You think in images and metaphors.',
        ),

        _infoCard(
          icon: Icons.work_outline,
          title: 'Career',
          text:
              'Natural fit for counseling, healthcare, hospitality, '
              'and creative arts. Your nurturing instinct makes you '
              'an excellent team leader.',
        ),

        const SizedBox(height: 8),

        _strengthsCard(),
      ],
    );
  }

  // ===========================================================
  // HELPERS
  // ===========================================================

  Widget _coverIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,

      behavior: HitTestBehavior.opaque,

      child: SizedBox(
        width: 32,
        height: 32,

        child: Center(child: Icon(icon, color: Colors.white, size: 21)),
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      height: 48,

      color: Colors.white,

      child: TabBar(
        controller: _tabController,

        isScrollable: true,

        tabAlignment: TabAlignment.start,

        padding: const EdgeInsets.symmetric(horizontal: 16),

        labelPadding: const EdgeInsets.symmetric(horizontal: 10),

        indicatorPadding: const EdgeInsets.symmetric(vertical: 8),

        indicator: BoxDecoration(
          color: const Color(0xFFF5F0FF),

          borderRadius: BorderRadius.circular(18),
        ),

        labelColor: const Color(0xFF8F19E8),

        unselectedLabelColor: const Color(0xFF777777),

        dividerColor: const Color(0xFFE8E8E8),

        indicatorSize: TabBarIndicatorSize.tab,

        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),

        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),

        tabs: tabs.map((tab) {
          return Tab(text: tab, height: 48);
        }).toList(),
      ),
    );
  }

  Widget _profileButton({
    required String title,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 38,

        alignment: Alignment.center,

        decoration: BoxDecoration(
          color: filled ? const Color(0xFF9A12E8) : Colors.white,

          borderRadius: BorderRadius.circular(8),

          border: Border.all(
            color: filled ? Colors.transparent : const Color(0xFFD5D5D5),
          ),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, size: 16, color: filled ? Colors.white : Colors.black),

            const SizedBox(width: 6),

            Text(
              title,

              style: TextStyle(
                color: filled ? Colors.white : Colors.black,

                fontSize: 11,

                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zodiacChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

      decoration: BoxDecoration(
        color: const Color(0xFFF3EDFF),
        borderRadius: BorderRadius.circular(14),
      ),

      child: Text(
        text,

        style: const TextStyle(color: Color(0xFF63428E), fontSize: 10),
      ),
    );
  }

  Widget _sectionTitle(String title, {IconData? icon}) {
    return Row(
      children: [
        Text(
          title,

          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),

        const Spacer(),

        if (icon != null) Icon(icon, size: 18, color: Colors.grey),
      ],
    );
  }

  Widget _detailItem(IconData icon, String text, [String? boldText]) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, size: 17, color: const Color(0xFF727785)),

          const SizedBox(width: 12),

          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF333333), fontSize: 11),

                children: [
                  TextSpan(text: text),

                  if (boldText != null)
                    TextSpan(
                      text: boldText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _friendItem() {
    return SizedBox(
      width: 58,

      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,

            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD6E8E2),
            ),

            child: const Icon(Icons.person, color: Colors.grey, size: 30),
          ),

          const SizedBox(height: 4),

          const Text(
            'Sarah Jenl',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [Color(0xFF152524), Color(0xFF283A38), Color(0xFF111C1B)],
        ),
      ),

      child: const Center(
        child: Icon(Icons.auto_awesome, color: Color(0xFFD6B86A), size: 70),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: Colors.black,

      alignment: Alignment.center,

      child: const Icon(Icons.person, color: Colors.white, size: 35),
    );
  }

  Widget _planetCard(String planet, String detail, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      decoration: BoxDecoration(
        color: const Color(0xFFF5F2FF),
        borderRadius: BorderRadius.circular(7),
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  planet,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  detail,
                  style: const TextStyle(color: Color(0xFF8A8FA1), fontSize: 9),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),

            decoration: BoxDecoration(
              color: const Color(0xFFFFEBCB),
              borderRadius: BorderRadius.circular(3),
            ),

            child: Text(
              status,
              style: const TextStyle(
                color: Color(0xFFD18B16),
                fontSize: 7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodBar(
    String name,
    String date,
    double value, {
    bool active = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),

      child: Row(
        children: [
          SizedBox(
            width: 55,

            child: Text(
              name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),

          Expanded(
            child: Container(
              height: 10,

              decoration: BoxDecoration(
                color: const Color(0xFFF0EDFF),
                borderRadius: BorderRadius.circular(10),
              ),

              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,

                widthFactor: value,

                child: Container(
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF9A12E8)
                        : const Color(0xFFE8E3FF),

                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 60,

            child: Text(
              date,
              style: const TextStyle(color: Color(0xFF9297A9), fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _antardasha(String name, String date, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(7),

        border: Border.all(
          color: active ? const Color(0xFF9A12E8) : const Color(0xFFE5E5E5),
        ),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF9A12E8) : Colors.black,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            date,
            style: TextStyle(
              fontSize: 8,
              color: active ? const Color(0xFF9A12E8) : const Color(0xFF9297A9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: const Color(0xFFF5F2FF),
        borderRadius: BorderRadius.circular(7),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF8F19E8)),

              const SizedBox(width: 6),

              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF8F19E8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF665B7A),
              fontSize: 9,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _strengthsCard() {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            '✣ Strengths',
            style: TextStyle(
              color: Color(0xFF1E9D65),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 5,
            runSpacing: 5,

            children: [
              _strength('Emotional intelligence'),
              _strength('Nurturing nature'),
              _strength('Strong intuition'),
              _strength('Creative imagination'),
              _strength('Loyal & protective'),
            ],
          ),

          const Divider(height: 20),

          const Text(
            '♧ Weaknesses',
            style: TextStyle(
              color: Color(0xFFE15C65),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 5,
            runSpacing: 5,

            children: [
              _weakness('Mood swings'),
              _weakness('Over-sensitivity'),
              _weakness('Tendency to cling'),
              _weakness('Indirect communication'),
              _weakness('Fear of rejection'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _strength(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

      decoration: BoxDecoration(
        color: const Color(0xFFE5F8EF),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF239463), fontSize: 8),
      ),
    );
  }

  Widget _weakness(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

      decoration: BoxDecoration(
        color: const Color(0xFFFFE7E8),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFD75A63), fontSize: 8),
      ),
    );
  }
}

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _ProfileTabBarDelegate({required this.child});

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _ProfileTabBarDelegate oldDelegate) {
    return false;
  }
}
// =============================================================
// BIRTH CHART PAINTER
// =============================================================

class _BirthChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.shortestSide * 0.43;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = const Color(0xFFD5D5D5);

    // Outer circle

    canvas.drawCircle(center, radius, paint);

    // Inner circle

    canvas.drawCircle(center, radius * 0.72, paint);

    // Houses

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * 3.1415926535 / 180;

      final end = Offset(
        center.dx + radius * 0.72 * _cos(angle),

        center.dy + radius * 0.72 * _sin(angle),
      );

      canvas.drawLine(center, end, paint);
    }

    // Center

    final centerPaint = Paint()..color = const Color(0xFFFFC857);

    canvas.drawCircle(center, 9, centerPaint);

    final dotPaint = Paint()..color = const Color(0xFF9A12E8);

    canvas.drawCircle(Offset(center.dx - 35, center.dy + 30), 6, dotPaint);

    canvas.drawCircle(
      Offset(center.dx + 38, center.dy - 15),
      6,
      Paint()..color = const Color(0xFFE06B47),
    );
  }

  double _cos(double angle) {
    return _trigCos(angle);
  }

  double _sin(double angle) {
    return _trigSin(angle);
  }

  double _trigCos(double x) {
    // Small approximation sufficient for decorative chart.
    return _mathCos(x);
  }

  double _trigSin(double x) {
    return _mathSin(x);
  }

  double _mathCos(double x) {
    return _cosSeries(x);
  }

  double _mathSin(double x) {
    return _sinSeries(x);
  }

  double _cosSeries(double x) {
    double result = 1;
    double term = 1;

    for (int i = 1; i <= 8; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));

      result += term;
    }

    return result;
  }

  double _sinSeries(double x) {
    double result = x;
    double term = x;

    for (int i = 1; i <= 8; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));

      result += term;
    }

    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
