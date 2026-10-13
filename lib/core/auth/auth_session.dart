import 'package:flutter/foundation.dart';
import 'auth_api.dart';
import 'auth_models.dart';
import 'refresh_store.dart';

class AuthSession extends ChangeNotifier {
  final AuthApi api;
  final RefreshStore store;
  AuthSession({required this.api, required this.store});
  String? _access, _refresh;
  Account? account;
  AuthProblem? restorationProblem;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    super.dispose();
  }

  bool ready = false;
  bool logoutUnconfirmed = false;
  bool _persist = true;
  int _epoch = 0;
  Future<void>? _flight;
  Future<void> _storage = Future.value();
  bool get authenticated => _access != null && account != null;
  bool get supportsPersistence => store.persistent;
  Future<void> _store(Future<void> Function() work) {
    final next = _storage.catchError((Object _) {}).then((_) => work());
    _storage = next;
    return next;
  }

  Future<void> clear() async {
    ++_epoch;
    _access = null;
    _refresh = null;
    _flight = null;
    account = null;
    notifyListeners();
    try {
      await _store(store.delete);
    } catch (_) {
      throw const AuthFailure(AuthProblem.storage);
    }
  }

  Future<void>? _restoration;
  Future<void> restore() => _restoration ??= _restore();
  Future<void> _restore() async {
    try {
      final token = await store.read();
      if (token != null) {
        if (!RegExp(r'^[a-f0-9]{128}$').hasMatch(token)) {
          await clear();
        } else {
          _refresh = token;
          await rotate();
          await profile();
        }
      }
    } on AuthFailure catch (error) {
      restorationProblem = error.problem;
    } catch (_) {
      restorationProblem = AuthProblem.storage;
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> _accept(TokenPair pair, int epoch) async {
    if (epoch != _epoch) throw const AuthFailure(AuthProblem.expired);
    if (_persist && store.persistent) {
      try {
        await _store(() async {
          if (epoch == _epoch) await store.write(pair.refreshToken);
        });
      } catch (_) {
        await clear();
        throw const AuthFailure(AuthProblem.storage);
      }
    }
    if (epoch != _epoch) throw const AuthFailure(AuthProblem.expired);
    _access = pair.accessToken;
    _refresh = pair.refreshToken;
  }

  Future<void> login(
    String email,
    String password, {
    bool remember = true,
  }) async {
    await clear();
    _persist = remember && store.persistent;
    final epoch = _epoch;
    try {
      final result = await api.request(
        'auth/login',
        body: {'email': email.trim().toLowerCase(), 'password': password},
      );
      final user = result['user'];
      if (user is! Map<String, dynamic>) {
        throw const AuthFailure(AuthProblem.protocol);
      }
      final next = Account.fromJson(user);
      await _accept(TokenPair.fromJson(result), epoch);
      if (epoch != _epoch) throw const AuthFailure(AuthProblem.expired);
      account = next;
      notifyListeners();
    } catch (error) {
      if (epoch == _epoch) await clear();
      rethrow;
    }
  }

  Future<void> register(Registration body) async {
    await api.request('auth/register', body: body.toJson());
  }

  Future<void> verifyEmail(String email, String otp) async {
    await api.request('auth/verify-email', body: {'email': email, 'otp': otp});
  }

  Future<void> resend(String email) async {
    await api.request('auth/resend-verification', body: {'email': email});
  }

  Future<void> forgot(String email) async {
    await api.request('auth/forgot-password', body: {'email': email});
  }

  Future<String> verifyReset(String email, String otp) async {
    final result = await api.request(
      'auth/verify-reset-otp',
      body: {'email': email, 'otp': otp},
    );
    final token = result['resetToken'];
    if (token is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(token)) {
      throw const AuthFailure(AuthProblem.protocol);
    }
    return token;
  }

  Future<void> reset(String token, String password) async {
    await api.request(
      'auth/reset-password',
      body: {'resetToken': token, 'newPassword': password},
    );
    await clear();
  }

  Future<void> rotate() {
    if (_flight != null) return _flight!;
    final value = _refresh;
    final epoch = _epoch;
    if (value == null) {
      return Future.error(const AuthFailure(AuthProblem.expired));
    }
    late Future<void> work;
    work = () async {
      try {
        // Erase before transmission: a crash cannot persist/retry a spent token.
        await _store(store.delete);
        if (epoch != _epoch) throw const AuthFailure(AuthProblem.expired);
        final result = await api.request(
          'auth/refresh',
          body: {'refreshToken': value},
        );
        await _accept(TokenPair.fromJson(result), epoch);
      } catch (error) {
        if (epoch == _epoch &&
            !(error is AuthFailure && error.problem == AuthProblem.rate)) {
          await clear();
        }
        if (error is AuthFailure) rethrow;
        throw const AuthFailure(AuthProblem.storage);
      } finally {
        if (identical(_flight, work)) _flight = null;
      }
    }();
    _flight = work;
    return work;
  }

  Future<Account> profile() async {
    final access = _access;
    final epoch = _epoch;
    if (access == null) throw const AuthFailure(AuthProblem.expired);
    Map<String, dynamic> result;
    try {
      result = await api.request('users/me', access: access, get: true);
    } on AuthFailure catch (error) {
      if (error.problem != AuthProblem.credentials) rethrow;
      if (epoch != _epoch) throw const AuthFailure(AuthProblem.expired);
      if (access == _access) await rotate();
      try {
        result = await api.request('users/me', access: _access, get: true);
      } on AuthFailure catch (retry) {
        if (retry.problem == AuthProblem.credentials) await clear();
        rethrow;
      }
    }
    if (epoch != _epoch) throw const AuthFailure(AuthProblem.expired);
    account = Account.fromJson(result);
    notifyListeners();
    return account!;
  }

  Future<Map<String, dynamic>> social(
    String path, {
    Object? body,
    String method = 'POST',
  }) async {
    await profile();
    final epoch = _epoch;
    try {
      final result = await api.request(
        path,
        body: body,
        access: _access,
        method: method,
        get: method == 'GET',
      );
      if (epoch != _epoch) throw const AuthFailure(AuthProblem.expired);
      return result;
    } on AuthFailure catch (error) {
      if (error.problem == AuthProblem.credentials) {
        if (epoch == _epoch) await clear();
        throw const AuthFailure(AuthProblem.expired);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> privacy(
    String action, {
    String? password,
  }) async {
    await profile();
    final epoch = _epoch;
    final result = await api.request(
      'privacy/$action',
      get: action == 'status',
      access: _access,
      body: action == 'status'
          ? null
          : {
              'password': password,
              if (action == 'deletion-request')
                'confirmation': 'REQUEST_DELETION',
            },
    );
    if (epoch != _epoch) throw const AuthFailure(AuthProblem.expired);
    if (action == 'deletion-request') {
      try {
        await clear();
      } catch (_) {
        logoutUnconfirmed = true;
      }
    }
    return result;
  }

  Future<void> change(
    String path,
    Object body, {
    String method = 'PATCH',
  }) async {
    await profile();
    final epoch = _epoch;
    await api.request(path, body: body, access: _access, method: method);
    if (epoch != _epoch) throw const AuthFailure(AuthProblem.expired);
    await profile();
  }

  Future<Uint8List?> avatar() async {
    final url = account?.avatarUrl;
    if (url == null) return null;
    if (!RegExp(
      r'^/(api/v1/users/avatar|uploads/avatars)/[a-f0-9-]{36}\.(webp|png|jpg|jpeg)$',
    ).hasMatch(url)) {
      return null;
    }
    await profile();
    final epoch = _epoch;
    final data = await api.download(
      url.startsWith('/uploads/')
          ? 'users/avatar/legacy/${url.split('/').last}'
          : url.substring('/api/v1/'.length),
      _access!,
    );
    if (epoch != _epoch) throw const AuthFailure(AuthProblem.expired);
    return data;
  }

  Future<void> logout({bool all = false}) async {
    if (all) {
      try {
        await profile();
        await api.request('auth/logout-all', body: {}, access: _access);
      } catch (_) {
        logoutUnconfirmed = true;
        await clear();
        rethrow;
      }
      await clear();
      return;
    }
    final value = _refresh;
    Object? storageFailure;
    try {
      await clear();
    } catch (error) {
      storageFailure = error;
    }
    if (value != null) {
      try {
        await api.request('auth/logout', body: {'refreshToken': value});
      } catch (_) {
        logoutUnconfirmed = true;
        rethrow;
      }
    }
    if (storageFailure != null) {
      logoutUnconfirmed = true;
      throw storageFailure;
    }
  }
}
