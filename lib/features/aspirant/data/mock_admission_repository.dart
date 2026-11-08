import '../domain/admission_repository.dart';
import '../domain/application_models.dart';

/// In-memory demo. To let you see every stage in a presentation, a submitted
/// application moves to "Under review" after 15s and "Admitted" after 40s.
/// In production, an administrator or admissions officer changes the status.
class MockAdmissionRepository implements AdmissionRepository {
  final Map<String, Application> _store = {};

  @override
  Future<Application> load(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _advance(_store[userId] ?? const Application());
  }

  @override
  Future<Application> saveDraft(String userId, Application application) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _store[userId] = application;
  }

  @override
  Future<Application> submit(String userId, Application application) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!application.isComplete) {
      throw StateError('Application is incomplete.');
    }
    return _store[userId] = application.copyWith(
      status: ApplicationStatus.submitted,
      submittedAt: DateTime.now(),
    );
  }

  Application _advance(Application a) {
    final sent = a.submittedAt;
    if (a.status == ApplicationStatus.draft || sent == null) return a;
    final age = DateTime.now().difference(sent);
    final status = age > const Duration(seconds: 40)
        ? ApplicationStatus.admitted
        : age > const Duration(seconds: 15)
        ? ApplicationStatus.underReview
        : ApplicationStatus.submitted;
    return a.copyWith(status: status);
  }
}
