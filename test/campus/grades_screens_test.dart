import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/core/router/main_portal_router.dart';
import 'package:smart_campus_portal/features/auth/data/mock_auth_repository.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/auth/presentation/auth_controller.dart';

// The campus data is shared by the tests in this file, so they run in order:
// first the empty results, then a lecturer enters a score.

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

void main() {
  testWidgets('a student with no scores yet sees an empty results page',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    await tester.tap(find.text('Results'));
    await tester.pumpAndSettle();

    expect(find.text('No results have been published yet.'), findsOneWidget);
  });

  testWidgets('a lecturer enters a score and the student then sees the result',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.lecturer);

    await tester.tap(tab('Students'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSC 401 - Compiler Construction'));
    await tester.pumpAndSettle();
    expect(find.text('No score yet'), findsNWidgets(2));

    // Students are sorted by name: the demo course rep first, the student last.
    await tester.tap(find.byTooltip('Edit score').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '72');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Score: 72'), findsOneWidget);

    await tester.tap(tab('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    await signInAs(tester, UserRole.student);
    await tester.tap(find.text('Results'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Compiler Construction'), findsOneWidget);
    expect(find.text('A'), findsOneWidget); // 72 is an A on the 5-point scale
  });

  testWidgets('a score outside 0 to 100 is refused in the dialog', (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.lecturer);

    await tester.tap(tab('Students'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSC 403 - Artificial Intelligence'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit score').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '150');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a whole number from 0 to 100.'), findsOneWidget);
  });
}
