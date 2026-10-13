import 'package:flutter/material.dart';

class CelestialCompatibilityCard extends StatelessWidget {
  final String name;
  final String username;
  final String? imagePath;
  final VoidCallback? onFollow;
  final bool isFollowing;

  const CelestialCompatibilityCard({
    super.key,
    required this.name,
    required this.username,
    this.imagePath,
    this.onFollow,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.40),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // =====================================================
          // PROFILE IMAGE
          // =====================================================

          _profileImage(),

          const SizedBox(width: 12),

          // =====================================================
          // USER INFO
          // =====================================================

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '$username •',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // =====================================================
          // FOLLOW BUTTON
          // =====================================================

          SizedBox(
            width: 85,
            height: 34,
            child: ElevatedButton(
              onPressed: onFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // PROFILE IMAGE
  // ===========================================================

  Widget _profileImage() {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: ClipOval(
        child: imagePath != null && imagePath!.isNotEmpty
            ? Image.asset(
          imagePath!,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (
              context,
              error,
              stackTrace,
              ) {
            return _emptyImage();
          },
        )
            : _emptyImage(),
      ),
    );
  }

  Widget _emptyImage() {
    return const Center(
      child: Icon(
        Icons.person_outline,
        color: Color(0xFFB0B0B0),
        size: 28,
      ),
    );
  }
}