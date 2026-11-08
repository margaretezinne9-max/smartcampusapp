import '../../auth/domain/user_role.dart';

/// One chat room per course. Its id is the course code without spaces
/// (for example "CSC401"), which is also how enrolment ids end, so Firestore
/// rules can check membership.
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.lecturerId,
    this.lecturerName = '',
  });

  final String id;
  final String courseCode;
  final String courseTitle;
  final String lecturerId;
  final String lecturerName;

  static String idFor(String courseCode) => courseCode.replaceAll(' ', '');
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final String text;
  final DateTime sentAt;
}

abstract final class ChatRules {
  static const maxMessageLength = 1000;
}
