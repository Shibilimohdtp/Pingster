import 'package:flutter/foundation.dart';
import 'package:pingster/models/user_model.dart';
import '../services/firebase_service.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';
import 'dart:io';

class ChatProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  Stream<List<Chat>> getUserChats(String userId) {
    print('Debug: Getting user chats for $userId');
    return _firebaseService.getUserChats(userId);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    print('Debug: Searching users with query: $query');
    return await _firebaseService.searchUsers(query);
  }

  Future<String> createNewChat(String currentUserId, String otherUserId) async {
    // This method should create a new chat document in Firestore and return its ID
    return await _firebaseService.createChat([currentUserId, otherUserId]);
  }

  Future<List<Chat>> filterAndEnrichChats(
      List<Chat> chats, String currentUserId, String searchQuery) async {
    print('Debug: Filtering and enriching ${chats.length} chats');
    print('Debug: Current user ID: $currentUserId');
    print('Debug: Search query: $searchQuery');

    List<Chat> enrichedChats = [];
    for (var chat in chats) {
      print('Debug: Processing chat ${chat.id}');
      String otherUserId =
          chat.participants.firstWhere((id) => id != currentUserId);
      print('Debug: Other user ID: $otherUserId');

      String otherUserName =
          await _firebaseService.getUserFullName(otherUserId);
      String? otherUserProfilePicture =
          await _firebaseService.getUserProfilePicture(otherUserId);

      print('Debug: Other user name: $otherUserName');
      print('Debug: Other user profile picture: $otherUserProfilePicture');

      if (searchQuery.isEmpty ||
          otherUserName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          otherUserId.toLowerCase().contains(searchQuery.toLowerCase())) {
        print('Debug: Chat matches search criteria');
        enrichedChats.add(chat.copyWith(
          otherUserName: otherUserName,
          otherUserProfilePicture: otherUserProfilePicture,
        ));
      } else {
        print('Debug: Chat does not match search criteria');
      }
    }

    print('Debug: Enriched chats count: ${enrichedChats.length}');
    return enrichedChats;
  }

  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firebaseService.getChatMessages(chatId);
  }

  Future<void> sendMessage(String chatId, ChatMessage message) async {
    await _firebaseService.sendMessage(chatId, message);
  }

  Future<String> createChat(List<String> participants) async {
    return await _firebaseService.createChat(participants);
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    await _firebaseService.markMessagesAsRead(chatId, userId);
  }

  Future<String> uploadFile(File file) async {
    return await _firebaseService.uploadFile(file);
  }
}
