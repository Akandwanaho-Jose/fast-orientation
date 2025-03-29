import 'package:cloud_firestore/cloud_firestore.dart';

class AddDepartmentsScript {
  static Future<void> addDepartments() async {
    final firestore = FirebaseFirestore.instance;

    // Department of Mechanical Engineering (ID: 5)
    await firestore.collection('departments').doc('5').set({
      'description':
          'The Department of Mechanical Engineering focuses on the design, analysis, and manufacturing of mechanical systems, preparing students for innovative careers in engineering.',
      'id': '5',
      'imageUrl': 'assets/images/mechanical.jpg',
      'name': 'Mechanical Engineering',
    });

    // Add programs subcollection for Mechanical Engineering
    await firestore
        .collection('departments')
        .doc('5')
        .collection('programs')
        .doc('BSc')
        .set({'name': 'BSc', 'durationYears': 4});

    // Add yearCourses subcollection for Mechanical Engineering
    await firestore
        .collection('departments')
        .doc('5')
        .collection('programs')
        .doc('BSc')
        .collection('yearCourses')
        .doc('year1')
        .set({
          'year': 1,
          'courses': [
            {
              'code': 'ME101',
              'name': 'Introduction to Mechanical Engineering',
              'description': 'Basics of mechanical systems.',
              'credits': 3,
            },
            {
              'code': 'MATH101',
              'name': 'Calculus I',
              'description': 'Fundamentals of calculus.',
              'credits': 4,
            },
          ],
        });

    await firestore
        .collection('departments')
        .doc('5')
        .collection('programs')
        .doc('BSc')
        .collection('yearCourses')
        .doc('year2')
        .set({
          'year': 2,
          'courses': [
            {
              'code': 'ME201',
              'name': 'Thermodynamics',
              'description': 'Study of energy and heat transfer.',
              'credits': 3,
            },
            {
              'code': 'PHYS201',
              'name': 'Physics II',
              'description': 'Advanced physics concepts.',
              'credits': 4,
            },
          ],
        });

    await firestore
        .collection('departments')
        .doc('5')
        .collection('programs')
        .doc('BSc')
        .collection('yearCourses')
        .doc('year3')
        .set({
          'year': 3,
          'courses': [
            {
              'code': 'ME301',
              'name': 'Fluid Mechanics',
              'description': 'Study of fluid behavior.',
              'credits': 3,
            },
            {
              'code': 'ME302',
              'name': 'Mechanical Design',
              'description': 'Principles of designing mechanical systems.',
              'credits': 3,
            },
          ],
        });

    await firestore
        .collection('departments')
        .doc('5')
        .collection('programs')
        .doc('BSc')
        .collection('yearCourses')
        .doc('year4')
        .set({
          'year': 4,
          'courses': [
            {
              'code': 'ME401',
              'name': 'Robotics',
              'description': 'Introduction to robotics and automation.',
              'credits': 3,
            },
            {
              'code': 'ME402',
              'name': 'Capstone Project',
              'description': 'Final year project.',
              'credits': 6,
            },
          ],
        });

    // Department of Biomedical Engineering (ID: 6)
    await firestore.collection('departments').doc('6').set({
      'description':
          'The Department of Biomedical Engineering bridges engineering and medicine, focusing on developing technologies for healthcare and medical applications.',
      'id': '6',
      'imageUrl': 'assets/images/biomedical.jpg',
      'name': 'Biomedical Engineering',
    });

    // Add programs subcollection for Biomedical Engineering
    await firestore
        .collection('departments')
        .doc('6')
        .collection('programs')
        .doc('BSc')
        .set({'name': 'BSc', 'durationYears': 4});

    // Add yearCourses subcollection for Biomedical Engineering
    await firestore
        .collection('departments')
        .doc('6')
        .collection('programs')
        .doc('BSc')
        .collection('yearCourses')
        .doc('year1')
        .set({
          'year': 1,
          'courses': [
            {
              'code': 'BM101',
              'name': 'Introduction to Biomedical Engineering',
              'description': 'Overview of biomedical engineering.',
              'credits': 3,
            },
            {
              'code': 'BIO101',
              'name': 'Biology I',
              'description': 'Fundamentals of biology.',
              'credits': 4,
            },
          ],
        });

    await firestore
        .collection('departments')
        .doc('6')
        .collection('programs')
        .doc('BSc')
        .collection('yearCourses')
        .doc('year2')
        .set({
          'year': 2,
          'courses': [
            {
              'code': 'BM201',
              'name': 'Biomechanics',
              'description': 'Study of mechanics in biological systems.',
              'credits': 3,
            },
            {
              'code': 'CHEM201',
              'name': 'Chemistry II',
              'description': 'Advanced chemistry concepts.',
              'credits': 4,
            },
          ],
        });

    await firestore
        .collection('departments')
        .doc('6')
        .collection('programs')
        .doc('BSc')
        .collection('yearCourses')
        .doc('year3')
        .set({
          'year': 3,
          'courses': [
            {
              'code': 'BM301',
              'name': 'Medical Imaging',
              'description': 'Techniques for medical imaging.',
              'credits': 3,
            },
            {
              'code': 'BM302',
              'name': 'Biomaterials',
              'description': 'Materials used in medical applications.',
              'credits': 3,
            },
          ],
        });

    await firestore
        .collection('departments')
        .doc('6')
        .collection('programs')
        .doc('BSc')
        .collection('yearCourses')
        .doc('year4')
        .set({
          'year': 4,
          'courses': [
            {
              'code': 'BM401',
              'name': 'Tissue Engineering',
              'description': 'Engineering tissues for medical use.',
              'credits': 3,
            },
            {
              'code': 'BM402',
              'name': 'Capstone Project',
              'description': 'Final year project.',
              'credits': 6,
            },
          ],
        });

    print(
      'Successfully added Mechanical Engineering and Biomedical Engineering departments!',
    );
  }
}
