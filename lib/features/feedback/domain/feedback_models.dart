import '../../auth/domain/user_role.dart';

enum FeedbackCategory {
  bug,
  idea,
  other;

  static FeedbackCategory parse(String? value) => FeedbackCategory.values
      .firstWhere((c) => c.name == value, orElse: () => FeedbackCategory.other);
}

/// A message from a user to the admins. Only the role is stored, not the
/// person, so feedback stays anonymous.
class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.role,
    required this.category,
    required this.message,
    required this.createdAt,
    this.rating,
  });

  final String id;
  final UserRole role;
  final FeedbackCategory category;
  final String message;
  final DateTime createdAt;

  /// 1 to 5 stars, optional.
  final int? rating;
}

/// One completed System Usability Scale questionnaire (anonymous, by role).
class SusResponse {
  const SusResponse({
    required this.id,
    required this.role,
    required this.answers,
    required this.score,
    required this.createdAt,
  });

  final String id;
  final UserRole role;

  /// Ten answers, each 1 (strongly disagree) to 5 (strongly agree).
  final List<int> answers;

  /// 0 to 100.
  final double score;
  final DateTime createdAt;
}

abstract final class FeedbackRules {
  static const maxMessageLength = 1000;

  /// Null when valid, otherwise an English message key.
  static String? validate(String message, int? rating) {
    final text = message.trim();
    if (text.isEmpty) return 'Please write your feedback.';
    if (text.length > maxMessageLength) return 'Your feedback is too long.';
    if (rating != null && (rating < 1 || rating > 5)) {
      return 'The rating must be between 1 and 5.';
    }
    return null;
  }
}

/// The System Usability Scale (Brooke, 1996): 10 statements answered 1 to 5.
abstract final class Sus {
  static const statements = [
    'I think that I would like to use this system frequently.',
    'I found the system unnecessarily complex.',
    'I thought the system was easy to use.',
    'I think that I would need the support of a technical person to be able to use this system.',
    'I found the various functions in this system were well integrated.',
    'I thought there was too much inconsistency in this system.',
    'I would imagine that most people would learn to use this system very quickly.',
    'I found the system very cumbersome to use.',
    'I felt very confident using the system.',
    'I needed to learn a lot of things before I could get going with this system.',
  ];

  /// 0 to 100. Odd-numbered statements (positive) score answer - 1, even
  /// ones (negative) score 5 - answer; the total is multiplied by 2.5.
  static double score(List<int> answers) {
    if (answers.length != statements.length) {
      throw ArgumentError('SUS needs exactly ${statements.length} answers.');
    }
    var total = 0;
    for (var i = 0; i < answers.length; i++) {
      final a = answers[i];
      if (a < 1 || a > 5) throw ArgumentError('Answers must be 1 to 5.');
      total += i.isEven ? a - 1 : 5 - a;
    }
    return total * 2.5;
  }

  /// Average score of the given responses, or null when there are none.
  static double? average(Iterable<SusResponse> responses) {
    if (responses.isEmpty) return null;
    return responses.map((r) => r.score).reduce((a, b) => a + b) /
        responses.length;
  }

  /// 68 is the commonly cited average SUS score.
  static bool isAboveAverage(double score) => score >= 68;
}
