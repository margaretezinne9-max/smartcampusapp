import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';

/// Firestore chat.
///   chatRooms/{roomId}                     course, lecturerId (created by the admin seed)
///   chatRooms/{roomId}/messages/{id}       senderId, senderName, senderRole, text, sentAt
/// A student's rooms come from their enrolments, a lecturer's from chatRooms.
/// Who may read or post is enforced by firestore.rules.
class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  ChatRoom _roomFromDoc(String id, Map<String, dynamic> m) => ChatRoom(
    id: id,
    courseCode: m['courseCode'] as String? ?? '',
    courseTitle: m['courseTitle'] as String? ?? '',
    lecturerId: m['lecturerId'] as String? ?? '',
    lecturerName: m['lecturerName'] as String? ?? '',
  );

  @override
  Stream<List<ChatRoom>> watchRooms(AppUser user) {
    if (user.role == UserRole.lecturer) {
      return _db
          .collection('chatRooms')
          .where('lecturerId', isEqualTo: user.id)
          .snapshots()
          .map((s) => s.docs.map((d) => _roomFromDoc(d.id, d.data())).toList());
    }
    if (user.role == UserRole.student || user.role == UserRole.courseRep) {
      return _db
          .collection('enrollments')
          .where('studentId', isEqualTo: user.id)
          .snapshots()
          .map(
            (s) => s.docs.map((d) {
              final m = d.data();
              final code = m['courseCode'] as String? ?? '';
              return ChatRoom(
                id: ChatRoom.idFor(code),
                courseCode: code,
                courseTitle: m['courseTitle'] as String? ?? '',
                lecturerId: m['lecturerId'] as String? ?? '',
              );
            }).toList(),
          );
    }
    if (user.role == UserRole.admin) {
      return _db
          .collection('chatRooms')
          .snapshots()
          .map((s) => s.docs.map((d) => _roomFromDoc(d.id, d.data())).toList());
    }
    return Stream.value(const <ChatRoom>[]);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String roomId) => _db
      .collection('chatRooms')
      .doc(roomId)
      .collection('messages')
      .orderBy('sentAt')
      .snapshots()
      .map(
        (s) => s.docs.map((d) {
          final m = d.data();
          final sentAt = m['sentAt'];
          return ChatMessage(
            id: d.id,
            roomId: roomId,
            senderId: m['senderId'] as String? ?? '',
            senderName: m['senderName'] as String? ?? '',
            senderRole: UserRole.parse(m['senderRole'] as String?),
            text: m['text'] as String? ?? '',
            // A message just sent has no server time yet; show it as "now".
            sentAt: sentAt is Timestamp ? sentAt.toDate() : DateTime.now(),
          );
        }).toList(),
      );

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
    await _db.collection('chatRooms').doc(roomId).collection('messages').add({
      'senderId': sender.id,
      'senderName': sender.name,
      'senderRole': sender.role.name,
      'text': clean,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }
}
