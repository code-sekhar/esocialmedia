import 'package:flutter/material.dart';

// =============================================================
// MODEL
// =============================================================

class FriendSuggestion {
  final String name;
  final String? image;
  final String zodiac;
  final int compatibility;

  const FriendSuggestion({
    required this.name,
    this.image,
    required this.zodiac,
    this.compatibility = 98,
  });
}

// =============================================================
// CARD
// =============================================================

class FriendSuggestionCard extends StatelessWidget {
  final FriendSuggestion friend;

  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const FriendSuggestionCard({
    super.key,
    required this.friend,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
          width: 1,
        ),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // =====================================================
          // PROFILE IMAGE
          // =====================================================

          AspectRatio(
            aspectRatio: 1.12,

            child: Stack(
              fit: StackFit.expand,
              children: [

                // =================================================
                // PROFILE IMAGE
                // =================================================

                friend.image != null &&
                    friend.image!.trim().isNotEmpty
                    ? Image.network(
                  friend.image!,
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

                // =================================================
                // COMPATIBILITY BADGE
                // =================================================

                Positioned(
                  top: 12,
                  right: 12,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFF414141),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        const Icon(
                          Icons.star_border,
                          color: Colors.white,
                          size: 18,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          '${friend.compatibility}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // =====================================================
          // CONTENT
          // =====================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              14,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // =================================================
                // NAME
                // =================================================

                Text(
                  friend.name,

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Color(0xFF171B27),
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 12),

                // =================================================
                // ZODIAC
                // =================================================

                Row(
                  children: [

                    // Zodiac circle
                    Container(
                      width: 28,
                      height: 28,

                      alignment: Alignment.center,

                      decoration: const BoxDecoration(
                        color: Color(0xFFE9D5FF),
                        shape: BoxShape.circle,
                      ),

                      child: Text(
                        _zodiacSymbol(friend.zodiac),
                        style: const TextStyle(
                          color: Color(0xFF7E22CE),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        friend.zodiac,

                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: Color(0xFF9BA1B2),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // =================================================
                // BUTTONS
                // =================================================

                Row(
                  children: [

                    // =================================================
                    // ADD FRIEND
                    // =================================================

                    Expanded(
                      child: GestureDetector(
                        onTap: onAdd,
                        behavior: HitTestBehavior.opaque,

                        child: Container(
                          height: 44,

                          alignment: Alignment.center,

                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius:
                            BorderRadius.circular(8),
                          ),

                          child: const Text(
                            'Add Friend',

                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,

                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // =================================================
                    // REMOVE
                    // =================================================

                    Expanded(
                      child: GestureDetector(
                        onTap: onRemove,
                        behavior: HitTestBehavior.opaque,

                        child: Container(
                          height: 44,

                          alignment: Alignment.center,

                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius:
                            BorderRadius.circular(8),
                          ),

                          child: const Text(
                            'Remove',

                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,

                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // EMPTY IMAGE
  // ===========================================================

  Widget _emptyImage() {
    return Container(
      color: const Color(0xFFE0E0E0),

      alignment: Alignment.center,

      child: const Icon(
        Icons.person_outline,
        color: Color(0xFF9E9E9E),
        size: 55,
      ),
    );
  }

  // ===========================================================
  // ZODIAC SYMBOL
  // ===========================================================

  String _zodiacSymbol(String zodiac) {
    final value = zodiac.toLowerCase();

    if (value.contains('aries')) {
      return '♈';
    }

    if (value.contains('taurus')) {
      return '♉';
    }

    if (value.contains('gemini')) {
      return '♊';
    }

    if (value.contains('cancer')) {
      return '♋';
    }

    if (value.contains('leo')) {
      return '♌';
    }

    if (value.contains('virgo')) {
      return '♍';
    }

    if (value.contains('libra')) {
      return '♎';
    }

    if (value.contains('scorpio')) {
      return '♏';
    }

    if (value.contains('sagittarius')) {
      return '♐';
    }

    if (value.contains('capricorn')) {
      return '♑';
    }

    if (value.contains('aquarius')) {
      return '♒';
    }

    if (value.contains('pisces')) {
      return '♓';
    }

    return '♈';
  }
}