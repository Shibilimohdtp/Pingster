import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String? profilePicture;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.profilePicture,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      username: data['username'] ?? '',
      fullName: data['fullName'] ?? '',
      profilePicture: data['profilePicture'],
    );
  }
}
