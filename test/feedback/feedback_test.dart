import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_portal/features/auth/domain/user_role.dart';
import 'package:smart_campus_portal/features/feedback/data/in_memory_feedback_repository.dart';
import 'package:smart_campus_portal/features/feedback/domain/feedback_models.dart';

SusResponse response(double score) => SusResponse(
      id: '$score',
      role: UserRole.student,
      answers: const [3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
      score: score,
      createdAt: DateTime(2026, 11, 1),
    );

void main() {
  group('SUS score', () {
    test('the best possible answers give 100', () {
      expect(Sus.score([5, 1, 5, 1, 5, 1, 5, 1, 5, 1]), 100);
    });

    test('the worst possible answers give 0', () {
      expect(Sus.score([1, 5, 1, 5, 1, 5, 1, 5, 1, 5]), 0);
    });

    test('all neutral answers give 50', () {
      expect(Sus.score(List.filled(10, 3)), 50);
    });

    test('a worked example: 4 on positive and 2 on negative statements gives 75', () {
      // Positive: (4-1) x 5 = 15. Negative: (5-2) x 5 = 15. (15 + 15) x 2.5 = 75.
      expect(Sus.score([4, 2, 4, 2, 4, 2, 4, 2, 4, 2]), 75);
    });

    test('the wrong number of answers is rejected', () {
      expect(() => Sus.score([5, 5, 5]), throwsArgumentError);
    });

    test('an answer outside 1 to 5 is rejected', () {
      expect(() => Sus.score([5, 1, 5, 1, 5, 1, 5, 1, 5, 6]), throwsArgumentError);
      expect(() => Sus.score([0, 1, 5, 1, 5, 1, 5, 1, 5, 1]), throwsArgumentError);
    });

    test('there are exactly ten statements', () {
      expect(Sus.statements, hasLength(10));
    });

    test('the average of no responses is null', () {
      expect(Sus.average(const []), isNull);
    });

    test('the average is the mean of the scores', () {
      expect(Sus.average([response(60), response(80)]), 70);
    });

    test('68 is the line between below and above average', () {
      expect(Sus.isAboveAverage(68), isTrue);
      expect(Sus.isAboveAverage(67.9), isFalse);
    });
  });

  group('FeedbackRules', () {
    test('accepts a normal message', () {
      expect(FeedbackRules.validate('The timetable is clear.', 4), isNull);
      expect(FeedbackRules.validate('No rating needed.', null), isNull);
    });

    test('rejects an empty message', () {
      expect(FeedbackRules.validate('   ', null), isNotNull);
    });

    test('rejects a message that is too long', () {
      expect(
        FeedbackRules.validate('x' * (FeedbackRules.maxMessageLength + 1), null),
        isNotNull,
      );
    });

    test('rejects a rating outside 1 to 5', () {
      expect(FeedbackRules.validate('Fine', 0), isNotNull);
      expect(FeedbackRules.validate('Fine', 6), isNotNull);
    });
  });

  group('InMemoryFeedbackRepository', () {
    late InMemoryFeedbackRepository repo;

    setUp(() => repo = InMemoryFeedbackRepository());

    test('feedback is stored with the role only, newest first', () async {
      await repo.submitFeedback(
        role: UserRole.student,
        category: FeedbackCategory.bug,
        message: 'First',
      );
      await repo.submitFeedback(
        role: UserRole.lecturer,
        category: FeedbackCategory.idea,
        message: 'Second',
        rating: 5,
      );

      final entries = await repo.watchFeedback().first;
      expect(entries.map((e) => e.message), ['Second', 'First']);
      expect(entries.first.role, UserRole.lecturer);
      expect(entries.first.rating, 5);
    });

    test('invalid feedback is rejected', () async {
      expect(
        () => repo.submitFeedback(
          role: UserRole.student,
          category: FeedbackCategory.other,
          message: '  ',
        ),
        throwsArgumentError,
      );
    });

    test('a survey response keeps its score and reaches listeners live', () async {
      final seen = expectLater(
        repo.watchSus(),
        emitsThrough(predicate<List<SusResponse>>(
          (l) => l.length == 1 && l.first.score == 100,
        )),
      );

      await repo.submitSus(
        role: UserRole.student,
        answers: [5, 1, 5, 1, 5, 1, 5, 1, 5, 1],
      );

      await seen;
    });

    test('an incomplete survey is rejected', () async {
      expect(
        () => repo.submitSus(role: UserRole.student, answers: [5, 5]),
        throwsArgumentError,
      );
    });
  });
}
