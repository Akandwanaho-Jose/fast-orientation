/*import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateDepartmentsScript {
  static Future<void> updateDepartments() async {
    final firestore = FirebaseFirestore.instance;

    // Helper function to update or create a department
    Future<void> updateOrCreateDepartment({
      required String id,
      required String name,
      required String description,
      required String imageUrl,
      required String headMessage,
      required String headImageUrl,
    }) async {
      final docRef = firestore.collection('departments').doc(id);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document exists, update it
        await docRef.update({
          'headMessage': headMessage,
          'headImageUrl': headImageUrl,
        });
        print('Updated department $id with headMessage and headImageUrl');
      } else {
        // Document doesn't exist, create it
        await docRef.set({
          'id': id,
          'name': name,
          'description': description,
          'imageUrl': imageUrl,
          'headMessage': headMessage,
          'headImageUrl': headImageUrl,
        });
        print('Created department $id with all fields');
      }
    }

    // Update or create Department 1: Electrical and Electronics Engineering (EEE)
    await updateOrCreateDepartment(
      id: '1',
      name: 'Electrical and Electronics Engineering',
      description:
          'The Department of Electrical and Electronics Engineering focuses on power systems, electronics, and telecommunications.',
      imageUrl: 'assets/images/eee.jpg',
      headMessage:
          '"Welcome to the Department of Electrical and Electronics Engineering! We are committed to fostering innovation and excellence in electrical systems and technology. Our faculty and students work together to push the boundaries of what’s possible." - Dr. John Smith',
      headImageUrl: 'assets/images/head_eee.jpg',
    );

    // Update or create Department 2: Petroleum Engineering
    await updateOrCreateDepartment(
      id: '2',
      name: 'Petroleum Engineering',
      description:
          'The Department of Petroleum Engineering specializes in the exploration and production of oil and gas resources.',
      imageUrl: 'assets/images/petroleum.jpg',
      headMessage:
          '"Greetings from the Department of Petroleum Engineering! Our mission is to train the next generation of engineers to tackle the challenges of energy exploration and production sustainably." - Prof. Sarah Johnson',
      headImageUrl: 'assets/images/head_petroleum.jpg',
    );

    // Update or create Department 3: Civil Engineering
    await updateOrCreateDepartment(
      id: '3',
      name: 'Civil Engineering',
      description:
          'The Department of Civil Engineering focuses on infrastructure development, structural engineering, and sustainable design.',
      imageUrl: 'assets/images/civil.jpg',
      headMessage:
          '"Welcome to the Department of Civil Engineering! We focus on building the infrastructure of tomorrow while ensuring sustainability and safety in all our projects." - Dr. Michael Brown',
      headImageUrl: 'assets/images/head_civil.jpg',
    );

    // Update or create Department 5: Mechanical Engineering
    await updateOrCreateDepartment(
      id: '5',
      name: 'Mechanical Engineering',
      description:
          'The Department of Mechanical Engineering focuses on the design and manufacturing of mechanical systems.',
      imageUrl: 'assets/images/mechanical.jpg',
      headMessage:
          '"Welcome to the Department of Mechanical Engineering! Our goal is to equip students with the skills to design and innovate mechanical systems for a better future." - Dr. Robert Wilson',
      headImageUrl: 'assets/images/head_mechanical.jpg',
    );

    // Update or create Department 6: Biomedical Engineering
    await updateOrCreateDepartment(
      id: '6',
      name: 'Biomedical Engineering',
      description:
          'The Department of Biomedical Engineering focuses on the application of engineering principles to healthcare.',
      imageUrl: 'assets/images/biomedical.jpg',
      headMessage:
          '"Greetings from the Department of Biomedical Engineering! We bridge engineering and medicine to create life-changing healthcare solutions." - Prof. Linda Taylor',
      headImageUrl: 'assets/images/head_biomedical.jpg',
    );

    print(
      'Successfully updated or created departments 1, 2, 3, 5, and 6 with headMessage and headImageUrl fields!',
    );
  }
}
*/
