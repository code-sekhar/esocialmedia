import 'package:flutter/material.dart';

import 'comments_screen.dart';



class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final bool isReply;

  const CommentItem({
    super.key,
    required this.comment,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        left: isReply ? 35 : 0,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: isReply ? 28 : 32,
                height: isReply ? 28 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.shade100,
                ),
                child: const Icon(
                  Icons.person,
                  size: 17,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),

                        const SizedBox(width: 5),

                        Text(
                          comment.time,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      comment.text,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.35,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 11,
                          color: Colors.orange,
                        ),

                        const SizedBox(width: 3),

                        Text(
                          '${comment.likes}',
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Text(
                          '♡ Like',
                          style: TextStyle(
                            fontSize: 8,
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (comment.replies.isNotEmpty)
            ...comment.replies.map(
                  (reply) => CommentItem(
                comment: reply,
                isReply: true,
              ),
            ),
        ],
      ),
    );
  }
}