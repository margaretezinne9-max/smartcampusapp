import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/user_role.dart';

class _Account {
  const _Account(this.user, this.password);
  final AppUser user;
  final String password;
}

/// In-memory demo backend: one account per role.
/// Email: `<role>@hcu.edu` (e.g. courseRep@hcu.edu), password: `password123`.
/// New applicants can also register; accounts last until the app restarts.
class MockAuthRepository implements AuthRepository {
  static const demoPassword = 'password123';

  static String demoEmail(UserRole role) =>
      '${role.name}@hcu.edu'.toLowerCase();

  static bool _isStudentLike(UserRole r) =>
      r == UserRole.student || r == UserRole.courseRep;

  static bool _belongsToDepartment(UserRole r) =>
      _isStudentLike(r) || r == UserRole.lecturer;

  final Map<String, _Account> _accounts = {
    for (final r in UserRole.values)
      demoEmail(r): _Account(
        AppUser(
          id: 'hcu-${r.name}-001',
          name: 'Demo ${r.label}',
          email: demoEmail(r),
          role: r,
          // Demo students and the lecturer belong to Computer Science.
          department: _belongsToDepartment(r) ? 'Computer Science' : null,
          level: _isStudentLike(r) ? 400 : null,
        ),
        demoPassword,
      ),
  };

  AppUser? _session;

  @override
  Future<AppUser?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return _session;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AuthException('Email or password is incorrect.');
    }
    return _session = account.user;
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final normalized = email.trim().toLowerCase();
    if (_accounts.containsKey(normalized)) {
      throw const AuthException('An account with this email already exists.');
    }

    final user = AppUser(
      id: 'hcu-aspirant-${_accounts.length + 1}',
      name: name.trim(),
      email: normalized,
      role: UserRole.aspirant,
    );
    _accounts[normalized] = _Account(user, password);
    return _session = user;
  }

  @override
  Future<void> signOut() async => _session = null;
}
