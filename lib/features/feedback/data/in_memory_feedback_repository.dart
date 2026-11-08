import '../../../core/live_value.dart';
import '../../auth/domain/user_role.dart';
import '../domain/feedback_models.dart';
import '../domain/feedback_repository.dart';

/// Demo feedback box that needs no internet (data lasts until the app restarts).
class InMemoryFeedbackRepository implements FeedbackRepository {
  final _feedback = LiveValue<List<FeedbackEntry>>(const []);
  final _sus = LiveValue<List<SusResponse>>(const []);
  int _counter = 0;

  @override
  Future<void> submitFeedback({
    required UserRole role,
    required FeedbackCategory category,
    required String message,
    int? rating,
  }) async {
    final problem = FeedbackRules.validate(message, rating);
    if (problem != null) throw ArgumentError(problem);
    _counter++;
    _feedback.value = [
      FeedbackEntry(
        id: 'local-fb-$_counter',
        role: role,
        category: category,
        message: message.trim(),
        rating: rating,
        createdAt: DateTime.now(),
      ),
      ..._feedback.value,
    ];
  }

  @override
  Future<void> submitSus({
    required UserRole role,
    required List<int> answers,
  }) async {
    final score = Sus.score(answers);
    _counter++;
    _sus.value = [
      SusResponse(
        id: 'local-sus-$_counter',
        role: role,
        answers: List.unmodifiable(answers),
        score: score,
        createdAt: DateTime.now(),
      ),
      ..._sus.value,
    ];
  }

  @override
  Stream<List<FeedbackEntry>> watchFeedback() => _feedback.watch();

  @override
  Stream<List<SusResponse>> watchSus() => _sus.watch();
}
