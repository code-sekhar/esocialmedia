import 'package:flutter/material.dart';

class SocialAppBar extends StatelessWidget {
  final String title;

  final String? profileImage;

  final VoidCallback? onProfile;
  final VoidCallback? onMenu;
  final VoidCallback? onSearch;
  final VoidCallback? onMessage;
  final VoidCallback? onNotification;

  const SocialAppBar({
    super.key,
    this.title = 'CosmicMatch',

    this.profileImage,

    this.onProfile,
    this.onMenu,
    this.onSearch,
    this.onMessage,
    this.onNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,

      padding: const EdgeInsets.symmetric(
        horizontal: 22,
      ),

      color: Colors.white,

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // =====================================================
          // PROFILE IMAGE
          // =====================================================

          GestureDetector(
            onTap: onProfile,

            behavior: HitTestBehavior.opaque,

            child: Container(
              width: 38,
              height: 38,

              padding: const EdgeInsets.all(1.5),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),

              child: ClipOval(
                child: profileImage != null &&
                    profileImage!.trim().isNotEmpty
                    ? Image.network(
                  profileImage!,

                  width: 35,
                  height: 35,

                  fit: BoxFit.cover,

                  errorBuilder: (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return _profilePlaceholder();
                  },
                )
                    : _profilePlaceholder(),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // =====================================================
          // GRID / MENU ICON
          // =====================================================

          GestureDetector(
            onTap: onMenu,

            behavior: HitTestBehavior.opaque,

            child: const SizedBox(
              width: 30,
              height: 40,

              child: Center(
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          const SizedBox(width: 9),

          // =====================================================
          // TITLE
          // =====================================================

          Text(
            title,

            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),

          const Spacer(),

          // =====================================================
          // SEARCH
          // =====================================================

          GestureDetector(
            onTap: onSearch,

            behavior: HitTestBehavior.opaque,

            child: const SizedBox(
              width: 30,
              height: 40,

              child: Center(
                child: Icon(
                  Icons.search,
                  size: 25,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // =====================================================
          // MESSAGE
          // =====================================================

          GestureDetector(
            onTap: onMessage,

            behavior: HitTestBehavior.opaque,

            child: const SizedBox(
              width: 30,
              height: 40,

              child: Center(
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 22,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // =====================================================
          // NOTIFICATION
          // =====================================================

          GestureDetector(
            onTap: onNotification,

            behavior: HitTestBehavior.opaque,

            child: const SizedBox(
              width: 30,
              height: 40,

              child: Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 24,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // PROFILE PLACEHOLDER
  // =============================================================

  Widget _profilePlaceholder() {
    return Container(
      color: const Color(0xFFE0E0E0),

      alignment: Alignment.center,

      child: const Icon(
        Icons.person,
        color: Color(0xFF888888),
        size: 22,
      ),
    );
  }
}