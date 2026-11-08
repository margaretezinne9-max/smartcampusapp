import 'package:flutter/foundation.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repository, {this.showDemoAccounts = true});

  final AuthRepository _repository;

  /// Whether the login page offers one-tap demo accounts (debug builds only).
  final bool showDemoAccounts;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _error;
  bool _busy = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get error => _error;
  bool get isBusy => _busy;

  /// Call once at startup to restore a saved session.
  Future<void> bootstrap() async {
    try {
      _user = await _repository.restoreSession();
      _status = _user == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) =>
      _authenticate(() => _repository.signIn(email: email, password: password));

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) => _authenticate(
    () => _repository.register(name: name, email: email, password: password),
  );

  Future<void> _authenticate(Future<AppUser> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _user = await action();
      _status = AuthStatus.authenticated;
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error =
          'Could not reach the server. Check your connection and try again.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    _error = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
