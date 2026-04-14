import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/features/departments/models/program.dart';

class ProgramService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new program
  Future<void> createProgram({
    required String departmentId,
    required String name,
    required int durationYears,
    required List<YearCourses> yearCourses,
  }) async {
    try {
      final programRef = await _firestore
          .collection('departments')
          .doc(departmentId)
          .collection('programs')
          .add({'name': name, 'durationYears': durationYears});

      for (var yearCourse in yearCourses) {
        await programRef
            .collection('yearCourses')
            .doc(yearCourse.year.toString())
            .set(yearCourse.toJson());
      }
    } catch (e) {
      throw Exception('Failed to create program: $e');
    }
  }

  // Read all programs for a department
  Stream<List<Program>> getPrograms(String departmentId) {
    return _firestore
        .collection('departments')
        .doc(departmentId)
        .collection('programs')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Program> programs = [];
          for (var doc in snapshot.docs) {
            final yearCoursesSnapshot =
                await doc.reference.collection('yearCourses').get();
            final yearCourses =
                yearCoursesSnapshot.docs
                    .map((ycDoc) => YearCourses.fromJson(ycDoc.data()))
                    .toList();
            programs.add(Program.fromJson(doc.data(), yearCourses));
          }
          return programs;
        });
  }

  // Update a program
  Future<void> updateProgram({
    required String departmentId,
    required String programId,
    required String name,
    required int durationYears,
    required List<YearCourses> yearCourses,
  }) async {
    try {
      await _firestore
          .collection('departments')
          .doc(departmentId)
          .collection('programs')
          .doc(programId)
          .update({'name': name, 'durationYears': durationYears});

      // Delete existing yearCourses
      final yearCoursesRef = _firestore
          .collection('departments')
          .doc(departmentId)
          .collection('programs')
          .doc(programId)
          .collection('yearCourses');
      final existingYearCourses = await yearCoursesRef.get();
      for (var doc in existingYearCourses.docs) {
        await doc.reference.delete();
      }

      // Add updated yearCourses
      for (var yearCourse in yearCourses) {
        await yearCoursesRef
            .doc(yearCourse.year.toString())
            .set(yearCourse.toJson());
      }
    } catch (e) {
      throw Exception('Failed to update program: $e');
    }
  }

  // Delete a program
  Future<void> deleteProgram(String departmentId, String programId) async {
    try {
      await _firestore
          .collection('departments')
          .doc(departmentId)
          .collection('programs')
          .doc(programId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete program: $e');
    }
  }
}
