import 'app_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Contract the UI depends on. Implement it with Firebase Auth,
/// a Laravel/Node REST API, etc. without touching any widget.
abstract interface class AuthRepository {
  Future<AppUser?> restoreSession();
  Future<AppUser> signIn({required String email, required String password});

  /// Self-registration. New accounts are always created as aspirants;
  /// other roles must be assigned by an administrator.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
