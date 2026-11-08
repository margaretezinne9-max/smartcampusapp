import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/user_role.dart';
import '../domain/feedback_models.dart';
import '../domain/feedback_repository.dart';

/// Firestore collections `feedback` and `susResponses`. Any signed-in user may
/// add to them; only admins may read them (see firestore.rules).
class FirestoreFeedbackRepository implements FeedbackRepository {
  FirestoreFeedbackRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DateTime _time(Object? value) =>
      value is Timestamp ? value.toDate() : DateTime.now();

  @override
  Future<void> submitFeedback({
    required UserRole role,
    required FeedbackCategory category,
    required String message,
    int? rating,
  }) async {
    final problem = FeedbackRules.validate(message, rating);
    if (problem != null) throw ArgumentError(problem);
    await _db.collection('feedback').add({
      'role': role.name,
      'category': category.name,
      'message': message.trim(),
      if (rating != null) 'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> submitSus({
    required UserRole role,
    required List<int> answers,
  }) async {
    final score = Sus.score(answers);
    await _db.collection('susResponses').add({
      'role': role.name,
      'answers': answers,
      'score': score,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<FeedbackEntry>> watchFeedback() => _db
      .collection('feedback')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) {
          final m = d.data();
          return FeedbackEntry(
            id: d.id,
            role: UserRole.parse(m['role'] as String?),
            category: FeedbackCategory.parse(m['category'] as String?),
            message: m['message'] as String? ?? '',
            rating: (m['rating'] as num?)?.toInt(),
            createdAt: _time(m['createdAt']),
          );
        }).toList(),
      );

  @override
  Stream<List<SusResponse>> watchSus() => _db
      .collection('susResponses')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) {
          final m = d.data();
          return SusResponse(
            id: d.id,
            role: UserRole.parse(m['role'] as String?),
            answers: [
              for (final a in (m['answers'] as List<dynamic>? ?? const []))
                (a as num).toInt(),
            ],
            score: (m['score'] as num?)?.toDouble() ?? 0,
            createdAt: _time(m['createdAt']),
          );
        }).toList(),
      );
}
