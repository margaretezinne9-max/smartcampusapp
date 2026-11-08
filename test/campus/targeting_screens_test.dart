import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/core/router/main_portal_router.dart';
import 'package:smart_campus_portal/features/auth/data/mock_auth_repository.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/auth/presentation/auth_controller.dart';

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

void main() {
  testWidgets('student home shows the calendar bar of upcoming events',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    expect(find.text('Upcoming events'), findsOneWidget);
    // The Cultural Day tile counts down 14 days.
    expect(find.text('In 14 days'), findsOneWidget);
  });

  testWidgets('tapping an event opens its details', (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    await tester.tap(find.text('In 14 days'));
    await tester.pumpAndSettle();

    // The same text also appears in the notices list behind the sheet, so
    // look only inside the bottom sheet.
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Come in your traditional attire. Venue: Main Campus field.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a student only sees notices meant for their department and level',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    await tester.tap(find.text('All notices'));
    await tester.pumpAndSettle();

    expect(find.text('Final-year project briefing'), findsOneWidget);
    expect(find.text('Law orientation week'), findsNothing);
  });

  testWidgets('an admin sees every notice, including targeted ones',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.admin);

    await tester.tap(tab('Notices'));
    await tester.pumpAndSettle();

    expect(find.text('Final-year project briefing'), findsOneWidget);
    expect(find.text('Law orientation week'), findsOneWidget);
  });
}
