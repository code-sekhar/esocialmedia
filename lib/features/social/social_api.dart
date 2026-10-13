import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_session.dart';

class SocialPost {
  final String id,
      content,
      visibility,
      authorId,
      username,
      createdAt,
      updatedAt;
  final String? displayName;
  final int revision;
  SocialPost(
    this.id,
    this.content,
    this.visibility,
    this.revision,
    this.authorId,
    this.username,
    this.displayName,
    this.createdAt,
    this.updatedAt,
  );
  factory SocialPost.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    if (author is! Map<String, dynamic> ||
        json['id'] is! String ||
        json['content'] is! String ||
        !['PUBLIC', 'PRIVATE'].contains(json['visibility']) ||
        json['revision'] is! int ||
        author['id'] is! String ||
        author['username'] is! String ||
        json['createdAt'] is! String ||
        json['updatedAt'] is! String ||
        (author['displayName'] != null && author['displayName'] is! String)) {
      throw const AuthFailure(AuthProblem.protocol);
    }
    return SocialPost(
      json['id'] as String,
      json['content'] as String,
      json['visibility'] as String,
      json['revision'] as int,
      author['id'] as String,
      author['username'] as String,
      author['displayName'] as String?,
      json['createdAt'] as String,
      json['updatedAt'] as String,
    );
  }
}

class PostPage {
  final List<SocialPost> items;
  final String? cursor;
  PostPage(this.items, this.cursor);
  factory PostPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List ||
        (json['nextCursor'] != null && json['nextCursor'] is! String)) {
      throw const AuthFailure(AuthProblem.protocol);
    }
    return PostPage(
      items.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const AuthFailure(AuthProblem.protocol);
        }
        return SocialPost.fromJson(item);
      }).toList(),
      json['nextCursor'] as String?,
    );
  }
}

class SocialApi {
  final AuthSession session;
  SocialApi(this.session);
  Future<PostPage> page({
    bool mine = false,
    String? cursor,
  }) async => PostPage.fromJson(
    await session.social(
      '${mine ? 'posts/mine' : 'feed/home'}?limit=20${cursor == null ? '' : '&cursor=${Uri.encodeQueryComponent(cursor)}'}',
      method: 'GET',
    ),
  );
  Future<SocialPost> create(String text, String visibility) async =>
      SocialPost.fromJson(
        await session.social(
          'posts',
          body: {'content': text, 'visibility': visibility},
        ),
      );
  Future<SocialPost> edit(
    SocialPost post,
    String text,
    String visibility,
  ) async => SocialPost.fromJson(
    await session.social(
      'posts/${post.id}',
      method: 'PATCH',
      body: {
        'content': text,
        'visibility': visibility,
        'expectedRevision': post.revision,
      },
    ),
  );
  Future<void> remove(SocialPost post) async {
    await session.social(
      'posts/${post.id}',
      method: 'DELETE',
      body: {'expectedRevision': post.revision},
    );
  }
}
