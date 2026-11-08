import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/core/router/main_portal_router.dart';
import 'package:smart_campus_portal/features/auth/data/mock_auth_repository.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/auth/presentation/auth_controller.dart';

// The campus data is shared by every test in this file, so the tests that add
// a resource are kept at the end and run in order.

Future<void> bootApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = AuthController(MockAuthRepository())..bootstrap();
  await tester.pumpWidget(MaterialApp(home: MainPortalRouter(auth: auth)));
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

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

Future<void> signOut(WidgetTester tester) async {
  await tester.tap(tab('Profile'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign out'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('student home shows the next exam', (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    expect(find.text('Next exam'), findsOneWidget);
  });

  testWidgets('the exams page lists the exams and opens the study planner',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    await tester.tap(find.text('Exams and study planner'));
    await tester.pumpAndSettle();
    expect(find.text('CSC 401 - Compiler Construction'), findsOneWidget);

    await tester.tap(find.text('Study planner'));
    await tester.pumpAndSettle();
    expect(find.text('How much can you study each day?'), findsOneWidget);

    await tester.tap(find.text('4 h'));
    await tester.pumpAndSettle();
    expect(find.textContaining('CSC 401 - Compiler Construction'), findsWidgets);
  });

  testWidgets('a lecturer sees the exams but no study planner', (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.lecturer);

    await tester.tap(find.text('Exams'));
    await tester.pumpAndSettle();

    expect(find.text('CSC 401 - Compiler Construction'), findsOneWidget);
    expect(find.text('Study planner'), findsNothing);
  });

  testWidgets('an admin can open the exam manager', (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.admin);

    await tester.tap(find.text('Manage exams'));
    await tester.pumpAndSettle();

    expect(find.text('Add exam'), findsOneWidget);
    expect(find.text('CSC 401 - Compiler Construction'), findsOneWidget);
  });

  testWidgets('a student sees the study resources', (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    await tester.tap(find.text('Study resources'));
    await tester.pumpAndSettle();

    expect(find.text('Lecture notes: Lexical analysis'), findsOneWidget);
    // Students cannot add resources.
    expect(find.text('Add resource'), findsNothing);
  });

  testWidgets('a lecturer cannot save a link that is not https', (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.lecturer);
    await tester.tap(find.text('Study resources'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add resource'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Insecure notes');
    await tester.enterText(fields.at(1), 'http://example.com/x');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a secure link starting with https://'), findsOneWidget);
  });

  testWidgets('a lecturer shares a resource and a student then sees it',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.lecturer);
    await tester.tap(find.text('Study resources'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add resource'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSC 401 - Compiler Construction').last);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Chapter 5 slides');
    await tester.enterText(fields.at(1), 'https://example.com/ch5');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Chapter 5 slides'), findsOneWidget);

    // Back to the lecturer's tabs, sign out, sign in as a student.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await signOut(tester);
    await signInAs(tester, UserRole.student);

    await tester.tap(find.text('Study resources'));
    await tester.pumpAndSettle();
    expect(find.text('Chapter 5 slides'), findsOneWidget);
  });
}
