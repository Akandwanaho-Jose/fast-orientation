import 'package:flutter/material.dart';
import 'features/home/screens/home_screen.dart';
import 'core/utils/constants.dart'; // Import Constants

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MUST FAST Orientation',
      theme: ThemeData(
        primaryColor: mustBlue, // Use constant from constants.dart
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: mustBlue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
