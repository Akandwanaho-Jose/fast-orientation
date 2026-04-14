import 'package:firebase_auth/firebase_auth.dart';
import 'package:fast/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Sign in with email and password
  Future<AppUser?> signIn(String email, String password) async {
    try {
      // Only set persistence on web platforms
      if (kIsWeb) {
        await _auth.setPersistence(Persistence.LOCAL);
      }
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user == null) {
        throw Exception('User not found after sign-in');
      }
      // Check the user's role
      String role = await _getUserRole(user.uid);
      // Update last login
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return AppUser.fromFirebaseUser(user, role);
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found for that email.');
        case 'wrong-password':
          throw Exception('Wrong password provided for that user.');
        case 'invalid-email':
          throw Exception('The email address is badly formatted.');
        case 'user-disabled':
          throw Exception('This user account has been disabled.');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please try again later.');
        default:
          throw Exception('Sign in failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }
  
  // Get the user's role
  Future<String> _getUserRole(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()!['role'] ?? 'user';
      }
      return 'user';
    } catch (e) {
      print('Error checking user role: $e');
      return 'user';
    }
  }
  
  // Check if the user is an admin
  Future<bool> isAdmin(String userId) async {
    String role = await _getUserRole(userId);
    return role == 'admin';
  }
  
  // Create a user profile
  Future<void> createUserProfile(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'role': role,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
  
  // Reset password - NEW METHOD
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found for that email address.');
        case 'invalid-email':
          throw Exception('The email address is badly formatted.');
        case 'too-many-requests':
          throw Exception('Too many requests. Please try again later.');
        default:
          throw Exception('Password reset failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }
  
  // Additional utility methods
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isLoggedIn => _auth.currentUser != null;
  String? get userEmail => _auth.currentUser?.email;
  String? get userId => _auth.currentUser?.uid;
}