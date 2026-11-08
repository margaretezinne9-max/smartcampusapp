import 'config.dart';

/// Whether the repositories (campus data, chat, feedback, AI assistant) use
/// Firebase. It starts as [kUseFirebase]. The tests switch it off in
/// test/flutter_test_config.dart, so `flutter test` always runs on the
/// in-memory demo backends, even when Firebase is switched on for the app.
bool useFirebaseBackends = kUseFirebase;
