import 'package:flutter/material.dart';
import '../../../core/utils/constants.dart'; // Import Constants

class FacultyScreen extends StatelessWidget {
  const FacultyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faculty')),
      body: const Center(
        child: Text(
          'Faculty Screen Content',
          style: TextStyle(color: mustBlue),
        ),
      ),
    );
  }
}
