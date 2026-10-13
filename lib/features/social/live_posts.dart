import 'package:flutter/material.dart';
import '../../core/auth/auth_scope.dart';
import '../../core/l10n/auth_copy.dart';
import '../../shared/widgets/create_post_screen.dart';
import '../../shared/widgets/post_card.dart';
import 'social_api.dart';

class LivePosts extends StatefulWidget {
  const LivePosts({super.key});
  @override
  State<LivePosts> createState() => LivePostsState();
}

class LivePostsState extends State<LivePosts> {
  List<SocialPost> posts = [];
  String? cursor;
  String error = '';
  bool busy = false, initialized = false, mine = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      reload();
    }
  }

  Future<void> reload({bool older = false}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final page = await SocialApi(
        AuthScope.of(context),
      ).page(mine: mine, cursor: older ? cursor : null);
      if (!mounted) return;
      setState(() {
        posts = older
            ? [
                ...posts,
                ...page.items.where((p) => !posts.any((old) => old.id == p.id)),
              ]
            : page.items;
        cursor = page.cursor;
        error = '';
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => error =
              '${AuthCopy.error(e)} Refresh before retrying an uncertain change.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit(SocialPost post) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreatePostScreen(post: post)),
    );
    if (saved == true && mounted) await reload();
  }

  Future<void> remove(SocialPost post) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this post?'),
        content: const Text(
          'This hides it from feeds. Stored content remains under the pending retention policy and in your private export.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep post'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm removal'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted || busy) return;
    setState(() => busy = true);
    try {
      await SocialApi(AuthScope.of(context)).remove(post);
      if (mounted) setState(() => posts.removeWhere((p) => p.id == post.id));
    } catch (e) {
      if (mounted) setState(() => error = AuthCopy.error(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = AuthScope.of(context).account?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      setState(() {
                        mine = false;
                        posts = [];
                        cursor = null;
                      });
                      reload();
                    },
              child: Text(mine ? 'Home' : 'Home · selected'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      setState(() {
                        mine = true;
                        posts = [];
                        cursor = null;
                      });
                      reload();
                    },
              child: Text(mine ? 'My posts · selected' : 'My posts'),
            ),
            TextButton(
              onPressed: busy ? null : reload,
              child: const Text('Refresh posts'),
            ),
          ],
        ),
        if (busy) const LinearProgressIndicator(),
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Semantics(liveRegion: true, child: Text(error)),
          ),
        if (!busy && error.isEmpty && posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No posts yet. Share a text post without astrology.'),
          ),
        for (final post in posts)
          Column(
            children: [
              PostCard(
                key: ValueKey('${post.id}:${post.revision}'),
                live: true,
                post: PostModel(
                  userName: post.displayName ?? post.username,
                  time:
                      '${post.createdAt} · ${post.visibility}${post.revision > 0 ? ' · Edited' : ''}',
                  content: post.content,
                ),
              ),
              if (post.authorId == owner)
                Wrap(
                  children: [
                    TextButton(
                      onPressed: busy ? null : () => edit(post),
                      child: const Text('Edit post'),
                    ),
                    TextButton(
                      onPressed: busy ? null : () => remove(post),
                      child: const Text('Remove post'),
                    ),
                  ],
                ),
            ],
          ),
        if (cursor != null)
          TextButton(
            onPressed: busy ? null : () => reload(older: true),
            child: const Text('Load older posts'),
          ),
      ],
    );
  }
}
