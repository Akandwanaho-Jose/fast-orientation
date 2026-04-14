import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fast/features/staff/models/staff.dart';
import 'package:image_picker/image_picker.dart';

class StaffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new staff member
  Future<void> createStaff({
    required String name,
    required String position,
    required String email,
    required String linkedinUrl,
    required String department,
    required XFile? imageFile,
  }) async {
    try {
      String photoUrl = '';
      if (imageFile != null) {
        final ref = _storage
            .ref()
            .child('staff')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(imageFile.path));
        photoUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('staff').add({
        'name': name,
        'position': position,
        'email': email,
        'linkedinUrl': linkedinUrl,
        'photoUrl': photoUrl,
        'department': department,
      });
    } catch (e) {
      throw Exception('Failed to create staff: $e');
    }
  }

  // Update a staff member
  Future<void> updateStaff({
    required String id,
    required String name,
    required String position,
    required String email,
    required String linkedinUrl,
    required String department,
    required String? currentPhotoUrl,
    required XFile? newImageFile,
  }) async {
    try {
      String photoUrl = currentPhotoUrl ?? '';
      if (newImageFile != null) {
        if (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty) {
          await _storage.refFromURL(currentPhotoUrl).delete();
        }
        final ref = _storage
            .ref()
            .child('staff')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(newImageFile.path));
        photoUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('staff').doc(id).update({
        'name': name,
        'position': position,
        'email': email,
        'linkedinUrl': linkedinUrl,
        'department': department,
        'photoUrl': photoUrl,
      });
    } catch (e) {
      throw Exception('Failed to update staff: $e');
    }
  }

  // Read all staff members
  Stream<List<Staff>> getStaff() {
    return _firestore
        .collection('staff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // Add id to the map
              return Staff.fromJson(data, doc.id);
            } catch (e) {
              print('Error mapping staff document ${doc.id}: $e'); // Remove in production
              return Staff(
                id: doc.id,
                name: null,
                position: null,
                email: null,
                linkedinUrl: null,
                photoUrl: null,
                department: null,
              );
            }
          }).toList();
        });
  }

  // Delete a staff member
  Future<void> deleteStaff(String id, String? photoUrl) async {
    try {
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await _storage.refFromURL(photoUrl).delete();
      }
      await _firestore.collection('staff').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete staff: $e');
    }
  }
}