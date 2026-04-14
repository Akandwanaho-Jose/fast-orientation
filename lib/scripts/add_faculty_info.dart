import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateFacultyInfoScript {
  static Future<void> updateFacultyInfo() async {
    print('Starting faculty info update...');

    // Faculty info data
    final Map<String, dynamic> facultyInfo = {
      'dean_name': 'Dr. Johnes Obungoloch',
      'dean_photo_url': 'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/deans%2Fdean.jpg?alt=media', // Replace with actual URL
      'dean_message':
          'Welcome to the Faculty of Applied Sciences and Technology at MUST. We are delighted to have you join our community of innovators and scholars. Our faculty is dedicated to providing cutting-edge education and research opportunities in science and technology. As you embark on this journey, know that our team of experienced lecturers and staff are here to support you every step of the way. Explore our diverse programs, engage with our vibrant community, and let’s shape the future together!',
    };

    // Reference to the faculty_info collection
    final DocumentReference facultyInfoRef =
        FirebaseFirestore.instance.collection('faculty_info').doc('fast');

    try {
      // Set the faculty_info/fast document with merge to avoid overwriting
      await facultyInfoRef.set(facultyInfo, SetOptions(merge: true));
      print('Added/Updated faculty_info/fast document');
    } catch (e) {
      print('Error adding/updating faculty_info/fast document: $e');
    }

    print('Faculty info update completed.');
  }
}