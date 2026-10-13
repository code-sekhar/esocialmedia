import 'package:flutter/material.dart';

// =============================================================
// REACTION TYPE
// =============================================================

enum PostReaction { like, love, haha, sad, angry, dislike }

// =============================================================
// REACTION DATA
// =============================================================

class ReactionInfo {
  final PostReaction type;
  final String emoji;
  final String label;
  final Color color;

  const ReactionInfo({
    required this.type,
    required this.emoji,
    required this.label,
    required this.color,
  });
}

// =============================================================
// REACTION CONFIG
// =============================================================

const List<ReactionInfo> reactionTypes = [
  ReactionInfo(
    type: PostReaction.like,
    emoji: '👍',
    label: 'Like',
    color: Color(0xFF1677FF),
  ),

  ReactionInfo(
    type: PostReaction.love,
    emoji: '❤️',
    label: 'Love',
    color: Color(0xFFFF3040),
  ),

  ReactionInfo(
    type: PostReaction.haha,
    emoji: '😂',
    label: 'Haha',
    color: Color(0xFFFFC107),
  ),

  ReactionInfo(
    type: PostReaction.sad,
    emoji: '😢',
    label: 'Sad',
    color: Color(0xFFFFC107),
  ),

  ReactionInfo(
    type: PostReaction.angry,
    emoji: '😡',
    label: 'Angry',
    color: Color(0xFFFF5722),
  ),

  ReactionInfo(
    type: PostReaction.dislike,
    emoji: '👎',
    label: 'Dislike',
    color: Color(0xFF607D8B),
  ),
];

// =============================================================
// MODEL
// =============================================================

class PostModel {
  final String userName;
  final String? avatar;
  final String time;
  final String content;
  final String? image;
  final String? zodiac;

  final int likes;
  final int comments;

  final bool following;

  // Current user's reaction
  final PostReaction? myReaction;

  const PostModel({
    required this.userName,
    this.avatar,
    required this.time,
    required this.content,
    this.image,
    this.zodiac,
    this.likes = 0,
    this.comments = 0,
    this.following = false,
    this.myReaction,
  });
}

// =============================================================
// POST CARD
// =============================================================

class PostCard extends StatefulWidget {
  final PostModel post;
  final bool live;

  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onFollow;

  // ===========================================================
  // API READY CALLBACK
  // ===========================================================

  final void Function(PostReaction? reaction)? onReactionChanged;

