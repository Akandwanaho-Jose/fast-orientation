import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fast/features/departments/models/department.dart';
import 'package:image_picker/image_picker.dart';

class DepartmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new department
  Future<void> createDepartment({
    required String name,
    required String description,
    required XFile? imageFile,
    required XFile? headImageFile,
    required String headMessage,
  }) async {
    try {
      String imageUrl = '';
      String headImageUrl = '';
      if (imageFile != null) {
        final ref = _storage
            .ref()
            .child('departments')
            .child('${DateTime.now().millisecondsSinceEpoch}_dept.jpg');
        await ref.putFile(File(imageFile.path));
        imageUrl = await ref.getDownloadURL();
      }
      if (headImageFile != null) {
        final ref = _storage
            .ref()
            .child('departments')
            .child('${DateTime.now().millisecondsSinceEpoch}_head.jpg');
        await ref.putFile(File(headImageFile.path));
        headImageUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('departments').add({
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'headMessage': headMessage,
        'headImageUrl': headImageUrl,
      });
    } catch (e) {
      throw Exception('Failed to create department: $e');
    }
  }

  // Read all departments
  Stream<List<Department>> getDepartments() {
    return _firestore
        .collection('departments')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Department.fromJson(doc.data()..['id'] = doc.id, []),
                  )
                  .toList(),
        );
  }

  // Update a department
  Future<void> updateDepartment({
    required String id,
    required String name,
    required String description,
    required String? currentImageUrl,
    required String? currentHeadImageUrl,
    required String headMessage,
    required XFile? newImageFile,
    required XFile? newHeadImageFile,
  }) async {
    try {
      String imageUrl = currentImageUrl ?? '';
      String headImageUrl = currentHeadImageUrl ?? '';
      if (newImageFile != null) {
        if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
          await _storage.refFromURL(currentImageUrl).delete();
        }
        final ref = _storage
            .ref()
            .child('departments')
            .child('${DateTime.now().millisecondsSinceEpoch}_dept.jpg');
        await ref.putFile(File(newImageFile.path));
        imageUrl = await ref.getDownloadURL();
      }
      if (newHeadImageFile != null) {
        if (currentHeadImageUrl != null && currentHeadImageUrl.isNotEmpty) {
          await _storage.refFromURL(currentHeadImageUrl).delete();
        }
        final ref = _storage
            .ref()
            .child('departments')
            .child('${DateTime.now().millisecondsSinceEpoch}_head.jpg');
        await ref.putFile(File(newHeadImageFile.path));
        headImageUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('departments').doc(id).update({
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'headMessage': headMessage,
        'headImageUrl': headImageUrl,
      });
    } catch (e) {
      throw Exception('Failed to update department: $e');
    }
  }

  // Delete a department
  Future<void> deleteDepartment(
    String id,
    String? imageUrl,
    String? headImageUrl,
  ) async {
    try {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _storage.refFromURL(imageUrl).delete();
      }
      if (headImageUrl != null && headImageUrl.isNotEmpty) {
        await _storage.refFromURL(headImageUrl).delete();
      }
      await _firestore.collection('departments').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete department: $e');
    }
  }
}
