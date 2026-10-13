import '../login_screen.dart';
import '../account_screen.dart';
import 'package:esocialmedia/core/auth/auth_scope.dart';
import 'package:esocialmedia/screen/dashboard/profile/profile_screen.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/create_post_bar.dart';
import '../../shared/widgets/create_post_screen.dart';
import '../../shared/widgets/friend_suggestion_card.dart';
import '../../shared/widgets/main_menu_drawer.dart';
import '../../features/social/live_posts.dart';
import '../../shared/widgets/social_app_bar.dart';
import '../../shared/widgets/story_section.dart';
import '../chat/chat_screen.dart';
import '../comments_screen/comments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final feedKey = GlobalKey<LivePostsState>();

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    final stories = [
      const StoryModel(name: 'Your Story', isOwnStory: true),

      const StoryModel(name: 'Javier Cruz', isLive: true),

      const StoryModel(name: 'Naomi Lee'),

      const StoryModel(name: 'Bijon Ironside'),

      const StoryModel(name: 'Amelia Jay'),
    ];

    final friends = [
      const FriendSuggestion(
        name: 'Rohan Singh',
        zodiac: 'Capricorn',
        compatibility: 98,
      ),

      const FriendSuggestion(
        name: 'Rohan Singh',
        zodiac: 'Capricorn',
        compatibility: 98,
      ),

      const FriendSuggestion(
        name: 'Rohan Singh',
        zodiac: 'Capricorn',
        compatibility: 98,
      ),

      const FriendSuggestion(
        name: 'Rohan Singh',
        zodiac: 'Capricorn',
        compatibility: 98,
      ),
    ];

    return ProtectedSession(
      child: Scaffold(
        key: scaffoldKey,

        backgroundColor: const Color(0xFFF5F5F5),

        drawer: MainMenuDrawer(
          onProfile: () {
            Navigator.pop(context);

            // ProfileScreen
          },

          onAccount: () {
            Navigator.pop(context);

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            );
          },

          onNotifications: () {
            Navigator.pop(context);

            // পরে NotificationScreen
          },

          onSecurity: () {
            Navigator.pop(context);

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            );
          },

          onLogout: () async {
            Navigator.pop(context);
            final session = AuthScope.of(context);
            try {
              await session.logout();
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Signed out here. Server revocation could not be confirmed.',
                    ),
                  ),
                );
              }
            }
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          },
        ),

        body: SafeArea(
          child: Column(
            children: [
              // =====================================================
              // APP BAR
              // =====================================================
              SocialAppBar(
                profileImage: '',

                onProfile: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },

                onMenu: () {
                  scaffoldKey.currentState?.openDrawer();
                },

                onSearch: () {
                  debugPrint('Search clicked');
                },
                onNotification: () {
                  debugPrint('Notification clicked');

                  // NotificationScreen navigate
                },

                onMessage: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  );
                },
              ),

              // =====================================================
              // MAIN SCROLL
              // =====================================================
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,

                  children: [
                    // =================================================
                    // CREATE POST
                    // =================================================
                    CreatePostBar(
                      onPost: () async {
                        final saved = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreatePostScreen(),
                          ),
                        );
                        if (saved == true && mounted) {
                          await feedKey.currentState?.reload();
                        }
                      },
                    ),

                    // =================================================
                    // STORIES
                    // =================================================
                    ExpansionTile(
                      title: const Text('Story design preview · not live'),
                      children: [
                        StorySection(stories: stories),
                        TextButton(
                          onPressed: () => _openComments(context),
                          child: const Text('Comment design preview'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // =================================================
                    // POSTS
                    // =================================================
                    LivePosts(key: feedKey),

                    // =================================================
                    // FRIEND SUGGESTIONS
                    // =================================================
                    ExpansionTile(
                      title: const Text(
                        'Suggestion design preview · no matching service',
                      ),
                      children: [_friendSuggestions(context, friends)],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // FRIEND SUGGESTIONS
  // =============================================================

  Widget _friendSuggestions(
    BuildContext context,
    List<FriendSuggestion> friends,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),

      padding: const EdgeInsets.fromLTRB(14, 18, 0, 18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // =======================================================
          // TITLE
          // =======================================================
          const Padding(
            padding: EdgeInsets.only(right: 14),

            child: Text(
              'Friend Suggestions',

              style: TextStyle(
                color: Color(0xFF171B27),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // =======================================================
          // RESPONSIVE CAROUSEL
          // =======================================================
          LayoutBuilder(
            builder: (context, constraints) {
              final double availableWidth = constraints.maxWidth;

              // 2 cards + 12px gap
              final double cardWidth = (availableWidth - 12) / 2;

              // Same image ratio as card
              final double imageHeight = cardWidth / 1.12;

              // Card content:
              // name + zodiac + buttons + padding
              const double contentHeight = 155;

              final double cardHeight = imageHeight + contentHeight;

              return SizedBox(
                height: cardHeight,

                child: ListView.separated(
                  scrollDirection: Axis.horizontal,

                  physics: const BouncingScrollPhysics(),

                  padding: EdgeInsets.zero,

                  itemCount: friends.length,

                  separatorBuilder: (_, _) {
                    return const SizedBox(width: 12);
                  },

                  itemBuilder: (context, index) {
                    final friend = friends[index];

                    return SizedBox(
                      width: cardWidth,

                      child: FriendSuggestionCard(
                        friend: friend,

                        onAdd: () {
                          debugPrint('Add Friend: ${friend.name}');
                        },

                        onRemove: () {
                          debugPrint('Remove Friend: ${friend.name}');
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =============================================================
  // COMMENTS
  // =============================================================

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (_) {
        return const CommentsBottomSheet();
      },
    );
  }
}
