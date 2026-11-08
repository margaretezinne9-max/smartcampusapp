import 'package:flutter/widgets.dart';

import '../../core/backend.dart';
import '../auth/domain/app_user.dart';
import 'data/firestore_feedback_repository.dart';
import 'data/in_memory_feedback_repository.dart';
import 'domain/feedback_repository.dart';
import 'presentation/feedback_admin_page.dart';
import 'presentation/feedback_page.dart';

/// Firestore when Firebase is on, the in-memory demo otherwise.
final FeedbackRepository feedbackRepository = useFirebaseBackends
    ? FirestoreFeedbackRepository()
    : InMemoryFeedbackRepository();

Widget buildFeedback(AppUser user) =>
    FeedbackPage(user: user, repository: feedbackRepository);

Widget buildFeedbackAdmin(AppUser user) =>
    FeedbackAdminPage(repository: feedbackRepository);
