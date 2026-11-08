import 'package:flutter/widgets.dart';

import '../../core/backend.dart';
import '../auth/domain/app_user.dart';
import 'data/firestore_chat_repository.dart';
import 'data/in_memory_chat_repository.dart';
import 'domain/chat_repository.dart';
import 'presentation/chat_rooms_page.dart';

/// Firestore when Firebase is on, the in-memory demo otherwise.
final ChatRepository chatRepository = useFirebaseBackends
    ? FirestoreChatRepository()
    : InMemoryChatRepository();

Widget buildChat(AppUser user) =>
    ChatRoomsPage(user: user, repository: chatRepository);
