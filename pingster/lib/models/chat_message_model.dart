import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, audio, image, video, file }

class ChatMessage {
  final String id;
  final String senderId;
  String content;
  final DateTime timestamp;
  bool isRead;
  final MessageType type;
  final String? replyTo;
  final Map<String, int> reactions;
  bool isEdited;
  DateTime? editTimestamp;
  bool isPinned;
  bool isSecret;
  DateTime? expirationTime;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.replyTo,
    Map<String, int>? reactions,
    this.isEdited = false,
    this.editTimestamp,
    this.isPinned = false,
    this.isSecret = false,
    this.expirationTime,
  }) : reactions = reactions ?? {};

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      type: MessageType.values[data['type'] ?? 0],
      replyTo: data['replyTo'],
      reactions: Map<String, int>.from(data['reactions'] ?? {}),
      isEdited: data['isEdited'] ?? false,
      editTimestamp: data['editTimestamp'] != null
          ? (data['editTimestamp'] as Timestamp).toDate()
          : null,
      isPinned: data['isPinned'] ?? false,
      isSecret: data['isSecret'] ?? false,
      expirationTime: data['expirationTime'] != null
          ? (data['expirationTime'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'type': type.index,
      'replyTo': replyTo,
      'reactions': reactions,
      'isEdited': isEdited,
      'editTimestamp':
          editTimestamp != null ? Timestamp.fromDate(editTimestamp!) : null,
      'isPinned': isPinned,
      'isSecret': isSecret,
      'expirationTime':
          expirationTime != null ? Timestamp.fromDate(expirationTime!) : null,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    String? replyTo,
    Map<String, int>? reactions,
    bool? isEdited,
    DateTime? editTimestamp,
    bool? isPinned,
    bool? isSecret,
    DateTime? expirationTime,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      editTimestamp: editTimestamp ?? this.editTimestamp,
      isPinned: isPinned ?? this.isPinned,
      isSecret: isSecret ?? this.isSecret,
      expirationTime: expirationTime ?? this.expirationTime,
    );
  }
}
