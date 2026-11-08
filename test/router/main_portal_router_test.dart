import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/core/router/main_portal_router.dart';
import 'package:smart_campus_portal/features/auth/data/mock_auth_repository.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/auth/presentation/auth_controller.dart';
import 'package:smart_campus_portal/features/portal/role_registry.dart';

/// Starts the router on a phone-sized screen and waits for the login page.
Future<AuthController> bootApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = AuthController(MockAuthRepository())..bootstrap();
  await tester.pumpWidget(MaterialApp(home: MainPortalRouter(auth: auth)));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return auth;
}

/// Taps the demo chip for [role], then Sign in, and waits for the dashboard.
Future<void> signInAs(WidgetTester tester, UserRole role) async {
  await tester.tap(find.widgetWithText(ActionChip, role.label));
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

Finder tab(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

void main() {
  testWidgets('shows the splash screen while restoring the session', (tester) async {
    final auth = AuthController(MockAuthRepository())..bootstrap();
    await tester.pumpWidget(MaterialApp(home: MainPortalRouter(auth: auth)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sign in to your campus portal'), findsNothing);

    await tester.pump(const Duration(seconds: 1)); // let bootstrap finish
    await tester.pumpAndSettle();
  });

  testWidgets('shows the login page when signed out', (tester) async {
    await bootApp(tester);

    expect(find.text('Sign in to your campus portal'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  group('each role gets its own dashboard', () {
    for (final role in UserRole.values) {
      testWidgets('${role.label} sees only its own tabs', (tester) async {
        await bootApp(tester);
        await signInAs(tester, role);

        final config = RoleRegistry.of(role);

        // Top bar shows the role.
        expect(find.widgetWithText(Chip, role.label), findsOneWidget);
        expect(find.text('Welcome, Demo'), findsOneWidget);

        // Home + this role's modules + Profile.
        expect(tab('Home'), findsOneWidget);
        for (final m in config.modules) {
          expect(tab(m.label), findsOneWidget);
        }
        expect(tab('Profile'), findsOneWidget);

        // No tab that belongs to a different role leaks in.
        for (final other in UserRole.values.where((r) => r != role)) {
          for (final m in RoleRegistry.of(other).modules) {
            final isShared = config.modules.any((x) => x.label == m.label);
            if (!isShared) expect(tab(m.label), findsNothing);
          }
        }
      });
    }
  });

  testWidgets('signing out returns to the login page', (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    await tester.tap(tab('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to your campus portal'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('wrong password shows an error and stays on the login page',
      (tester) async {
    await bootApp(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'student@hcu.edu');
    await tester.enterText(fields.at(1), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('empty form shows validation errors without signing in',
      (tester) async {
    await bootApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
  });

  testWidgets('a new applicant can register and lands on the aspirant portal',
      (tester) async {
    await bootApp(tester);

    await tester.tap(find.text('New applicant? Create an account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ada Obi');
    await tester.enterText(fields.at(1), 'ada@example.com');
    await tester.enterText(fields.at(2), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Ada'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Aspirant'), findsOneWidget);
    expect(tab('Application'), findsOneWidget);
    expect(tab('Admission'), findsOneWidget);
  });
}
