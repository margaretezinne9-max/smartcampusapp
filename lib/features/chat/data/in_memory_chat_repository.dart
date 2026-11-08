import '../../../core/live_value.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../../campus/domain/demo_data.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';

/// Demo chat that needs no internet. Uses the same demo courses, lecturer and
/// students as the campus demo data, so the demo accounts can talk to each
/// other (until the app restarts).
class InMemoryChatRepository implements ChatRepository {
  InMemoryChatRepository() {
    final now = DateTime.now();
    final data = DemoData.build(
      lecturerId: 'hcu-lecturer-001',
      lecturerName: 'Demo Lecturer',
      students: const [
        DemoStudent('hcu-student-001', 'Demo Student'),
        DemoStudent('hcu-courseRep-001', 'Demo Course Rep'),
      ],
      now: now,
    );

    _enrollments = data.enrollments
        .map((e) => (studentId: e.studentId, courseCode: e.courseCode))
        .toList();

    for (final s in data.slots) {
      final room = ChatRoom(
        id: ChatRoom.idFor(s.courseCode),
        courseCode: s.courseCode,
        courseTitle: s.courseTitle,
        lecturerId: s.lecturerId,
        lecturerName: s.lecturerName,
      );
      _rooms.add(room);
      _messages[room.id] = LiveValue([
        ChatMessage(
          id: 'welcome-${room.id}',
          roomId: room.id,
          senderId: room.lecturerId,
          senderName: room.lecturerName,
          senderRole: UserRole.lecturer,
          text:
              'Welcome to ${room.courseCode}. Post your questions here and '
              'I will reply.',
          sentAt: now.subtract(const Duration(days: 1)),
        ),
      ]);
    }
  }

  final List<ChatRoom> _rooms = [];
  late final List<({String studentId, String courseCode})> _enrollments;
  final Map<String, LiveValue<List<ChatMessage>>> _messages = {};
  int _counter = 0;

  bool _isMember(ChatRoom room, AppUser user) {
    switch (user.role) {
      case UserRole.lecturer:
        return room.lecturerId == user.id;
      case UserRole.student:
      case UserRole.courseRep:
        return _enrollments.any(
          (e) => e.studentId == user.id && e.courseCode == room.courseCode,
        );
      case UserRole.admin:
        return true;
      case UserRole.bursar:
      case UserRole.aspirant:
        return false;
    }
  }

  @override
  Stream<List<ChatRoom>> watchRooms(AppUser user) =>
      Stream.value(_rooms.where((r) => _isMember(r, user)).toList());

  @override
  Stream<List<ChatMessage>> watchMessages(String roomId) =>
      (_messages[roomId] ??= LiveValue(const <ChatMessage>[])).watch();

  @override
  Future<void> sendMessage({
    required String roomId,
    required AppUser sender,
    required String text,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty || clean.length > ChatRules.maxMessageLength) {
      throw ArgumentError(
        'A message must be 1 to ${ChatRules.maxMessageLength} characters.',
      );
    }
    final room = _rooms.where((r) => r.id == roomId).firstOrNull;
    if (room == null || !_isMember(room, sender)) {
      throw StateError('You are not a member of this chat.');
    }

    _counter++;
    final live = _messages[roomId] ??= LiveValue(const <ChatMessage>[]);
    live.value = [
      ...live.value,
      ChatMessage(
        id: 'local-$_counter',
        roomId: roomId,
        senderId: sender.id,
        senderName: sender.name,
        senderRole: sender.role,
        text: clean,
        sentAt: DateTime.now(),
      ),
    ];
  }
}
