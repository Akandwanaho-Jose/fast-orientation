import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/features/departments/models/course.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new course under a program
  Future<void> createCourse({
    required String departmentId,
    required String programId,
    required String name,
    required String code,
    required int credits,
    required String description,
  }) async {
    try {
      await _firestore.collection('courses').add({
        'departmentId': departmentId,
        'programId': programId,
        'name': name,
        'code': code,
        'credits': credits,
        'description': description,
      });
    } catch (e) {
      throw Exception('Failed to create course: $e');
    }
  }

  // Read all courses for a program
  Stream<List<Course>> getCourses(String departmentId, String programId) {
    return _firestore
        .collection('courses')
        .where('departmentId', isEqualTo: departmentId)
        .where('programId', isEqualTo: programId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Course.fromJson(doc.data())).toList(),
        );
  }

  // Update a course
  Future<void> updateCourse({
    required String courseId,
    required String departmentId,
    required String programId,
    required String name,
    required String code,
    required int credits,
    required String description,
  }) async {
    try {
      await _firestore.collection('courses').doc(courseId).update({
        'departmentId': departmentId,
        'programId': programId,
        'name': name,
        'code': code,
        'credits': credits,
        'description': description,
      });
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }

  // Delete a course
  Future<void> deleteCourse(String courseId) async {
    try {
      await _firestore.collection('courses').doc(courseId).delete();
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }
}
