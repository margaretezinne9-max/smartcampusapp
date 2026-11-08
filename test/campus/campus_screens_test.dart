import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/core/router/main_portal_router.dart';
import 'package:smart_campus_portal/features/auth/data/mock_auth_repository.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/auth/presentation/auth_controller.dart';

// These tests use the in-memory demo backend (kUseFirebase is false).
// The campus repository is shared by every test in this file, so the test
// that publishes a notice is kept last.

Future<void> bootApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
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

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(tab(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('student home shows the next class with hall and campus info',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    expect(
      find.byWidgetPredicate((w) =>
          w is Text && (w.data == 'Next class' || w.data == 'Happening now')),
      findsOneWidget,
    );
    expect(find.text('Hall and campus info'), findsOneWidget);
    expect(find.text('Latest notices'), findsOneWidget);
  });

  testWidgets('tapping hall and campus info shows directions and a Maps button',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    await tester.tap(find.text('Hall and campus info'));
    await tester.pumpAndSettle();

    expect(find.text('How to get there'), findsOneWidget);
    expect(find.text('Open in Google Maps'), findsOneWidget);
  });

  testWidgets('student timetable lists the weekly classes', (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    await openTab(tester, 'Timetable');

    expect(find.text('CSC 401 - Compiler Construction'), findsOneWidget);
    expect(find.text('GST 401 - Entrepreneurship Studies'), findsOneWidget);
  });

  testWidgets('student sees notices and events', (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    // Notices are a shortcut on Home (the bottom bar holds at most 5 tabs).
    await tester.tap(find.text('All notices'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to the new semester'), findsOneWidget);
    expect(find.text('Cultural Day'), findsOneWidget);
    // Students cannot publish.
    expect(find.text('Publish notice'), findsNothing);
  });

  testWidgets('lecturer sees only their own students, grouped by course',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.lecturer);

    await openTab(tester, 'Students');
    expect(find.text('2 students'), findsNWidgets(5));

    await tester.tap(find.text('CSC 401 - Compiler Construction'));
    await tester.pumpAndSettle();
    expect(find.text('Demo Student'), findsOneWidget);
    expect(find.text('Demo Course Rep'), findsOneWidget);
  });

  testWidgets('admin sees every user and cannot change their own role',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.admin);

    await openTab(tester, 'Users');

    expect(find.text('Demo Student'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('admin publishes a notice and it appears straight away',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.admin);

    await openTab(tester, 'Notices');
    await tester.tap(find.text('Publish notice'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Exam timetable released');
    await tester.enterText(fields.at(1), 'See the notice board.');
    await tester.tap(find.widgetWithText(FilledButton, 'Publish'));
    await tester.pumpAndSettle();

    expect(find.text('Exam timetable released'), findsOneWidget);
  });
}
