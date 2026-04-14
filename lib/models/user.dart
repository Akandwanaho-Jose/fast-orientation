import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;

  AppUser({required this.uid, required this.email, required this.role});

  factory AppUser.fromFirebaseUser(User user, String role) {
    return AppUser(uid: user.uid, email: user.email ?? '', role: role);
  }
}
