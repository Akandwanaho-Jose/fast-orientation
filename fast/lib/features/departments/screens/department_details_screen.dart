import 'package:flutter/material.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/departments/models/department.dart';
import 'package:fast/features/departments/screens/course_details_screen.dart'; // Add this import

class DepartmentDetailsScreen extends StatelessWidget {
  final Department department;

  const DepartmentDetailsScreen({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          department.name,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: mustBlue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Department Image
          if (department.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                department.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
              ),
            ),
          const SizedBox(height: 16),

          // Department Description
          Text(
            'About the Department',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: mustGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            department.description,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          // Programs (if any)
          Text(
            'Programs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: mustGreen,
            ),
          ),
          const SizedBox(height: 8),
          if (department.programs.isNotEmpty)
            ...department.programs.map((program) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Program Header
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: mustBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${program.durationYears} Years',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Courses by Year
                  ...program.yearCourses.map((yearCourses) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Year ${yearCourses.year}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: mustBlue,
                            ),
                          ),
                        ),
                        ...yearCourses.courses.map((course) {
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(
                              bottom: 8.0,
                              left: 16.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Text(
                                course.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                'Code: ${course.code} | Credits: ${course.credits}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward,
                                color: mustGreen,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            CourseDetailsScreen(course: course),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
              );
            }).toList()
          else
            const Text(
              'No programs available for this department.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
        ],
      ),
    );
  }
}
