import 'package:flutter/widgets.dart';

import '../auth/domain/app_user.dart';
import 'data/mock_admission_repository.dart';
import 'domain/admission_repository.dart';
import 'presentation/admission_status_page.dart';
import 'presentation/application_controller.dart';
import 'presentation/application_page.dart';

// Swap MockAdmissionRepository for your real API implementation here.
final AdmissionRepository _repository = MockAdmissionRepository();

// One controller per signed-in aspirant, shared by both tabs.
final Map<String, ApplicationController> _controllers = {};

ApplicationController _controllerFor(AppUser user) => _controllers.putIfAbsent(
  user.id,
  () => ApplicationController(_repository, user.id)..load(),
);

Widget buildAspirantApplication(AppUser user) =>
    ApplicationPage(controller: _controllerFor(user));

Widget buildAspirantAdmission(AppUser user) =>
    AdmissionStatusPage(controller: _controllerFor(user));
