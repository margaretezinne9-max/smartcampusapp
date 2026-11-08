import '../../auth/domain/user_role.dart';
import 'feedback_models.dart';

abstract interface class FeedbackRepository {
  /// Throws [ArgumentError] when [FeedbackRules.validate] fails.
  Future<void> submitFeedback({
    required UserRole role,
    required FeedbackCategory category,
    required String message,
    int? rating,
  });

  /// Throws [ArgumentError] unless there are 10 answers of 1 to 5.
  Future<void> submitSus({required UserRole role, required List<int> answers});

  /// Admin only, newest first.
  Stream<List<FeedbackEntry>> watchFeedback();
  Stream<List<SusResponse>> watchSus();
}
