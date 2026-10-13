import 'package:flutter/material.dart';

class StoryModel {
  final String name;
  final String? image;
  final bool isLive;
  final bool isOwnStory;

  const StoryModel({
    required this.name,
    this.image,
    this.isLive = false,
    this.isOwnStory = false,
  });
}

// =============================================================
// STORY SECTION
// =============================================================

class StorySection extends StatelessWidget {
  final List<StoryModel> stories;
  final Function(StoryModel)? onStoryTap;

  const StorySection({
    super.key,
    required this.stories,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 108,
      color: Colors.white,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        padding: const EdgeInsets.only(
          left: 21,
          right: 4,
          top: 9,
        ),

        physics: const BouncingScrollPhysics(),

        itemCount: stories.length,

        separatorBuilder: (_, _) {
          return const SizedBox(width: 16);
        },

        itemBuilder: (context, index) {
          final story = stories[index];

          return StoryItem(
            story: story,
            onTap: () {
              onStoryTap?.call(story);
            },
          );
        },
      ),
    );
  }
}

// =============================================================
// STORY ITEM
// =============================================================

class StoryItem extends StatelessWidget {
  final StoryModel story;
  final VoidCallback? onTap;

  const StoryItem({
    super.key,
    required this.story,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,

      child: SizedBox(
        width: 60,

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ===================================================
            // STORY CIRCLE
            // ===================================================

            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,

              children: [

                // =================================================
                // OUTER CIRCLE
                // =================================================

                Container(
                  width: 60,
                  height: 60,

                  padding: const EdgeInsets.all(2),

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: story.isLive
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFFD9D9D9),
                  ),

                  child: Container(
                    width: 56,
                    height: 56,

                    padding: const EdgeInsets.all(2),

                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),

                    child: ClipOval(
                      child: story.image != null
                          ? Image.network(
                        story.image!,
                        width: 52,
                        height: 52,
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
                ),

                // =================================================
                // YOUR STORY + BUTTON
                // =================================================

                if (story.isOwnStory)
                  Positioned(
                    right: -2,
                    bottom: -2,

                    child: Container(
                      width: 22,
                      height: 22,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: const Color(0xFF777777),

                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),

                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),

                // =================================================
                // LIVE BADGE
                // =================================================

                if (story.isLive)
                  Positioned(
                    left: 1,
                    right: 1,
                    bottom: -4,

                    child: Container(
                      height: 19,

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2B20),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),

                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,

                        children: const [

                          Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 9,
                          ),

                          SizedBox(width: 2),

                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // ===================================================
            // STORY NAME
            // ===================================================

            Text(
              story.name,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Color(0xFF444444),
                fontSize: 9,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // PLACEHOLDER
  // ===========================================================

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFD9D9D9),

      child: const SizedBox.expand(),
    );
  }
}