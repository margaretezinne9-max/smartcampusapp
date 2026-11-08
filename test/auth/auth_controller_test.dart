import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/features/auth/data/mock_auth_repository.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/auth/presentation/auth_controller.dart';

void main() {
  late AuthController auth;

  setUp(() => auth = AuthController(MockAuthRepository()));

  test('starts unknown, then unauthenticated when there is no session', () async {
    expect(auth.status, AuthStatus.unknown);

    await auth.bootstrap();

    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.user, isNull);
  });

  group('sign in', () {
    for (final role in UserRole.values) {
      test('${role.label} signs in and receives the ${role.name} role', () async {
        await auth.signIn(
          MockAuthRepository.demoEmail(role),
          MockAuthRepository.demoPassword,
        );

        expect(auth.status, AuthStatus.authenticated);
        expect(auth.user?.role, role);
        expect(auth.error, isNull);
      });
    }

    test('wrong password is rejected with an error message', () async {
      await auth.signIn('student@hcu.edu', 'not-the-password');

      expect(auth.status, isNot(AuthStatus.authenticated));
      expect(auth.user, isNull);
      expect(auth.error, 'Email or password is incorrect.');
    });

    test('unknown email is rejected', () async {
      await auth.signIn('nobody@hcu.edu', MockAuthRepository.demoPassword);

      expect(auth.user, isNull);
      expect(auth.error, isNotNull);
    });

    test('email is trimmed and case-insensitive', () async {
      await auth.signIn('  STUDENT@HCU.EDU ', MockAuthRepository.demoPassword);

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.user?.role, UserRole.student);
    });

    test('isBusy is true while signing in and false afterwards', () async {
      final future =
          auth.signIn('student@hcu.edu', MockAuthRepository.demoPassword);
      expect(auth.isBusy, isTrue);

      await future;
      expect(auth.isBusy, isFalse);
    });

    test('listeners are notified when state changes', () async {
      var notifications = 0;
      auth.addListener(() => notifications++);

      await auth.signIn('student@hcu.edu', MockAuthRepository.demoPassword);

      expect(notifications, greaterThanOrEqualTo(2)); // busy on, then result
    });
  });

  group('register', () {
    test('creates an account that is always an aspirant', () async {
      await auth.register(
        name: 'Ada Obi',
        email: 'ada@example.com',
        password: 'secret123',
      );

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.user?.role, UserRole.aspirant);
      expect(auth.user?.name, 'Ada Obi');
    });

    test('rejects an email that is already registered', () async {
      await auth.register(
        name: 'Someone',
        email: 'student@hcu.edu',
        password: 'secret123',
      );

      expect(auth.status, isNot(AuthStatus.authenticated));
      expect(auth.error, 'An account with this email already exists.');
    });

    test('a new account can sign in again after signing out', () async {
      await auth.register(
        name: 'Ada Obi',
        email: 'ada@example.com',
        password: 'secret123',
      );
      await auth.signOut();

      await auth.signIn('ada@example.com', 'secret123');

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.user?.role, UserRole.aspirant);
    });
  });

  test('signOut clears the user and returns to unauthenticated', () async {
    await auth.signIn('admin@hcu.edu', MockAuthRepository.demoPassword);

    await auth.signOut();

    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.user, isNull);
  });

  test('UserRole.parse falls back to the least-privileged role', () {
    expect(UserRole.parse('bursar'), UserRole.bursar);
    expect(UserRole.parse('superuser'), UserRole.aspirant);
    expect(UserRole.parse(null), UserRole.aspirant);
  });
}
