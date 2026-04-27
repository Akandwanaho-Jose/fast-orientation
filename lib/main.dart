import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fast/core/services/auth_service.dart';
import 'package:fast/core/services/lib/core/notification_service.dart';
import 'package:fast/core/services/lib/core/services/announcement_service.dart';
import 'package:fast/core/services/lib/core/services/course_service.dart';
import 'package:fast/core/services/lib/core/services/department_service.dart';
import 'package:fast/core/services/lib/core/services/faculty_info_service.dart';
import 'package:fast/core/services/lib/core/services/program_service.dart';
import 'package:fast/core/services/lib/core/services/staff_service.dart';
import 'package:fast/core/theme/fast_brand.dart';
import 'package:fast/features/admin/screens/admin_dashboard_screen.dart';
import 'package:fast/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandling();
  runApp(const BootstrapApp());
}

void _installGlobalErrorHandling() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrintStack(stackTrace: details.stack);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  ErrorWidget.builder = (details) {
    return Material(
      color: const Color(0xFFF6F8FC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              const Text(
                'A screen failed to render.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: FastBrand.headingText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: FastBrand.mutedText, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  };
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    unawaited(_initializeNotificationsInBackground());
  }

  Future<void> _initializeNotificationsInBackground() async {
    try {
      await NotificationService().initialize();
    } catch (error, stackTrace) {
      debugPrint('Notification initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _retryBootstrap() {
    setState(() {
      _startupFuture = _bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BootstrapShell(child: _StartupLoadingState());
        }

        if (snapshot.hasError) {
          return _BootstrapShell(
            child: _StartupErrorState(
              error: snapshot.error,
              onRetry: _retryBootstrap,
            ),
          );
        }

        return const MyApp();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DepartmentService>(create: (_) => DepartmentService()),
        Provider<ProgramService>(create: (_) => ProgramService()),
        Provider<StaffService>(create: (_) => StaffService()),
        Provider<AnnouncementService>(create: (_) => AnnouncementService()),
        Provider<CourseService>(create: (_) => CourseService()),
        Provider<FacultyInfoService>(create: (_) => FacultyInfoService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: FastBrand.appTitle,
        theme: FastBrand.theme(),
        home: const AuthWrapper(),
      ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StatusScaffold(
            title: 'Loading FAST Connect...',
            child: CircularProgressIndicator(color: FastBrand.primary),
          );
        }

        if (snapshot.hasError) {
          return const _StatusScaffold(
            title: 'Authentication could not start.',
            message: 'Please restart the app and try again.',
            icon: Icons.error_outline_rounded,
            iconColor: Colors.red,
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const HomeScreen();
        }

        return RoleBasedScreen(user: user);
      },
    );
  }
}

class RoleBasedScreen extends StatelessWidget {
  const RoleBasedScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return FutureBuilder<bool>(
      future: authService.isAdmin(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StatusScaffold(
            title: 'Checking user permissions...',
            child: CircularProgressIndicator(color: FastBrand.primary),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error checking admin status: ${snapshot.error}');
          return const HomeScreen();
        }

        final isAdmin = snapshot.data ?? false;
        debugPrint('User ${user.uid} isAdmin: $isAdmin');
        return isAdmin ? const AdminDashboardScreen() : const HomeScreen();
      },
    );
  }
}

class _BootstrapShell extends StatelessWidget {
  const _BootstrapShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: FastBrand.appTitle,
      theme: FastBrand.theme(),
      home: Scaffold(
        backgroundColor: FastBrand.shellBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupLoadingState extends StatelessWidget {
  const _StartupLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(28),
      decoration: FastBrand.surfaceDecoration(),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: FastBrand.primary),
          SizedBox(height: 18),
          Text(
            'Starting FAST Connect...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: FastBrand.headingText,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Loading Firebase and preparing your faculty experience.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FastBrand.mutedText, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _StartupErrorState extends StatelessWidget {
  const _StartupErrorState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(28),
      decoration: FastBrand.surfaceDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 60, color: Colors.red.shade300),
          const SizedBox(height: 18),
          const Text(
            'FAST Connect could not finish starting.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: FastBrand.headingText,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'The app found a startup problem before the first screen loaded.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FastBrand.mutedText, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: FastBrand.mutedSurfaceDecoration(radius: 18),
            child: Text(
              '${error ?? 'Unknown startup error'}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: FastBrand.supportText, height: 1.5),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry startup'),
          ),
        ],
      ),
    );
  }
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({
    required this.title,
    this.message,
    this.child,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? message;
  final Widget? child;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastBrand.shellBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: FastBrand.surfaceDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (child != null) child!,
                if (child == null && icon != null)
                  Icon(icon, size: 58, color: iconColor ?? FastBrand.primary),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: FastBrand.headingText,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: FastBrand.mutedText,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
