import 'package:flutter/widgets.dart';

import '../../core/backend.dart';
import '../auth/domain/app_user.dart';
import 'data/gemini_assistant_service.dart';
import 'data/offline_assistant_service.dart';
import 'domain/assistant_service.dart';
import 'presentation/assistant_controller.dart';
import 'presentation/assistant_page.dart';

// Gemini when Firebase is on, the offline demo otherwise. Created on first
// use, after Firebase is initialised.
AssistantService _createService() =>
    useFirebaseBackends ? GeminiAssistantService() : OfflineAssistantService();

// One conversation per signed-in user.
final Map<String, AssistantController> _controllers = {};

Widget buildAssistant(AppUser user) => AssistantPage(
  controller: _controllers.putIfAbsent(
    user.id,
    () => AssistantController(_createService()),
  ),
);
