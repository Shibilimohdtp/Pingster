import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  String? otherUserName;
  String? otherUserProfilePicture;

  Chat({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.otherUserName,
    this.otherUserProfilePicture,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
    };
  }

  Chat copyWith({
    String? otherUserName,
    String? otherUserProfilePicture,
  }) {
    return Chat(
      id: this.id,
      participants: this.participants,
      lastMessage: this.lastMessage,
      lastMessageTime: this.lastMessageTime,
      unreadCount: this.unreadCount,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserProfilePicture:
          otherUserProfilePicture ?? this.otherUserProfilePicture,
    );
  }
}
