import 'package:flutter/material.dart';
import '../../../core/utils/constants.dart'; // Import Constants

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: const Center(
        child: Text(
          'Courses Screen Content',
          style: TextStyle(color: mustBlue),
        ),
      ),
    );
  }
}
