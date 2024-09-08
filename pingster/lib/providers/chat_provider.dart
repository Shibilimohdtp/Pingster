import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'package:collection/collection.dart';
import '../services/encryption_service.dart';
import 'dart:io';

class ChatProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final EncryptionService _encryptionService = EncryptionService();

  Stream<List<Chat>> getUserChats(String userId) {
    return _firebaseService.getUserChats(userId).asyncMap((chats) async {
      List<Chat> enrichedChats = [];
      for (var chat in chats) {
        enrichedChats.add(await _enrichChat(chat, userId));
      }
      return enrichedChats;
    });
  }

  Future<Chat> _enrichChat(Chat chat, String currentUserId) async {
    String otherUserId =
        chat.participants.firstWhere((id) => id != currentUserId);
    UserModel otherUser = await _firebaseService.getUserById(otherUserId);
    String decryptedLastMessage =
        await _encryptionService.decrypt(chat.lastMessage, chat.id);

    return chat.copyWith(
      otherUserName: otherUser.fullName,
      otherUserProfilePicture: otherUser.profilePicture,
      lastMessage: decryptedLastMessage,
    );
  }

  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firebaseService.getChatMessages(chatId).asyncMap((messages) async {
      List<ChatMessage> decryptedMessages = [];
      for (var message in messages) {
        String decryptedContent =
            await _encryptionService.decrypt(message.content, chatId);
        decryptedMessages.add(message.copyWith(content: decryptedContent));
      }
      return decryptedMessages;
    });
  }

  Future<void> sendMessage(String chatId, ChatMessage message) async {
    String encryptedContent =
        await _encryptionService.encrypt(message.content, chatId);
    ChatMessage encryptedMessage = message.copyWith(content: encryptedContent);
    await _firebaseService.sendMessage(chatId, encryptedMessage);
  }

  Future<void> editMessage(
      String chatId, ChatMessage message, String newContent) async {
    String encryptedContent =
        await _encryptionService.encrypt(newContent, chatId);
    ChatMessage updatedMessage = message.copyWith(
      content: encryptedContent,
      isEdited: true,
      editTimestamp: DateTime.now(),
    );
    await _firebaseService.updateMessage(chatId, updatedMessage);
    notifyListeners();
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firebaseService.deleteMessage(chatId, messageId);
    notifyListeners();
  }

  Future<void> pinMessage(String chatId, String messageId) async {
    await _firebaseService.pinMessage(chatId, messageId);
    notifyListeners();
  }

  Future<void> unpinMessage(String chatId, String messageId) async {
    await _firebaseService.unpinMessage(chatId, messageId);
    notifyListeners();
  }

  Future<List<ChatMessage>> getPinnedMessages(String chatId) async {
    List<ChatMessage> pinnedMessages =
        await _firebaseService.getPinnedMessages(chatId);
    return Future.wait(pinnedMessages.map((message) async {
      String decryptedContent =
          await _encryptionService.decrypt(message.content, chatId);
      return message.copyWith(content: decryptedContent);
    }));
  }

  Future<void> setChatFolder(String chatId, String? folder) async {
    if (folder != null) {
      await _firebaseService.setChatFolder(chatId, folder);
      notifyListeners();
    }
  }

  Future<void> setChatTheme(String chatId, String? theme) async {
    await _firebaseService.setChatTheme(chatId, theme);
    notifyListeners();
  }

  Future<String?> getChatTheme(String chatId) async {
    return await _firebaseService.getChatTheme(chatId);
  }

  Future<void> sendSecretMessage(
      String chatId, ChatMessage message, Duration expirationDuration) async {
    String encryptedContent =
        await _encryptionService.encrypt(message.content, chatId);
    ChatMessage secretMessage = message.copyWith(
      content: encryptedContent,
      isSecret: true,
      expirationTime: DateTime.now().add(expirationDuration),
    );
    await _firebaseService.sendMessage(chatId, secretMessage);
  }

  Future<String> createNewChat(String currentUserId, String otherUserId) async {
    List<Chat> existingChats = await getUserChats(currentUserId).first;
    Chat? existingChat = existingChats.firstWhereOrNull(
      (chat) => chat.participants.contains(otherUserId),
    );

    if (existingChat != null) {
      return existingChat.id;
    }

    return await _firebaseService.createChat([currentUserId, otherUserId]);
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    await _firebaseService.markMessagesAsRead(chatId, userId);
  }

  Future<String> uploadFile(File file) async {
    return await _firebaseService.uploadFile(file);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    return await _firebaseService.searchUsers(query);
  }

  Stream<bool> getTypingStatus(String chatId, String userId) {
    return _firebaseService.getTypingStatus(chatId, userId);
  }

  Future<void> setTypingStatus(
      String chatId, String userId, bool isTyping) async {
    await _firebaseService.setTypingStatus(chatId, userId, isTyping);
  }

  Future<void> addReaction(
      String chatId, String messageId, String emoji) async {
    await _firebaseService.addReaction(chatId, messageId, emoji);
    notifyListeners();
  }

  Future<bool> isUserBlocked(String chatId, String userId) async {
    try {
      return await _firebaseService.isUserBlocked(chatId, userId);
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false;
    }
  }

  Future<void> blockUser(String chatId, String userId) async {
    try {
      await _firebaseService.blockUser(chatId, userId);
      notifyListeners();
    } catch (e) {
      print('Error blocking user: $e');
      throw e;
    }
  }

  Future<void> unblockUser(String chatId, String userId) async {
    try {
      await _firebaseService.unblockUser(chatId, userId);
      notifyListeners();
    } catch (e) {
      print('Error unblocking user: $e');
      throw e;
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _firebaseService.deleteChat(chatId);
      notifyListeners();
    } catch (e) {
      print('Error deleting chat: $e');
      throw e;
    }
  }
}
