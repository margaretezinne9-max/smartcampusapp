import 'package:flutter/material.dart';

import '../../../core/l10n/translations.dart';
import '../../../core/widgets/stream_view.dart';
import '../../auth/domain/app_user.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';
import 'chat_room_page.dart';

/// The course chats a user belongs to.
class ChatRoomsPage extends StatelessWidget {
  const ChatRoomsPage({
    super.key,
    required this.user,
    required this.repository,
  });

  final AppUser user;
  final ChatRepository repository;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return StreamView<List<ChatRoom>>(
      open: () => repository.watchRooms(user),
      builder: (context, rooms) {
        final sorted = [...rooms]
          ..sort((a, b) => a.courseCode.compareTo(b.courseCode));

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(context.tr('Course chats'), style: text.headlineSmall),
                const SizedBox(height: 16),
                if (sorted.isEmpty)
                  Text(context.tr('You are not part of any course chat yet.')),
                for (final room in sorted)
                  Card.outlined(
                    child: ListTile(
                      leading: const Icon(Icons.forum_outlined),
                      title: Text('${room.courseCode} - ${room.courseTitle}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatRoomPage(
                            room: room,
                            user: user,
                            repository: repository,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
