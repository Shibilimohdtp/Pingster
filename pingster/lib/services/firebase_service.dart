import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pingster/models/user_model.dart';
import '../models/chat_model.dart';
import '../models/chat_message_model.dart';
import 'dart:io';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    print('Debug: Searching users with query: $query');
    QuerySnapshot userSnapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: query + 'z')
        .get();

    print('Debug: Found ${userSnapshot.docs.length} users matching the query');
    return userSnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  Stream<List<Chat>> getUserChats(String userId) {
    print('Debug: Fetching chats for user $userId');
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      print('Debug: Received ${snapshot.docs.length} chats');
      return snapshot.docs.map((doc) {
        print('Debug: Processing chat ${doc.id}');
        return Chat.fromFirestore(doc);
      }).toList();
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

  Future<void> sendMessage(String chatId, ChatMessage message) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message.content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount.${message.senderId}': FieldValue.increment(1),
    });
  }

  Future<String> createChat(List<String> participants) async {
    // Create a new chat document
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
}