  const PostCard({
    super.key,
    required this.post,
    this.live = false,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onFollow,
    this.onReactionChanged,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

// =============================================================
// STATE
// =============================================================

class _PostCardState extends State<PostCard> {
  // ===========================================================
  // CURRENT REACTION
  // ===========================================================

  PostReaction? _myReaction;

  // ===========================================================
  // REACTION COUNTS
  // ===========================================================

  late int _likes;

  // ===========================================================
  // INIT
  // ===========================================================

  @override
  void initState() {
    super.initState();

    _myReaction = widget.post.myReaction;

    _likes = widget.post.likes;
  }

  // ===========================================================
  // REACTION INFO
  // ===========================================================

  ReactionInfo? get _currentReaction {
    if (_myReaction == null) {
      return null;
    }

    for (final reaction in reactionTypes) {
      if (reaction.type == _myReaction) {
        return reaction;
      }
    }

    return null;
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(left: 15, right: 15, bottom: 10),

      padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(13),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // HEADER
          // =====================================================
          _header(),

          const SizedBox(height: 13),

          // =====================================================
          // CONTENT
          // =====================================================
          Text(
            widget.post.content,

            maxLines: widget.live ? null : 4,

            overflow: widget.live
                ? TextOverflow.visible
                : TextOverflow.ellipsis,

            style: const TextStyle(
              color: Color(0xFF202020),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.42,
            ),
          ),

          // =====================================================
          // HASHTAGS
          // =====================================================
          if (widget.post.zodiac != null &&
              widget.post.zodiac!.trim().isNotEmpty) ...[
            const SizedBox(height: 9),

            Text(
              widget.post.zodiac!,

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                color: Color(0xFF006CC9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ],

          // =====================================================
          // IMAGE
          // =====================================================
          if (widget.post.image != null &&
              widget.post.image!.trim().isNotEmpty) ...[
            const SizedBox(height: 13),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),

              child: AspectRatio(
                aspectRatio: 1.55,

                child: Image.network(
                  widget.post.image!,

                  width: double.infinity,

                  fit: BoxFit.cover,

                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFEDEDED),

                      alignment: Alignment.center,

                      child: const Icon(
                        Icons.image_outlined,
                        color: Colors.grey,
                        size: 28,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // =====================================================
          // TRANSLATE
          // =====================================================
          if (!widget.live) ...[
            const Row(
              children: [
                Text(
                  'Translate',
                  style: TextStyle(color: Color(0xFF777777), fontSize: 9),
                ),

                SizedBox(width: 5),

                Icon(Icons.translate, size: 12, color: Color(0xFF777777)),
              ],
            ),

            const SizedBox(height: 12),

            // =====================================================
            // ACTION BAR
            // =====================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // =================================================
                // REACTION PILL
                // =================================================
                GestureDetector(
                  onTap: _toggleLike,

                  onLongPress: () {
                    _showReactionPicker(context);
                  },

                  child: _reactionPill(),
                ),

                const SizedBox(width: 13),

                // =================================================
                // LIKE / CURRENT REACTION
                // =================================================
                GestureDetector(
                  onTap: _toggleLike,

                  onLongPress: () {
                    _showReactionPicker(context);
                  },

                  child: _reactionButton(),
                ),

                const Spacer(),

                // =================================================
                // COMMENTS
                // =================================================
                GestureDetector(
                  onTap: widget.onComment,

                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: Color(0xFF333333),
                      ),

                      const SizedBox(width: 4),

                      Text(
                        '${widget.post.comments} Comments',

                        style: const TextStyle(
                          color: Color(0xFF444444),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // =============================================================
  // TOGGLE LIKE
  // =============================================================

  void _toggleLike() {
    if (_myReaction == PostReaction.like) {
      // ---------------------------------------------
      // REMOVE LIKE
      // ---------------------------------------------

      setState(() {
        _myReaction = null;

        if (_likes > 0) {
          _likes--;
        }
      });

      _sendReactionToApi(null);

      return;
    }

    // ---------------------------------------------
    // NEW LIKE
    // ---------------------------------------------

    setState(() {
      _myReaction = PostReaction.like;

      _likes++;
    });

    _sendReactionToApi(PostReaction.like);
  }

  // =============================================================
  // SELECT REACTION
  // =============================================================

  void _selectReaction(PostReaction reaction) {
    Navigator.pop(context);

    // Same reaction pressed
    if (_myReaction == reaction) {
      setState(() {
        if (reaction == PostReaction.like && _likes > 0) {
          _likes--;
        }

        _myReaction = null;
      });

      _sendReactionToApi(null);

      return;
    }

    final oldReaction = _myReaction;

    setState(() {
      // If old reaction was like,
      // remove it from like count.
      if (oldReaction == PostReaction.like && _likes > 0) {
        _likes--;
      }

      // If new reaction is like,
      // increase like count.
      if (reaction == PostReaction.like) {
        _likes++;
      }

      _myReaction = reaction;
    });

    _sendReactionToApi(reaction);
  }

  // =============================================================
  // REACTION PICKER
  // =============================================================

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.only(left: 15, right: 15, bottom: 15),

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(25),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),

                  blurRadius: 15,

                  offset: const Offset(0, 5),
                ),
              ],
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,

              children: reactionTypes.map((reaction) {
                final bool selected = _myReaction == reaction.type;

                return GestureDetector(
                  onTap: () {
                    _selectReaction(reaction.type);
                  },

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),

                    width: selected ? 52 : 44,

                    height: selected ? 52 : 44,

                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFF1F1F1)
                          : Colors.transparent,

                      shape: BoxShape.circle,

                      border: selected
                          ? Border.all(color: reaction.color, width: 2)
                          : null,
                    ),

                    child: Text(
                      reaction.emoji,

                      style: TextStyle(fontSize: selected ? 29 : 25),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // REACTION PILL
  // =============================================================

  Widget _reactionPill() {
    final reaction = _currentReaction;

    return Container(
      height: 22,

      padding: const EdgeInsets.symmetric(horizontal: 6),

      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ===================================================
          // REACTION ICON
          // ===================================================
          if (reaction != null)
            Container(
              width: 15,
              height: 15,

              alignment: Alignment.center,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: reaction.color,
              ),

              child: Text(reaction.emoji, style: const TextStyle(fontSize: 9)),
            )
          else
            Container(
              width: 15,
              height: 15,

              decoration: const BoxDecoration(
                shape: BoxShape.circle,

                color: Color(0xFF1677FF),
              ),

              child: const Icon(Icons.thumb_up, color: Colors.white, size: 9),
            ),

          const SizedBox(width: 3),

          // ===================================================
          // HEART
          // ===================================================
          if (reaction == null)
            Transform.translate(
              offset: const Offset(-3, 0),

              child: Container(
                width: 15,
                height: 15,

                decoration: const BoxDecoration(
                  shape: BoxShape.circle,

                  color: Color(0xFFFF7A00),
                ),

                child: const Icon(Icons.favorite, color: Colors.white, size: 8),
              ),
            ),

          const SizedBox(width: 1),

          Text(
            '$_likes',

            style: const TextStyle(color: Color(0xFF666666), fontSize: 8),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // REACTION BUTTON
  // =============================================================

  Widget _reactionButton() {
    final reaction = _currentReaction;

    if (reaction == null) {
      return const Row(
        children: [
          Icon(Icons.thumb_up_alt_outlined, size: 13, color: Color(0xFF444444)),

          SizedBox(width: 5),

          Text('Like', style: TextStyle(color: Color(0xFF444444), fontSize: 9)),
        ],
      );
    }

    return Row(
      children: [
        Text(reaction.emoji, style: const TextStyle(fontSize: 14)),

        const SizedBox(width: 5),

        Text(
          reaction.label,

          style: TextStyle(
            color: reaction.color,

            fontSize: 9,

            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =============================================================
  // API CALLBACK
  // =============================================================

  void _sendReactionToApi(PostReaction? reaction) {
    // ===========================================================
    // এখানেই পরে API call বসাবে
    // ===========================================================
    //
    // Example:
    //
    // final reactionValue =
    //     reaction?.name;
    //
    // await postService.reactToPost(
    //   postId: widget.post.id,
    //   reaction: reactionValue,
    // );
    //
    // ===========================================================

    widget.onReactionChanged?.call(reaction);

    debugPrint('Reaction changed: ${reaction?.name}');
  }

  // =============================================================
  // HEADER
  // =============================================================

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        // =========================================================
        // AVATAR
        // =========================================================
        Container(
          width: 42,
          height: 42,

          padding: const EdgeInsets.all(2),

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            border: Border.all(color: const Color(0xFFFFC76A), width: 1.3),
          ),

          child: ClipOval(
            child:
                widget.post.avatar != null &&
                    widget.post.avatar!.trim().isNotEmpty
                ? Image.network(
                    widget.post.avatar!,

                    width: 38,
                    height: 38,

                    fit: BoxFit.cover,

                    errorBuilder: (context, error, stackTrace) {
                      return _avatarPlaceholder();
                    },
                  )
                : _avatarPlaceholder(),
          ),
        ),

        const SizedBox(width: 11),

        // =========================================================
        // USER INFORMATION
        // =========================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                widget.post.userName,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Color(0xFF222222),

                  fontSize: 14,

                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                widget.post.time,

                style: const TextStyle(color: Color(0xFF777777), fontSize: 10),
              ),
            ],
          ),
        ),

        // =========================================================
        // FOLLOW
        // =========================================================
        if (!widget.live && !widget.post.following)
          GestureDetector(
            onTap: widget.onFollow,

            child: Container(
              width: 64,
              height: 30,

              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: const Color(0xFFB0B0B0),

                borderRadius: BorderRadius.circular(17),
              ),

              child: const Text(
                'Follow',

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 10,

                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        const SizedBox(width: 8),

        // =========================================================
        // MORE
        // =========================================================
        const Icon(Icons.more_vert, size: 18, color: Color(0xFF777777)),
      ],
    );
  }

  // =============================================================
  // AVATAR PLACEHOLDER
  // =============================================================

  Widget _avatarPlaceholder() {
    return Container(
      color: const Color(0xFFFFD58C),

      child: const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }
}
