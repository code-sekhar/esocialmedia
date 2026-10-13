import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esocialmedia/core/auth/auth_api.dart';
import 'package:esocialmedia/core/auth/auth_models.dart';
import 'package:esocialmedia/core/auth/auth_session.dart';
import 'package:esocialmedia/core/auth/refresh_store.dart';

class Adapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handle;
  Adapter(this.handle);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handle(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(Object data, [int code = 200]) => ResponseBody.fromString(
  jsonEncode(data),
  code,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

class Store extends MemoryRefreshStore {
  @override
  bool get persistent => true;
}

void main() {
  final user = {
    'id': 'synthetic',
    'email': 'test@example.invalid',
    'username': 'synthetic',
  };
  final pair = {'accessToken': 'access-one', 'refreshToken': 'a' * 128};
  AuthSession client(
    Future<ResponseBody> Function(RequestOptions) handle, [
    RefreshStore? store,
  ]) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1/'));
    dio.httpClientAdapter = Adapter(handle);
    return AuthSession(
      api: AuthApi(client: dio),
      store: store ?? MemoryRefreshStore(),
    );
  }

  test('login/profile/logout use real typed HTTP contracts', () async {
    final paths = <String>[];
    final auth = client((o) async {
      paths.add(o.path);
      return response(
        o.path == 'auth/login'
            ? {...pair, 'user': user}
            : o.path == 'users/me'
            ? user
            : {'message': 'Revoked'},
      );
    });
    await auth.login('test@example.invalid', 'synthetic password');
    expect(auth.authenticated, isTrue);
    expect((await auth.profile()).id, 'synthetic');
    await auth.logout();
    expect(auth.authenticated, isFalse);
    expect(paths, ['auth/login', 'users/me', 'auth/logout']);
  });
  test(
    'registration omits birth data and accepts no registration.user',
    () async {
      final auth = client((o) async {
        expect((o.data as Map).containsKey('dateOfBirth'), isFalse);
        return response({'message': 'Generic'});
      });
      await auth.register(
        Registration(
          email: 'test@example.invalid',
          username: 'synthetic',
          displayName: 'Synthetic',
          password: 'synthetic password',
        ),
      );
      expect(auth.authenticated, isFalse);
    },
  );
  test('verification and complete recovery use opaque reset grant', () async {
    final paths = <String>[];
    final auth = client((o) async {
      paths.add(o.path);
      return response(
        o.path == 'auth/verify-reset-otp'
            ? {'resetToken': 'b' * 64}
            : {'message': 'Generic'},
      );
    });
    await auth.verifyEmail('test@example.invalid', '123456');
    await auth.resend('test@example.invalid');
    await auth.forgot('test@example.invalid');
    final grant = await auth.verifyReset('test@example.invalid', '123456');
    await auth.reset(grant, 'replacement passphrase');
    expect(paths.length, 5);
  });
  test('invalid credentials never establish a session', () async {
    final auth = client((o) async => response({}, 401));
    await expectLater(
      auth.login('test@example.invalid', 'incorrect password'),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.problem,
          'kind',
          AuthProblem.credentials,
        ),
      ),
    );
    expect(auth.authenticated, isFalse);
  });
  test('simultaneous 401 requests coordinate exactly one refresh', () async {
    int refreshes = 0;
    final gate = Completer<void>();
    final auth = client((o) async {
      if (o.path == 'auth/login') return response({...pair, 'user': user});
      if (o.path == 'auth/refresh') {
        refreshes++;
        await gate.future;
        return response({
          'accessToken': 'access-two',
          'refreshToken': 'b' * 128,
        });
      }
      return o.headers['Authorization'] == 'Bearer access-one'
          ? response({}, 401)
          : response(user);
    });
    await auth.login('test@example.invalid', 'synthetic password');
    final requests = [auth.profile(), auth.profile()];
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(refreshes, 1);
    gate.complete();
    await Future.wait(requests);
    expect(refreshes, 1);
  });
  test(
    'uncertain refresh is not retried and erases secure persistence',
    () async {
      final store = Store();
      int refreshes = 0;
      final auth = client((o) async {
        if (o.path == 'auth/login') return response({...pair, 'user': user});
        refreshes++;
        throw DioException(
          requestOptions: o,
          type: DioExceptionType.receiveTimeout,
        );
      }, store);
      await auth.login('test@example.invalid', 'synthetic password');
      expect(await store.read(), pair['refreshToken']);
      await expectLater(auth.rotate(), throwsA(isA<AuthFailure>()));
      expect(refreshes, 1);
      expect(await store.read(), isNull);
      expect(auth.authenticated, isFalse);
    },
  );
  test('refresh credentials are removed before transmission', () async {
    final store = Store();
    final auth = client((o) async {
      if (o.path == 'auth/login') return response({...pair, 'user': user});
      expect(await store.read(), isNull);
      return response({'accessToken': 'access-two', 'refreshToken': 'b' * 128});
    }, store);
    await auth.login('test@example.invalid', 'synthetic password');
    await auth.rotate();
    expect(await store.read(), 'b' * 128);
  });
  test('native restoration rotates once before profile retrieval', () async {
    final store = Store();
    await store.write('a' * 128);
    int rotations = 0;
    final auth = client((o) async {
      if (o.path == 'auth/refresh') {
        rotations++;
        return response(pair);
      }
      return response(user);
    }, store);
    await Future.wait([auth.restore(), auth.restore()]);
    expect(rotations, 1);
    expect(auth.authenticated, isTrue);
  });
  test('confirmed refresh revocation expires the session', () async {
    final auth = client(
      (o) async => o.path == 'auth/login'
          ? response({...pair, 'user': user})
          : response({}, 401),
    );
    await auth.login('test@example.invalid', 'synthetic password');
    await expectLater(auth.rotate(), throwsA(isA<AuthFailure>()));
    expect(auth.authenticated, isFalse);
  });
  for (final entry in {
    429: AuthProblem.rate,
    503: AuthProblem.unavailable,
  }.entries) {
    test('HTTP ${entry.key} has a distinct safe failure', () async {
      final auth = client((o) async => response({}, entry.key));
      await expectLater(
        auth.login('test@example.invalid', 'synthetic password'),
        throwsA(
          isA<AuthFailure>().having((e) => e.problem, 'kind', entry.value),
        ),
      );
    });
  }
  test('logout-all revokes using the authenticated account', () async {
    final paths = <String>[];
    final auth = client((o) async {
      paths.add(o.path);
      return response(
        o.path == 'auth/login'
            ? {...pair, 'user': user}
            : o.path == 'users/me'
            ? user
            : {'message': 'Revoked'},
      );
    });
    await auth.login('test@example.invalid', 'synthetic password');
    await auth.logout(all: true);
    expect(paths.last, 'auth/logout-all');
    expect(auth.authenticated, isFalse);
  });
  test(
    'late rotation response cannot resurrect a logged-out session',
    () async {
      final gate = Completer<void>();
      final auth = client((o) async {
        if (o.path == 'auth/login') return response({...pair, 'user': user});
        if (o.path == 'auth/refresh') {
          await gate.future;
          return response(pair);
        }
        return response({'message': 'Revoked'});
      });
      await auth.login('test@example.invalid', 'synthetic password');
      final rotation = auth.rotate().catchError((Object _) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await auth.logout();
      gate.complete();
      await rotation;
      expect(auth.authenticated, isFalse);
    },
  );
  test('browser memory storage does not claim persistence', () {
    expect(MemoryRefreshStore().persistent, isFalse);
  });
  test('password policy counts Unicode characters and UTF-8 bytes', () {
    expect(validPassword('😀' * 15), isTrue);
    expect(validPassword('😀' * 19), isFalse);
    expect(validPassword('a' * 14), isFalse);
    expect(validEmail('পরীক্ষা@example.invalid'), isTrue);
  });
}
