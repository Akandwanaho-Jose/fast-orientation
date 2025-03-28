import 'package:flutter/material.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/departments/models/course.dart';

class CourseDetailsScreen extends StatelessWidget {
  final Course course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.name, style: const TextStyle(color: Colors.white)),
        backgroundColor: mustBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: mustGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Code: ${course.code}',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Credits: ${course.credits}',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: mustBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              course.description,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
