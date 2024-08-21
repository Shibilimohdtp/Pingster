import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  User? _user;

  User? get user => _user;

  AuthProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _user = await _firebaseService.getCurrentUser();
    notifyListeners();
  }

  Future<bool> isUserLoggedIn() async {
    if (_user != null) return true;
    _user = await _firebaseService.getCurrentUser();
    return _user != null;
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
      _user = userCredential.user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential =
          await _firebaseService.signInWithEmail(email, password);
      _user = userCredential.user;
      notifyListeners();
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
