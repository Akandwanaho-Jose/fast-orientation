import 'package:fast/features/departments/models/course.dart';

class Program {
  final String name;
  final int durationYears;
  final List<YearCourses> yearCourses;

  Program({
    required this.name,
    required this.durationYears,
    required this.yearCourses,
  });

  // Factory method to create a Program from Firestore data
  factory Program.fromJson(
    Map<String, dynamic> json,
    List<YearCourses> yearCourses,
  ) {
    return Program(
      name: json['name'] as String,
      durationYears: json['durationYears'] as int,
      yearCourses: yearCourses,
    );
  }

  // Method to convert a Program to Firestore-compatible JSON
  Map<String, dynamic> toJson() {
    return {'name': name, 'durationYears': durationYears};
  }
}

class YearCourses {
  final int year;
  final List<Course> courses;

  YearCourses({required this.year, required this.courses});

  // Factory method to create a YearCourses from Firestore data
  factory YearCourses.fromJson(Map<String, dynamic> json) {
    return YearCourses(
      year: json['year'] as int,
      courses:
          (json['courses'] as List<dynamic>)
              .map(
                (courseJson) =>
                    Course.fromJson(courseJson as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  // Method to convert a YearCourses to Firestore-compatible JSON
  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'courses': courses.map((course) => course.toJson()).toList(),
    };
  }
}
