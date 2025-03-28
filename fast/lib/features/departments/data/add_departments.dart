import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/features/departments/data/mock_data.dart';
//import 'package:fast/features/departments/models/department.dart';
//import 'package:fast/features/departments/models/program.dart';
//import 'package:fast/features/departments/models/course.dart';

Future<void> addDepartmentsToFirestore() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  for (var department in mockDepartments) {
    // Add department document
    final departmentRef = firestore
        .collection('departments')
        .doc(department.id);
    await departmentRef.set(department.toJson());

    // Add programs subcollection
    for (var program in department.programs) {
      final programRef = departmentRef.collection('programs').doc();
      await programRef.set(program.toJson());
      // Add yearCourses subcollection
      for (var yearCourses in program.yearCourses) {
        final yearRef = programRef
            .collection('yearCourses')
            .doc('year${yearCourses.year}');
        await yearRef.set(yearCourses.toJson());
      }
    }
  }
  print('Departments added to Firestore successfully!');
}
