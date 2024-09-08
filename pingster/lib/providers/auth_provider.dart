import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _user;

  UserModel? get user => _user;

  AuthProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    User? firebaseUser = await _firebaseService.getCurrentUser();
    if (firebaseUser != null) {
      _user = await _firebaseService.getUserById(firebaseUser.uid);
      notifyListeners();
    }
  }

  Future<bool> isUserLoggedIn() async {
    if (_user != null) return true;
    User? firebaseUser = await _firebaseService.getCurrentUser();
    if (firebaseUser != null) {
      _user = await _firebaseService.getUserById(firebaseUser.uid);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> signUpWithEmail(
      String email, String password, String username, String fullName) async {
    try {
      UserCredential userCredential = await _firebaseService.signUpWithEmail(
          email, password, username, fullName);
      _user = await _firebaseService.getUserById(userCredential.user!.uid);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseService.signInWithEmail(email, password);
      _user = await _firebaseService.getUserById(userCredential.user!.uid);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile({String? fullName, File? imageFile}) async {
    try {
      if (_user != null) {
        String? profilePictureUrl;
        if (imageFile != null) {
          profilePictureUrl =
              await _firebaseService.uploadProfilePicture(_user!.id, imageFile);
        }
        _user = await _firebaseService.updateUserProfile(
          _user!.id,
          fullName: fullName,
          profilePicture: profilePictureUrl,
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseService.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  // Future<void> signInWithGoogle() async {
  //   // TODO: Implement Google Sign-In
  // }

  // Future<void> signInWithFacebook() async {
  //   // TODO: Implement Facebook Sign-In
  // }

  // Future<void> signInWithApple() async {
  //   // TODO: Implement Apple Sign-In
  // }
}
