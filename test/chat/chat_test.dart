import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/core/router/main_portal_router.dart';
import 'package:smart_campus_portal/features/auth/data/mock_auth_repository.dart';
import 'package:smart_campus_portal/features/auth/domain/app_user.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/auth/presentation/auth_controller.dart';
import 'package:smart_campus_portal/features/chat/data/in_memory_chat_repository.dart';
import 'package:smart_campus_portal/features/chat/domain/chat_models.dart';

AppUser user(UserRole role, String id) => AppUser(
      id: id,
      name: 'Test ${role.label}',
      email: 'test@hcu.edu',
      role: role,
    );

final student = user(UserRole.student, 'hcu-student-001');
final courseRep = user(UserRole.courseRep, 'hcu-courseRep-001');
final lecturer = user(UserRole.lecturer, 'hcu-lecturer-001');

void main() {
  group('InMemoryChatRepository', () {
    late InMemoryChatRepository repo;

    setUp(() => repo = InMemoryChatRepository());

    test('a student sees the chats of the courses they are enrolled in', () async {
      final rooms = await repo.watchRooms(student).first;

      expect(rooms, hasLength(5));
      expect(rooms.map((r) => r.id), contains('CSC401'));
    });

    test('a student who is not enrolled sees nothing', () async {
      expect(await repo.watchRooms(user(UserRole.student, 'someone-else')).first, isEmpty);
    });

    test('a lecturer sees only the courses they teach', () async {
      expect(await repo.watchRooms(lecturer).first, hasLength(5));
      expect(
        await repo.watchRooms(user(UserRole.lecturer, 'other-lecturer')).first,
        isEmpty,
      );
    });

    test('bursars and aspirants have no course chats', () async {
      expect(await repo.watchRooms(user(UserRole.bursar, 'b')).first, isEmpty);
      expect(await repo.watchRooms(user(UserRole.aspirant, 'a')).first, isEmpty);
    });

    test('each room starts with a welcome message from the lecturer', () async {
      final messages = await repo.watchMessages('CSC401').first;

      expect(messages, hasLength(1));
      expect(messages.first.senderRole, UserRole.lecturer);
    });

    test('a sent message reaches listeners in real time with the sender details',
        () async {
      final seen = expectLater(
        repo.watchMessages('CSC401'),
        emitsThrough(predicate<List<ChatMessage>>(
          (list) => list.isNotEmpty && list.last.text == 'Is the test open book?',
        )),
      );

      await repo.sendMessage(
        roomId: 'CSC401',
        sender: student,
        text: '  Is the test open book?  ',
      );

      await seen;
      final last = (await repo.watchMessages('CSC401').first).last;
      expect(last.senderId, student.id);
      expect(last.senderRole, UserRole.student);
    });

    test('messages from two people stay in order', () async {
      await repo.sendMessage(roomId: 'CSC403', sender: student, text: 'First');
      await repo.sendMessage(roomId: 'CSC403', sender: lecturer, text: 'Second');

      final texts = (await repo.watchMessages('CSC403').first).map((m) => m.text);
      expect(texts.toList().sublist(texts.length - 2), ['First', 'Second']);
    });

    test('an empty or too long message is rejected', () async {
      expect(
        () => repo.sendMessage(roomId: 'CSC401', sender: student, text: '   '),
        throwsArgumentError,
      );
      expect(
        () => repo.sendMessage(
          roomId: 'CSC401',
          sender: student,
          text: 'x' * (ChatRules.maxMessageLength + 1),
        ),
        throwsArgumentError,
      );
    });

    test('someone outside the course cannot post in its chat', () async {
      expect(
        () => repo.sendMessage(
          roomId: 'CSC401',
          sender: user(UserRole.student, 'not-enrolled'),
          text: 'Hello',
        ),
        throwsStateError,
      );
    });

    test('a course rep is a member like any enrolled student', () async {
      await repo.sendMessage(roomId: 'CSC401', sender: courseRep, text: 'Notes uploaded');

      final last = (await repo.watchMessages('CSC401').first).last;
      expect(last.senderRole, UserRole.courseRep);
    });
  });

  group('chat screens', () {
    Future<void> boot(WidgetTester tester) async {
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

    Future<void> openRoom(WidgetTester tester, String title) async {
      await tester.tap(tab('Chat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
    }

    Future<void> send(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
    }

    // The chat is shared by every test in this file, so the test that needs
    // an earlier message comes after the one that sends it.
    testWidgets('a student sees their course chats and the welcome message',
        (tester) async {
      await boot(tester);
      await signInAs(tester, UserRole.student);

      await tester.tap(tab('Chat'));
      await tester.pumpAndSettle();
      expect(find.text('CSC 401 - Compiler Construction'), findsOneWidget);
      expect(find.text('GST 401 - Entrepreneurship Studies'), findsOneWidget);

      await tester.tap(find.text('CSC 401 - Compiler Construction'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Welcome to CSC 401'), findsOneWidget);
    });

    testWidgets('a lecturer posts and the message reaches a student',
        (tester) async {
      await boot(tester);
      await signInAs(tester, UserRole.lecturer);

      await openRoom(tester, 'CSC 401 - Compiler Construction');
      await send(tester, 'Read chapter 3 before Monday');
      expect(find.text('Read chapter 3 before Monday'), findsOneWidget);

      // Back to the lecturer's tabs, sign out, sign in as a student.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(tab('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      await signInAs(tester, UserRole.student);
      await openRoom(tester, 'CSC 401 - Compiler Construction');

      expect(find.text('Read chapter 3 before Monday'), findsOneWidget);
    });
  });
}
