import 'application_models.dart';

/// Implement with your real API. The aspirant screens only use this.
abstract interface class AdmissionRepository {
  Future<Application> load(String userId);
  Future<Application> saveDraft(String userId, Application application);
  Future<Application> submit(String userId, Application application);
}
