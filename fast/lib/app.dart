import 'package:flutter/material.dart';
import 'core/theme/fast_brand.dart';
import 'features/home/screens/home_screen.dart';
import 'core/utils/constants.dart'; // Import Constants

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: FastBrand.appTitle,
      theme: FastBrand.theme().copyWith(
        primaryColor: mustBlue,
      ),
      home: const HomeScreen(),
    );
  }
}
