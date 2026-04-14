import 'package:cloud_firestore/cloud_firestore.dart';

class FacultyInfoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getFacultyInfo() async {
    try {
      final doc = await _firestore.collection('faculty_info').doc('fast').get();
      if (!doc.exists) {
        throw Exception('Faculty info not found');
      }
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching faculty info: $e');
      rethrow;
    }
  }
}