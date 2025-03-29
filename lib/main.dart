import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:fast/features/departments/screens/departments_screen.dart';
// import 'package:fast/scripts/add_departments.dart'; // Import the script (now commented out)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // await AddDepartmentsScript.addDepartments(); // Script execution commented out as it's already completed
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FAST MUST Orientation',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DepartmentsScreen(),
    );
  }
}
