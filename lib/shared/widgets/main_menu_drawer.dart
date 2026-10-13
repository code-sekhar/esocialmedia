import 'package:flutter/material.dart';

class MainMenuDrawer extends StatelessWidget {
  final VoidCallback? onProfile;
  final VoidCallback? onAccount;
  final VoidCallback? onNotifications;
  final VoidCallback? onSecurity;
  final VoidCallback? onLogout;

  const MainMenuDrawer({
    super.key,
    this.onProfile,
    this.onAccount,
    this.onNotifications,
    this.onSecurity,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.92,

      elevation: 0,

      backgroundColor: Colors.transparent,

      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFDFC2),
              Color(0xFFFFF5EA),
            ],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              21,
              18,
              21,
              22,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // =====================================================
                // HEADER
                // =====================================================

                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },

                  child: Row(
                    children: [

                      const Icon(
                        Icons.arrow_back,
                        size: 23,
                        color: Colors.black,
                      ),

                      const SizedBox(width: 13),

                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 39),

                // =====================================================
                // PROFILE AVATAR
                // =====================================================

                Center(
                  child: GestureDetector(
                    onTap: onProfile,

                    child: Container(
                      width: 118,
                      height: 118,

                      padding: const EdgeInsets.all(5),

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        border: Border.all(
                          color: const Color(0xFFC75BFF),
                          width: 2,
                        ),
                      ),

                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF9210D9),
                        ),

                        alignment: Alignment.center,

                        child: const Text(
                          'SG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 39,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 13),

                // =====================================================
                // NAME
                // =====================================================

                const Center(
                  child: Text(
                    'Salena Gomes',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =====================================================
                // EDIT PROFILE
                // =====================================================

                Center(
                  child: GestureDetector(
                    onTap: onProfile,

                    child: Container(
                      width: 121,
                      height: 39,

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: const Color(0xFF929292),
                        borderRadius: BorderRadius.circular(22),
                      ),

                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 47),

                // =====================================================
                // STATS
                // =====================================================

                Row(
                  children: [

                    Expanded(
                      child: _statCard(
                        value: '101',
                        label: 'Posts',
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _statCard(
                        value: '101',
                        label: 'Following',
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _statCard(
                        value: '101',
                        label: 'Pages',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 49),

                // =====================================================
                // POPULAR PAGES
                // =====================================================

                const Text(
                  'Popular Pages',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 17),

                Row(
                  children: [

                    Expanded(
                      child: _popularPage(
                        title: 'Daily Rashi',
                        members: '11k members',
                        background:
                        const Color(0xFFFFD8BD),
                      ),
                    ),

                    const SizedBox(width: 18),

                    Expanded(
                      child: _popularPage(
                        title: 'Universal truth',
                        members: '11k members',
                        background:
                        const Color(0xFFD7F0DF),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 29),

                // =====================================================
                // SETTINGS
                // =====================================================

                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Column(
                    children: [

                      _settingItem(
                        icon: Icons.person_outline,
                        iconBackground:
                        const Color(0xFFD8F0E1),
                        title: 'Account',
                        subtitle:
                        'Details, preferences',
                        onTap: onAccount,
                      ),

                      _divider(),

                      _settingItem(
                        icon: Icons.notifications_none,
                        iconBackground:
                        const Color(0xFFFFDCCB),
                        title: 'Notifications',
                        subtitle:
                        'Push, email, alerts',
                        onTap: onNotifications,
                      ),

                      _divider(),

                      _settingItem(
                        icon: Icons.shield_outlined,
                        iconBackground:
                        const Color(0xFFE0FFBD),
                        title: 'Security',
                        subtitle:
                        'Password, 2FA',
                        onTap: onSecurity,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // =====================================================
                // LOGOUT
                // =====================================================

                GestureDetector(
                  onTap: onLogout,

                  child: Container(
                    width: double.infinity,
                    height: 48,

                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDCCB),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),

                    child: const Text(
                      'Log out',
                      style: TextStyle(
                        color: Color(0xFFD0526A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // STAT CARD
  // ===============================================================

  Widget _statCard({
    required String value,
    required String label,
  }) {
    return Container(
      height: 67,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // POPULAR PAGE
  // ===============================================================

  Widget _popularPage({
    required String title,
    required String members,
    required Color background,
  }) {
    return Container(
      height: 156,

      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        12,
        12,
      ),

      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Container(
            width: 34,
            height: 34,

            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),

            child: const Icon(
              Icons.auto_awesome,
              size: 17,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            members,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 10,
            ),
          ),

          const Spacer(),

          Container(
            width: 65,
            height: 30,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(18),
            ),

            child: const Text(
              'Join',
              style: TextStyle(
                color: Color(0xFF444444),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SETTING ITEM
  // ===============================================================

  Widget _settingItem({
    required IconData icon,
    required Color iconBackground,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,

      child: SizedBox(
        height: 68,

        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),

          child: Row(
            children: [

              Container(
                width: 40,
                height: 40,

                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius:
                  BorderRadius.circular(8),
                ),

                child: Icon(
                  icon,
                  color: Colors.black,
                  size: 21,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF5D5D5D),
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF9B9B9B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                size: 21,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // DIVIDER
  // ===============================================================

  Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 0.6,
      color: Color(0xFFE1E1E1),
      indent: 0,
      endIndent: 0,
    );
  }
}