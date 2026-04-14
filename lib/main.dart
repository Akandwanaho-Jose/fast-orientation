import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:fast/core/services/auth_service.dart';
import 'package:fast/core/services/lib/core/services/announcement_service.dart';
import 'package:fast/core/services/lib/core/services/course_service.dart';
import 'package:fast/core/services/lib/core/services/department_service.dart';
import 'package:fast/core/services/lib/core/services/faculty_info_service.dart';
import 'package:fast/core/services/lib/core/services/program_service.dart';
import 'package:fast/core/services/lib/core/services/staff_service.dart';
import 'package:fast/core/services/lib/core/notification_service.dart';
import 'package:fast/features/admin/screens/admin_dashboard_screen.dart';
import 'package:fast/features/home/screens/home_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const MyApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize notification service
    await NotificationService().initialize();
    
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<DepartmentService>(
          create: (_) => DepartmentService(),
        ),
        Provider<ProgramService>(
          create: (_) => ProgramService(),
        ),
        Provider<StaffService>(
          create: (_) => StaffService(),
        ),
        Provider<AnnouncementService>(
          create: (_) => AnnouncementService(),
        ),
        Provider<CourseService>(
          create: (_) => CourseService(),
        ),
        Provider<FacultyInfoService>(
          create: (_) => FacultyInfoService(),
        ),
        // Add notification service provider
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MUST-FAST CONNECT',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// New widget to handle authentication and role-based routing
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading FAST Connect...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Handle error state
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please restart the app',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        // Handle authentication state
        final user = snapshot.data;
        if (user != null) {
          // Signed-in admins still go to the dashboard.
          return RoleBasedScreen(user: user);
        } else {
          // Guests can browse the app without signing in.
          return const HomeScreen();
        }
      },
    );
  }
}

// New widget to handle role-based screen routing
class RoleBasedScreen extends StatelessWidget {
  final User user;

  const RoleBasedScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return FutureBuilder<bool>(
      future: authService.isAdmin(user.uid),
      builder: (context, snapshot) {
        // Show loading while checking admin status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Checking user permissions...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Handle error in checking admin status
        if (snapshot.hasError) {
          debugPrint('Error checking admin status: ${snapshot.error}');
          // Default to regular home screen if there's an error
          return const HomeScreen();
        }

        // Route based on admin status
        final isAdmin = snapshot.data ?? false;
        debugPrint('User ${user.uid} isAdmin: $isAdmin');
        
        if (isAdmin) {
          return const AdminDashboardScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}
