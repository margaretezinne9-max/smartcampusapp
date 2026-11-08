import 'dart:async';

import 'package:smart_campus_portal/core/backend.dart';

/// Runs before every test file. Tests always use the in-memory demo backends,
/// whatever `kUseFirebase` is set to for the real app, because the tests have
/// no Firebase project to talk to.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  useFirebaseBackends = false;
  await testMain();
}
