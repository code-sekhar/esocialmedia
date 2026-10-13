import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/core/auth/auth_api.dart';
import 'package:esocialmedia/core/auth/auth_models.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/auth_scope.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';
import 'package:esocialmedia/features/social/social_api.dart';
import 'package:esocialmedia/features/social/live_posts.dart';
import 'package:esocialmedia/shared/widgets/create_post_screen.dart';

class SocialAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int postStatus = 200;
  int feedStatus = 200;
  final user = {
    'id': 'owner',
    'email': 'synthetic@example.invalid',
    'username': 'owner',
  };
  final post = {
    'id': 'p',
    'content': '<script>inert text</script>',
    'visibility': 'PRIVATE',
    'revision': 0,
    'createdAt': '2026-10-13T00:00:00Z',
    'updatedAt': '2026-10-13T00:00:00Z',
    'author': {'id': 'owner', 'username': 'owner', 'displayName': null},
  };
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    Object result = user;
    if (o.path == 'auth/login') {
      result = {
        'user': user,
        'accessToken': 'access',
        'refreshToken': 'a' * 128,
      };
    } else if (o.path.startsWith('feed/home') ||
        o.path.startsWith('posts/mine')) {
      result = {
        'items': [post],
        'nextCursor': null,
      };
    } else if (o.path.startsWith('posts')) {
      result = post;
    }
    return ResponseBody.fromString(
      jsonEncode(result),
      o.path.startsWith('feed')
          ? feedStatus
          : o.path.startsWith('posts')
          ? postStatus
          : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

Future<({AuthSession auth, SocialAdapter adapter})> fixture() async {
  final adapter = SocialAdapter();
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1/'));
  dio.httpClientAdapter = adapter;
  final auth = AuthSession(
    api: AuthApi(client: dio),
    store: MemoryRefreshStore(),
  );
  await auth.login('synthetic@example.invalid', 'synthetic secure passphrase');
  return (auth: auth, adapter: adapter);
}

void main() {
  test(
    'typed API forwards visibility, cursor, ownership revision and bearer',
    () async {
      final f = await fixture();
      try {
        final api = SocialApi(f.auth);
        final p = await api.create('Hello', 'PRIVATE');
        await api.edit(p, 'Edited', 'PUBLIC');
        await api.remove(p);
        await api.page(cursor: 'opaque+/=');
        final calls = f.adapter.requests
            .where(
              (o) => o.path.startsWith('posts') || o.path.startsWith('feed'),
            )
            .toList();
        expect(calls[0].data, {'content': 'Hello', 'visibility': 'PRIVATE'});
        expect(calls[1].data, {
          'content': 'Edited',
          'visibility': 'PUBLIC',
          'expectedRevision': 0,
        });
        expect(calls[2].method, 'DELETE');
        expect(calls.last.path, contains('opaque%2B%2F%3D'));
        expect(
          calls.every((o) => o.headers['Authorization'] == 'Bearer access'),
          isTrue,
        );
      } finally {
        f.auth.dispose();
      }
    },
  );
  test(
    'confirmed social 401 clears credentials and does not replay writes',
    () async {
      final f = await fixture();
      try {
        f.adapter.postStatus = 401;
        await expectLater(
          SocialApi(f.auth).create('Text', 'PRIVATE'),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.problem,
              'problem',
              AuthProblem.expired,
            ),
          ),
        );
        expect(f.auth.authenticated, isFalse);
        expect(f.adapter.requests.where((o) => o.path == 'posts').length, 1);
        expect(
          f.adapter.requests.where((o) => o.path == 'auth/refresh'),
          isEmpty,
        );
      } finally {
        f.auth.dispose();
      }
    },
  );
  testWidgets('feed outage is an error rather than a fabricated empty result', (
    tester,
  ) async {
    final f = (await tester.runAsync(fixture))!;
    addTearDown(f.auth.dispose);
    f.adapter.feedStatus = 503;
    await tester.pumpWidget(
      AuthScope(
        session: f.auth,
        child: const MaterialApp(home: Scaffold(body: LivePosts())),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No posts yet.'), findsNothing);
    expect(f.auth.authenticated, isTrue);
    expect(tester.takeException(), isNull);
    expect(find.byType(Semantics), findsWidgets);
  });
  testWidgets(
    'composer hides saved edit content after confirmed session loss',
    (tester) async {
      final f = (await tester.runAsync(fixture))!;
      addTearDown(f.auth.dispose);
      final post = SocialPost.fromJson(f.adapter.post);
      await tester.pumpWidget(
        AuthScope(
          session: f.auth,
          child: MaterialApp(home: CreatePostScreen(post: post)),
        ),
      );
      expect(find.byType(CreatePostScreen), findsOneWidget);
      expect(find.text('Edit Post'), findsOneWidget);
      await tester.runAsync(f.auth.clear);
      await tester.pump();
      expect(find.text('Edit Post'), findsNothing);
      expect(find.textContaining('inert text'), findsNothing);
      expect(f.adapter.requests.where((o) => o.path == 'posts'), isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('rejects malformed post and page envelopes', () {
    expect(() => SocialPost.fromJson({}), throwsA(isA<Exception>()));
    expect(
      () => PostPage.fromJson({'items': 'invalid'}),
      throwsA(isA<Exception>()),
    );
  });
  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('live feed preserves cards without fake engagement at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = (await tester.runAsync(fixture))!;
      addTearDown(f.auth.dispose);
      await tester.pumpWidget(
        AuthScope(
          session: f.auth,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: LivePosts())),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('<script>inert text</script>'), findsOneWidget);
      expect(find.text('Like'), findsNothing);
      expect(find.textContaining('Comments'), findsNothing);
      expect(find.text('Edit post'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'existing composer validates empty text and publishes a real request',
    (tester) async {
      final f = (await tester.runAsync(fixture))!;
      addTearDown(f.auth.dispose);
      await tester.pumpWidget(
        AuthScope(
          session: f.auth,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CreatePostScreen(),
                    ),
                  ),
                  child: const Text('Open composer'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open composer'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Create Post'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Post'));
      await tester.pumpAndSettle();
      expect(f.adapter.requests.where((o) => o.path == 'posts'), isEmpty);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Actual words');
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Create Post'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Post'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(f.adapter.requests.where((o) => o.path == 'posts').single.data, {
        'content': 'Actual words',
        'visibility': 'PRIVATE',
      });
      expect(find.text('Open composer'), findsOneWidget);
    },
  );
}
