import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';
import 'dart:io';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<UserCredential> signUpWithEmail(
      String email, String password, String username, String fullName) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'fullName': fullName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Future<UserCredential> signInWithGoogle() async {
  //   // TODO: Implement Google Sign-In
  // }

  // Future<UserCredential> signInWithFacebook() async {
  //   // TODO: Implement Facebook Sign-In
  // }

  // Future<UserCredential> signInWithApple() async {
  //   // TODO: Implement Apple Sign-In
  // }

  Future<List<UserModel>> searchUsers(String query) async {
    QuerySnapshot userSnapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: query + 'z')
        .get();

    return userSnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  Stream<List<Chat>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
    });
  }

  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  Stream<bool> getTypingStatus(String chatId, String userId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['isTyping'] ?? false);
  }

  Future<void> setTypingStatus(
      String chatId, String userId, bool isTyping) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(userId)
        .set({'isTyping': isTyping}, SetOptions(merge: true));
  }

  Future<void> addReaction(
      String chatId, String messageId, String emoji) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$emoji': FieldValue.increment(1),
    });
  }

  Future<void> sendMessage(String chatId, ChatMessage message) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message.content,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> getChatParticipants(String chatId) async {
    DocumentSnapshot chatDoc =
        await _firestore.collection('chats').doc(chatId).get();
    return List<String>.from(chatDoc['participants']);
  }

  Future<void> incrementUnreadCount(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$userId': FieldValue.increment(1),
    });
  }

  Future<String> createChat(List<String> participants) async {
    DocumentReference chatRef = await _firestore.collection('chats').add({
      'participants': participants,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': Map.fromIterable(participants, value: (_) => 0),
    });
    return chatRef.id;
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$userId': 0,
    });

    QuerySnapshot unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    WriteBatch batch = _firestore.batch();
    unreadMessages.docs.forEach((doc) {
      batch.update(doc.reference, {'isRead': true});
    });
    await batch.commit();
  }

  Future<String> getUserFullName(String userId) async {
    print('Debug: Fetching full name for user $userId');
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    String fullName = userDoc.get('fullName') ?? '';
    print('Debug: Full name for user $userId is $fullName');
    return fullName;
  }

  Future<String?> getUserProfilePicture(String userId) async {
    print('Debug: Fetching profile picture for user $userId');
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    String? profilePicture = userDoc.get('profilePicture') as String?;
    print('Debug: Profile picture for user $userId is $profilePicture');
    return profilePicture;
  }

  Future<String> uploadFile(File file) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference =
        FirebaseStorage.instance.ref().child('chat_files/$fileName');
    UploadTask uploadTask = reference.putFile(file);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> updateMessage(String chatId, ChatMessage message) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .update(message.toMap());
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> setChatFolder(String chatId, String folder) async {
    await _firestore.collection('chats').doc(chatId).update({'folder': folder});
  }

  Future<String?> getChatTheme(String chatId) async {
    try {
      DocumentSnapshot chatDoc =
          await _firestore.collection('chats').doc(chatId).get();

      if (chatDoc.exists) {
        Map<String, dynamic> data = chatDoc.data() as Map<String, dynamic>;
        return data['theme'] as String?;
      } else {
        print('Chat document does not exist');
        return null;
      }
    } catch (e) {
      print('Error getting chat theme: $e');
      return null;
    }
  }

  Future<List<ChatMessage>> getPinnedMessages(String chatId) async {
    try {
      QuerySnapshot pinnedMessagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isPinned', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      return pinnedMessagesSnapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting pinned messages: $e');
      return [];
    }
  }

  Future<void> setChatTheme(String chatId, String? theme) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({'theme': theme});
    } catch (e) {
      print('Error setting chat theme: $e');
    }
  }

  Future<void> pinMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isPinned': true});
    } catch (e) {
      print('Error pinning message: $e');
    }
  }

  Future<void> unpinMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isPinned': false});
    } catch (e) {
      print('Error unpinning message: $e');
    }
  }

  Future<UserModel> getUserById(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    return UserModel.fromFirestore(userDoc);
  }

  Future<UserModel> updateUserProfile(String userId,
      {String? fullName, String? profilePicture}) async {
    Map<String, dynamic> updateData = {};
    if (fullName != null) updateData['fullName'] = fullName;
    if (profilePicture != null) updateData['profilePicture'] = profilePicture;

    await _firestore.collection('users').doc(userId).update(updateData);

    // Fetch and return the updated user data
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    return UserModel.fromFirestore(userDoc);
  }

  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    String fileName = 'profile_$userId.jpg';
    Reference storageRef = _storage.ref().child('profile_pictures/$fileName');
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    // Update user document in Firestore with the new profile picture URL
    await _firestore.collection('users').doc(userId).update({
      'profilePicture': downloadUrl,
    });

    return downloadUrl;
  }

  Future<bool> isUserBlocked(String chatId, String userId) async {
    try {
      DocumentSnapshot chatDoc =
          await _firestore.collection('chats').doc(chatId).get();
      List<String> blockedUsers =
          List<String>.from(chatDoc['blockedUsers'] ?? []);
      return blockedUsers.contains(userId);
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false;
    }
  }

  Future<void> blockUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'blockedUsers': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print('Error blocking user: $e');
      throw e;
    }
  }

  Future<void> unblockUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'blockedUsers': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      print('Error unblocking user: $e');
      throw e;
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages in the chat
      QuerySnapshot messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the chat document
      batch.delete(_firestore.collection('chats').doc(chatId));

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error deleting chat: $e');
      throw e;
    }
  }
}
