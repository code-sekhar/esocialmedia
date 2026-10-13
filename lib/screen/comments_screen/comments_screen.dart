import 'package:flutter/material.dart';

import 'comment_item.dart';

class CommentModel {
  final String name;
  final String time;
  final String text;
  final String? image;
  final int likes;
  final List<CommentModel> replies;

  const CommentModel({
    required this.name,
    required this.time,
    required this.text,
    this.image,
    this.likes = 0,
    this.replies = const [],
  });
}

class CommentsBottomSheet extends StatefulWidget {
  const CommentsBottomSheet({
    super.key,
  });

  @override
  State<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState
    extends State<CommentsBottomSheet> {
  final TextEditingController commentController =
  TextEditingController();

  final comments = const [
    CommentModel(
      name: 'Om Patil',
      time: '2h',
      text:
      "I'd like to request a native GIF export feature. "
          "It would be great to have this built-in so we can "
          "export directly without relying on external tools.",
      likes: 112,
      replies: [
        CommentModel(
          name: 'Kiran Patel',
          time: '2h',
          text:
          "I'd like to request a native GIF export "
              "feature. It would be great to have this "
              "built-in so we can export directly.",
          likes: 112,
        ),
        CommentModel(
          name: 'Rakesh Patil',
          time: '2h',
          text:
          "I'd like to request a native GIF export "
              "feature. It would be great to have this "
              "built-in.",
          likes: 82,
        ),
      ],
    ),

    CommentModel(
      name: 'Om Patil',
      time: '2h',
      text:
      "I'd like to request a native GIF export "
          "feature. It would be great to have this "
          "built-in.",
      likes: 112,
    ),

    CommentModel(
      name: 'Om Patil',
      time: '2h',
      text:
      "I'd like to request a native GIF export "
          "feature.",
      likes: 80,
    ),
  ];

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
      MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Handle
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius:
              BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            child: Row(
              children: [
                const Text(
                  'Comments (120)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                const Text(
                  'Most relevant',
                  style: TextStyle(
                    fontSize: 10,
                  ),
                ),

                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 15,
                ),
              ],
            ),
          ),

          const Divider(),

          // Comments
          Expanded(
            child: ListView.builder(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return CommentItem(
                  comment: comments[index],
                );
              },
            ),
          ),

          // Input
          _commentInput(),
        ],
      ),
    );
  }

  Widget _commentInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.grey,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Write a comment',
                  hintStyle: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor:
                  Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.send_outlined,
              size: 19,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}