import 'package:flutter/material.dart';

class CreatePostBar extends StatelessWidget {
  final String? profileImage;
  final VoidCallback? onPost;

  const CreatePostBar({
    super.key,
    this.profileImage,
    this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        21,
        5,
        21,
        7,
      ),
      child: Container(
        height: 52,

        padding: const EdgeInsets.symmetric(
          horizontal: 9,
        ),

        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),

          borderRadius: BorderRadius.circular(27),

          border: Border.all(
            color: const Color(0xFFE3E3E3),
            width: 0.8,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          children: [

            // =====================================================
            // PROFILE IMAGE
            // =====================================================

            Container(
              width: 38,
              height: 38,

              padding: const EdgeInsets.all(2),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: const Color(0xFFD7D4CE),

                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),

              child: ClipOval(
                child: profileImage != null &&
                    profileImage!.isNotEmpty
                    ? Image.network(
                  profileImage!,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,

                  errorBuilder:
                      (
                      context,
                      error,
                      stackTrace,
                      ) {
                    return _placeholder();
                  },
                )
                    : _placeholder(),
              ),
            ),

            const SizedBox(width: 12),

            // =====================================================
            // INPUT TEXT
            // =====================================================

            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "What's aligning today?",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // =====================================================
            // POST BUTTON
            // =====================================================

            GestureDetector(
              onTap: onPost,
              behavior: HitTestBehavior.opaque,

              child: Container(
                width: 72,
                height: 34,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: const Color(0xFFB83D72),

                  borderRadius:
                  BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB83D72)
                          .withValues(alpha: 0.18),

                      blurRadius: 5,

                      offset: const Offset(0, 2),
                    ),
                  ],
                ),

                child: const Text(
                  'Post',

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // PROFILE PLACEHOLDER
  // ===========================================================

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFD8D8D8),

      child: const Icon(
        Icons.person,
        size: 20,
        color: Color(0xFF8A8A8A),
      ),
    );
  }
}