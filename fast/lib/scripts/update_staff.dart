/*import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateStaffScript {
  static Future<void> updateStaff() async {
    print('Starting staff update...');

    // Sample staff data with placeholder photo URLs
    final List<Map<String, dynamic>> sampleStaff = [
      // Dean’s Office
      {
        'name': 'Dr. John Doe',
        'position': 'Dean',
        'email': 'john.doe@must.ac.ug',
        'linkedinUrl': 'https://www.linkedin.com/in/johndoe',
        'photoUrl':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=1974&auto=format&fit=crop',
        'department': 'Dean’s Office',
      },
      {
        'name': 'Ms. Jane Smith',
        'position': 'Administrative Assistant',
        'email': 'jane.smith@must.ac.ug',
        'linkedinUrl': 'https://www.linkedin.com/in/janesmith',
        'photoUrl':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=1974&auto=format&fit=crop',
        'department': 'Dean’s Office',
      },
      // Electrical and Electronics Engineering Department
      {
        'name': 'Prof. Michael Brown',
        'position': 'Head of Department',
        'email': 'michael.brown@must.ac.ug',
        'linkedinUrl': 'https://www.linkedin.com/in/michaelbrown',
        'photoUrl':
            'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=1974&auto=format&fit=crop',
        'department': 'Electrical and Electronics Engineering Department',
      },
      {
        'name': 'Dr. Sarah Johnson',
        'position': 'Senior Lecturer',
        'email': 'sarah.johnson@must.ac.ug',
        'linkedinUrl': 'https://www.linkedin.com/in/sarahjohnson',
        'photoUrl':
            'https://images.unsplash.com/photo-1573496359142-b8d877991彰?q=80&w=1974&auto=format&fit=crop',
        'department': 'Electrical and Electronics Engineering Department',
      },
      // Biomedical Engineering Department
      {
        'name': 'Dr. Emily Davis',
        'position': 'Head of Department',
        'email': 'emily.davis@must.ac.ug',
        'linkedinUrl': 'https://www.linkedin.com/in/emilydavis',
        'photoUrl':
            'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=1974&auto=format&fit=crop',
        'department': 'Biomedical Engineering Department',
      },
      // Petroleum Engineering Department
      {
        'name': 'Prof. David Wilson',
        'position': 'Head of Department',
        'email': 'david.wilson@must.ac.ug',
        'linkedinUrl': 'https://www.linkedin.com/in/davidwilson',
        'photoUrl':
            'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?q=80&w=1974&auto=format&fit=crop',
        'department': 'Petroleum Engineering Department',
      },
      // Civil Engineering Department
      {
        'name': 'Dr. Linda Martinez',
        'position': 'Head of Department',
        'email': 'linda.martinez@must.ac.ug',
        'linkedinUrl': 'https://www.linkedin.com/in/lindamartinez',
        'photoUrl':
            'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?q=80&w=1974&auto=format&fit=crop',
        'department': 'Civil Engineering Department',
      },
      // Mechanical Engineering Department
      {
        'name': 'Prof. James Taylor',
        'position': 'Head of Department',
        'email': 'james.taylor@must.ac.ug',
        'linkedinUrl': 'https://www.linkedin.com/in/jamestaylor',
        'photoUrl':
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=1974&auto=format&fit=crop',
        'department': 'Mechanical Engineering Department',
      },
    ];

    // Reference to the staff collection
    final CollectionReference staffRef = FirebaseFirestore.instance.collection(
      'staff',
    );

    // Clear existing staff (optional, remove if you want to append)
    final existingStaff = await staffRef.get();
    for (var doc in existingStaff.docs) {
      await doc.reference.delete();
    }

    // Add new staff
    for (var staff in sampleStaff) {
      await staffRef.add(staff);
      print('Added staff: ${staff['name']} in ${staff['department']}');
    }

    print('Staff update completed.');
  }
}*/
