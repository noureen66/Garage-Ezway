// // // lib/pages/service/user_service.dart
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _currentUserKey = 'current_user_id';
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  Future<fb_auth.User?> registerUser(String email, String password) async {
    try {
      final fb_auth.UserCredential cred = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, cred.user!.uid);
      await prefs.setString('email', email);
      return cred.user;
    } catch (e) {
      print("Register error: $e");

      if (e is fb_auth.FirebaseAuthException) {
        print("Firebase code: ${e.code}, message: ${e.message}");
      } else if (e is PlatformException) {
        print("Platform code: ${e.code}, message: ${e.message}");
      } else {
        print("Other exception: ${e.toString()}");
      }

      return null;
    }
  }

  Future<fb_auth.User?> loginUser(String email, String password) async {
    try {
      final fb_auth.UserCredential cred = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, cred.user!.uid);
      await prefs.setString('email', email);
      return cred.user;
    } catch (e) {
      print("Login error: $e");

      // Optionally check type if you want
      if (e is fb_auth.FirebaseAuthException) {
        print("Firebase code: ${e.code}, message: ${e.message}");
      } else if (e is PlatformException) {
        print("Platform code: ${e.code}, message: ${e.message}");
      } else {
        print("Other exception: ${e.toString()}");
      }

      return null;
    }
  }

  // Get current user
  Future<fb_auth.User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove('email');
  }

  // Delete user
  Future<void> deleteCurrentUser() async {
    final fb_auth.User? user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
