import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/core/router/main_portal_router.dart';
import 'package:smart_campus_portal/features/assistant/data/offline_assistant_service.dart';
import 'package:smart_campus_portal/features/assistant/domain/assistant_models.dart';
import 'package:smart_campus_portal/features/assistant/domain/assistant_service.dart';
import 'package:smart_campus_portal/features/assistant/presentation/assistant_controller.dart';
import 'package:smart_campus_portal/features/auth/data/mock_auth_repository.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/auth/presentation/auth_controller.dart';

class _FailingService implements AssistantService {
  @override
  bool get isDemo => false;

  @override
  Future<AssistantReply> ask(String question) async =>
      throw const AssistantException('The assistant is unavailable right now. Please try again.');

  @override
  void reset() {}
}

class _EchoService implements AssistantService {
  int resets = 0;

  @override
  bool get isDemo => false;

  @override
  Future<AssistantReply> ask(String question) async => AssistantReply('You asked: $question');

  @override
  void reset() => resets++;
}

void main() {
  group('AcademicPolicy', () {
    test('recognises the agreed refusal word however it is formatted', () {
      expect(AcademicPolicy.isRefusal('REFUSED'), isTrue);
      expect(AcademicPolicy.isRefusal('  refused. '), isTrue);
      expect(AcademicPolicy.isRefusal('"REFUSED"'), isTrue);
    });

    test('does not mistake a real answer for a refusal', () {
      expect(AcademicPolicy.isRefusal('A deadlock needs four conditions.'), isFalse);
      expect(AcademicPolicy.isRefusal('I refused to guess.'), isFalse);
      expect(AcademicPolicy.isRefusal(''), isFalse);
    });

    test('the system prompt states the scope, the refusal word and honesty', () {
      final prompt = AcademicPolicy.systemPrompt;

      expect(prompt, contains('REFUSED'));
      expect(prompt, contains('never invent'));
      expect(prompt, contains('academic'));
    });
  });

  group('OfflineAssistantService', () {
    final service = OfflineAssistantService();

    test('answers a topic it knows', () async {
      final reply = await service.ask('Explain what a deadlock is');

      expect(reply.refused, isFalse);
      expect(reply.text, contains('circular wait'));
    });

    test('also understands a French question about a known topic', () async {
      final reply = await service.ask("Aide-moi à réviser la normalisation des bases de données");

      expect(reply.refused, isFalse);
      expect(reply.text, contains('1NF'));
    });

    test('refuses non-academic requests', () async {
      final reply = await service.ask('Who won the football match yesterday?');

      expect(reply.refused, isTrue);
    });

    test('admits it does not know instead of inventing an answer', () async {
      final reply = await service.ask('What is the capital of a made-up country?');

      expect(reply.refused, isFalse);
      expect(reply.text, contains('will not guess'));
    });

    test('is labelled as a demo', () {
      expect(service.isDemo, isTrue);
    });
  });

  group('AssistantController', () {
    test('keeps the question and the answer in order', () async {
      final controller = AssistantController(_EchoService());

      await controller.ask('What is recursion?');

      expect(controller.messages, hasLength(2));
      expect(controller.messages.first.fromUser, isTrue);
      expect(controller.messages.last.text, 'You asked: What is recursion?');
      expect(controller.isBusy, isFalse);
    });

    test('ignores an empty question', () async {
      final controller = AssistantController(_EchoService());

      await controller.ask('   ');

      expect(controller.messages, isEmpty);
    });

    test('rejects a question that is too long', () async {
      final controller = AssistantController(_EchoService());

      await controller.ask('x' * (AcademicPolicy.maxQuestionLength + 1));

      expect(controller.messages, isEmpty);
      expect(controller.error, isNotNull);
    });

    test('a refused question is flagged as refused', () async {
      final controller = AssistantController(OfflineAssistantService());

      await controller.ask('Tell me a joke');

      expect(controller.messages.last.refused, isTrue);
    });

    test('a failing service shows an error and keeps the question', () async {
      final controller = AssistantController(_FailingService());

      await controller.ask('What is Big O?');

      expect(controller.error, 'The assistant is unavailable right now. Please try again.');
      expect(controller.messages, hasLength(1));
      expect(controller.isBusy, isFalse);
    });

    test('reset clears the conversation and the service memory', () async {
      final service = _EchoService();
      final controller = AssistantController(service);
      await controller.ask('Hello');

      controller.reset();

      expect(controller.messages, isEmpty);
      expect(service.resets, 1);
    });
  });

  group('assistant screen', () {
    Future<void> boot(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = AuthController(MockAuthRepository())..bootstrap();
      await tester.pumpWidget(MaterialApp(home: MainPortalRouter(auth: auth)));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ActionChip, UserRole.student.label));
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Assistant'),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> ask(WidgetTester tester, String question) async {
      await tester.enterText(find.byType(TextField), question);
      await tester.tap(find.byTooltip('Send'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    // The conversation is kept per user for the whole file, so these tests
    // run in order and the last one resets it.
    testWidgets('shows the disclaimer and example questions', (tester) async {
      await boot(tester);

      expect(
        find.textContaining('AI answers can contain mistakes'),
        findsOneWidget,
      );
      expect(find.textContaining('Demo mode'), findsOneWidget);
      expect(find.text('Explain what a deadlock is'), findsOneWidget);
    });

    testWidgets('answers an academic question', (tester) async {
      await boot(tester);

      await ask(tester, 'Explain what a deadlock is');

      expect(find.textContaining('circular wait'), findsOneWidget);
    });

    testWidgets('refuses a non-academic question', (tester) async {
      await boot(tester);

      await ask(tester, 'Who won the football match?');

      expect(
        find.text('I can only help with academic questions: course content, study methods and exam revision.'),
        findsOneWidget,
      );
    });

    testWidgets('a new conversation clears the chat', (tester) async {
      await boot(tester);

      await tester.tap(find.text('New conversation'));
      await tester.pumpAndSettle();

      expect(find.textContaining('circular wait'), findsNothing);
      expect(find.text('Try asking'), findsOneWidget);
    });
  });
}
