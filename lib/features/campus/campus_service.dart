import '../../core/backend.dart';
import 'data/firestore_campus_repository.dart';
import 'data/in_memory_campus_repository.dart';
import 'domain/campus_repository.dart';

/// The one repository the campus screens use. Top-level variables are created
/// on first use, so Firebase is already initialised when it is built.
final CampusRepository campusRepository = useFirebaseBackends
    ? FirestoreCampusRepository()
    : InMemoryCampusRepository();
