import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:fast/features/home/screens/home_screen.dart';
import 'package:fast/features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    runApp(const MyApp());
  } catch (e) {
    print('Firebase initialization failed: $e');
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Firebase Failed to Initialize')),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FAST MUST Orientation',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('AuthWrapper: Connection State: ${snapshot.connectionState}');
        print('AuthWrapper: Has Data: ${snapshot.hasData}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('AuthWrapper: Waiting for auth state');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          print('AuthWrapper: User logged in: ${snapshot.data!.uid}');
          return const HomeScreen();
        }
        print('AuthWrapper: No user logged in');
        return const LoginScreen();
      },
    );
  }
}
