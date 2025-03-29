import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/features/departments/models/department.dart';
import 'package:fast/features/departments/models/program.dart';
import 'package:fast/features/departments/models/course.dart';
import 'package:fast/features/departments/screens/course_details_screen.dart';
import 'package:fast/core/utils/constants.dart'; // Import MUST colors

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
        backgroundColor: mustBlue, // Use MUST blue for AppBar
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Department Image
            Image.asset(
              department.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, size: 50, color: Colors.grey),
                );
              },
            ),
            // Department Name (below image)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                department.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: mustGreen, // Use MUST green for department name
                ),
              ),
            ),
            // Program ExpansionTile
            FutureBuilder<QuerySnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('departments')
                      .doc(department.id)
                      .collection('programs')
                      .get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading programs',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final programDocs = snapshot.data!.docs;

                final uniquePrograms = <String, Program>{};
                for (var doc in programDocs) {
                  final program = Program.fromJson(
                    doc.data() as Map<String, dynamic>,
                    [],
                  );
                  uniquePrograms[program.name] = program;
                }
                final programs = uniquePrograms.values.toList();

                if (programs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No programs available',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      child: ExpansionTile(
                        title: Text(
                          program.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: mustBlue, // Use MUST blue for program name
                          ),
                        ),
                        subtitle: Text(
                          'Duration: ${program.durationYears} years',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        children: [
                          FutureBuilder<QuerySnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('departments')
                                    .doc(department.id)
                                    .collection('programs')
                                    .doc(programDocs[index].id)
                                    .collection('yearCourses')
                                    .orderBy('year')
                                    .get(),
                            builder: (context, yearSnapshot) {
                              if (yearSnapshot.hasError) {
                                return const ListTile(
                                  title: Text(
                                    'Error loading courses',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                );
                              }
                              if (!yearSnapshot.hasData) {
                                return const ListTile(
                                  title: Text('Loading courses...'),
                                );
                              }

                              final yearCoursesList =
                                  yearSnapshot.data!.docs.map((doc) {
                                    return YearCourses.fromJson(
                                      doc.data() as Map<String, dynamic>,
                                    );
                                  }).toList();

                              final yearCoursesMap = {
                                for (var yc in yearCoursesList) yc.year: yc,
                              };

                              return Column(
                                children: List.generate(4, (yearIndex) {
                                  final year = yearIndex + 1;
                                  final yearCourses = yearCoursesMap[year];

                                  if (yearCourses == null) {
                                    return ExpansionTile(
                                      title: Text(
                                        'Year $year',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              mustBlue, // Use MUST blue for year
                                        ),
                                      ),
                                      children: const [
                                        ListTile(
                                          title: Text(
                                            'No courses available',
                                            style: TextStyle(
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  final uniqueCourses = <String, Course>{};
                                  for (var course in yearCourses.courses) {
                                    uniqueCourses[course.code] = course;
                                  }
                                  final courses = uniqueCourses.values.toList();

                                  return ExpansionTile(
                                    title: Text(
                                      'Year $year',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            mustBlue, // Use MUST blue for year
                                      ),
                                    ),
                                    children:
                                        courses.isEmpty
                                            ? const [
                                              ListTile(
                                                title: Text(
                                                  'No courses available',
                                                  style: TextStyle(
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ]
                                            : courses.map((course) {
                                              return ListTile(
                                                title: Text(
                                                  course.name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  'Credits: ${course.credits}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              CourseDetailsScreen(
                                                                course: course,
                                                              ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }).toList(),
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
