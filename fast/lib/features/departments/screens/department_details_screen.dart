import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/features/departments/models/department.dart';
import 'package:fast/features/departments/models/program.dart';
import 'package:fast/features/departments/models/course.dart';
import 'package:fast/features/departments/screens/course_details_screen.dart';

class DepartmentDetailsScreen extends StatelessWidget {
  final Department department;

  const DepartmentDetailsScreen({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(department.name)),
      body: FutureBuilder<QuerySnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('departments')
                .doc(department.id)
                .collection('programs')
                .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading programs'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final programs =
              snapshot.data!.docs.map((doc) {
                return Program.fromJson(
                  doc.data() as Map<String, dynamic>,
                  [], // YearCourses are fetched separately
                );
              }).toList();

          return ListView.builder(
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
              return ExpansionTile(
                title: Text(program.name),
                subtitle: Text('Duration: ${program.durationYears} years'),
                children: List.generate(4, (yearIndex) {
                  final year = yearIndex + 1;
                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('departments')
                            .doc(department.id)
                            .collection('programs')
                            .doc(snapshot.data!.docs[index].id)
                            .collection('yearCourses')
                            .doc('year$year')
                            .get(),
                    builder: (context, yearSnapshot) {
                      if (yearSnapshot.hasError) {
                        return const ListTile(
                          title: Text('Error loading courses'),
                        );
                      }
                      if (!yearSnapshot.hasData || !yearSnapshot.data!.exists) {
                        return const ListTile(
                          title: Text('No courses available'),
                        );
                      }

                      final yearCourses = YearCourses.fromJson(
                        yearSnapshot.data!.data() as Map<String, dynamic>,
                      );

                      return ExpansionTile(
                        title: Text('Year $year'),
                        children:
                            yearCourses.courses.map((course) {
                              return ListTile(
                                title: Text(course.name),
                                subtitle: Text('Credits: ${course.credits}'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => CourseDetailsScreen(
                                            course: course,
                                          ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                      );
                    },
                  );
                }),
              );
            },
          );
        },
      ),
    );
  }
}
