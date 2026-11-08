import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/widgets/stream_view.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';

/// One course chat. New messages appear live for everyone in the room.
class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({
    super.key,
    required this.room,
    required this.user,
    required this.repository,
  });

  final ChatRoom room;
  final AppUser user;
  final ChatRepository repository;

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final failed = context.tr('Could not send the message.');
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await widget.repository.sendMessage(
        roomId: widget.room.id,
        sender: widget.user,
        text: text,
      );
      _input.clear();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.room.courseCode} - ${widget.room.courseTitle}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Expanded(
                child: StreamView<List<ChatMessage>>(
                  open: () => widget.repository.watchMessages(widget.room.id),
                  builder: (context, messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(context.tr('No messages yet. Say hello!')),
                      );
                    }
                    final newestFirst = messages.reversed.toList();
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: newestFirst.length,
                      itemBuilder: (context, i) => _MessageBubble(
                        message: newestFirst[i],
                        mine: newestFirst[i].senderId == widget.user.id,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: ChatRules.maxMessageLength,
                        decoration: InputDecoration(
                          hintText: context.tr('Write a message'),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: context.tr('Send'),
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isLecturer = message.senderRole == UserRole.lecturer;
    final time = formatClock(message.sentAt.hour * 60 + message.sentAt.minute);
    final foreground = mine ? scheme.onPrimaryContainer : scheme.onSurface;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(
                isLecturer
                    ? '${message.senderName} (${context.tr('Lecturer')})'
                    : message.senderName,
                style: text.labelMedium?.copyWith(color: scheme.primary),
              ),
            Text(message.text, style: TextStyle(color: foreground)),
            const SizedBox(height: 2),
            Text(time, style: text.labelSmall?.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }
}
