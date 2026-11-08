import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/core/router/main_portal_router.dart';
import 'package:smart_campus_portal/features/auth/data/mock_auth_repository.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/auth/presentation/auth_controller.dart';

// The feedback box is shared by every test in this file. The admin test comes
// last because it reads what the first two tests sent.

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

void main() {
  testWidgets('a student sends feedback', (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'The timetable is very clear.');
    await tester.tap(find.text('Send feedback'));
    await tester.pumpAndSettle();

    expect(find.text('Thank you for your feedback.'), findsOneWidget);
  });

  testWidgets('an empty feedback message is not sent', (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);

    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send feedback'));
    await tester.pumpAndSettle();

    expect(find.text('Please write your feedback.'), findsOneWidget);
  });

  testWidgets('the survey can only be sent when all ten statements are answered',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.student);
    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usability survey'));
    await tester.pumpAndSettle();

    FilledButton submit() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Submit survey'),
        );
    expect(submit().onPressed, isNull);

    // Best possible answers: 5 on positive statements, 1 on negative ones.
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.descendant(
        of: find.byKey(ValueKey('sus-$i')),
        matching: find.text(i.isEven ? '5' : '1'),
      ));
      await tester.pump();
    }
    expect(submit().onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Submit survey'));
    await tester.pumpAndSettle();
    expect(find.text('Thank you for taking part.'), findsOneWidget);
  });

  testWidgets('the admin sees the feedback and the survey average',
      (tester) async {
    await bootApp(tester);
    await signInAs(tester, UserRole.admin);

    await tester.tap(find.text('Feedback and survey results'));
    await tester.pumpAndSettle();

    expect(find.text('The timetable is very clear.'), findsOneWidget);
    expect(find.text('100.0'), findsOneWidget);
    expect(find.text('1 response'), findsOneWidget);
    expect(find.text('Above the average of 68.'), findsOneWidget);
  });
}
