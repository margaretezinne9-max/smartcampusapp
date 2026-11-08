import '../../auth/domain/app_user.dart';
import 'chat_models.dart';

/// Course chats between a lecturer and the students enrolled in the course.
/// A student sees only the courses they are enrolled in; a lecturer only the
/// courses they teach.
abstract interface class ChatRepository {
  Stream<List<ChatRoom>> watchRooms(AppUser user);

  /// Oldest message first.
  Stream<List<ChatMessage>> watchMessages(String roomId);

  /// Throws [ArgumentError] for empty or too long text, [StateError] when
  /// [sender] is not a member of the room.
  Future<void> sendMessage({
    required String roomId,
    required AppUser sender,
    required String text,
  });
}
