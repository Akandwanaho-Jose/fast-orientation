import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class RestructuredDatabaseSeeder {
  RestructuredDatabaseSeeder({
    required FirebaseFirestore firestore,
    required DateTime now,
    this.dryRun = false,
    this.seedExamples = true,
    this.seedQuickLinks = true,
  }) : _firestore = firestore,
       _now = now;

  final FirebaseFirestore _firestore;
  final DateTime _now;
  final bool dryRun;
  final bool seedExamples;
  final bool seedQuickLinks;

  Future<void> run() async {
    _log('');
    _log('FAST restructured Firestore seeder');
    _log('Dry run: $dryRun');
    _log('Seed examples when empty: $seedExamples');
    _log('Seed quick links: $seedQuickLinks');
    _log('');

    await _seedOrMigrateDepartments();
    await _seedOrMigrateStaff();
    await _seedOrMigrateAnnouncements();
    await _seedFacultyInfo();
    await _seedFeaturedStories();
    await _seedOrientationContent();
    await _seedSupportResources();

    if (seedQuickLinks) {
      await _seedQuickLinksCollection();
    }

    _log('');
    _log('Seeder finished successfully.');
    if (dryRun) {
      _log('No Firestore writes were committed because DRY_RUN is enabled.');
    }
  }

  Future<void> _seedOrMigrateDepartments() async {
    _log('Checking departments...');
    final departmentsRef = _firestore.collection('departments');
    final snapshot = await departmentsRef.get();

    if (snapshot.docs.isEmpty) {
      if (!seedExamples) {
        _log(
          'No departments found. Example department data seeding is disabled.',
        );
        return;
      }

      for (final department in _sampleDepartments()) {
        final ref = departmentsRef.doc(department.id);
        await _setDocument(ref, department.data);
        _log('Prepared department ${department.id}');

        for (final program in department.programs) {
          final programRef = ref.collection('programs').doc(program.id);
          await _setDocument(programRef, program.data);

          for (final yearCourse in program.yearCourses) {
            final yearRef = programRef
                .collection('yearCourses')
                .doc(yearCourse.id);
            await _setDocument(yearRef, yearCourse.data);
          }
        }
      }

      _log('Seeded example departments, programs, and year courses.');
      return;
    }

    var order = 1;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = _readString(data, 'name') ?? 'Department ${doc.id}';
      final description = _readString(data, 'description') ?? '';
      final payload = <String, dynamic>{
        'id': _readString(data, 'id') ?? doc.id,
        'name': name,
        'shortName': _readString(data, 'shortName') ?? _buildShortName(name),
        'slug': _readString(data, 'slug') ?? _slugify(name),
        'description': description,
        'shortDescription':
            _readString(data, 'shortDescription') ??
            _buildShortDescription(description, name),
        'imageUrl': _readString(data, 'imageUrl') ?? '',
        'headName': _readString(data, 'headName') ?? '',
        'headTitle': _readString(data, 'headTitle') ?? 'Head of Department',
        'headImageUrl': _readString(data, 'headImageUrl') ?? '',
        'headMessage': _readString(data, 'headMessage') ?? '',
        'contactEmail': _readString(data, 'contactEmail') ?? '',
        'contactPhone': _readString(data, 'contactPhone') ?? '',
        'location': _readString(data, 'location') ?? '',
        'featured': _readBool(data, 'featured') ?? order == 1,
        'order': _readInt(data, 'order') ?? order,
        'facilities': _readStringList(data, 'facilities'),
        'achievements': _readStringList(data, 'achievements'),
        'status': _readString(data, 'status') ?? 'published',
        'createdAt': data['createdAt'] ?? Timestamp.fromDate(_now),
        'updatedAt': Timestamp.fromDate(_now),
      };

      await _setDocument(doc.reference, payload);
      await _migratePrograms(doc.reference);
      order++;
    }

    _log('Migrated ${snapshot.docs.length} department documents.');
  }

  Future<void> _migratePrograms(
    DocumentReference<Map<String, dynamic>> departmentRef,
  ) async {
    final snapshot = await departmentRef.collection('programs').get();
    var order = 1;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = _readString(data, 'name') ?? 'Unnamed Program';
      final payload = <String, dynamic>{
        'name': name,
        'award': _readString(data, 'award') ?? _inferAward(name),
        'slug': _readString(data, 'slug') ?? _slugify(name),
        'summary':
            _readString(data, 'summary') ?? 'Learn more about $name at FAST.',
        'durationYears': _readInt(data, 'durationYears') ?? 4,
        'studyMode': _readString(data, 'studyMode') ?? 'full-time',
        'intake': _readStringList(data, 'intake'),
        'entryRequirements': _readString(data, 'entryRequirements') ?? '',
        'careerPaths': _readStringList(data, 'careerPaths'),
        'brochureUrl': _readString(data, 'brochureUrl') ?? '',
        'featured': _readBool(data, 'featured') ?? order == 1,
        'order': _readInt(data, 'order') ?? order,
        'status': _readString(data, 'status') ?? 'published',
        'createdAt': data['createdAt'] ?? Timestamp.fromDate(_now),
        'updatedAt': Timestamp.fromDate(_now),
      };

      await _setDocument(doc.reference, payload);
      await _migrateYearCourses(doc.reference);
      order++;
    }
  }

  Future<void> _migrateYearCourses(
    DocumentReference<Map<String, dynamic>> programRef,
  ) async {
    final snapshot = await programRef.collection('yearCourses').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final payload = <String, dynamic>{
        'year': _readInt(data, 'year') ?? _parseYearFromId(doc.id),
        'courses': _normalizeCourses(data['courses']),
        'updatedAt': Timestamp.fromDate(_now),
      };

      await _setDocument(doc.reference, payload);
    }
  }

  Future<void> _seedOrMigrateStaff() async {
    _log('Checking staff...');
    final staffRef = _firestore.collection('staff');
    final snapshot = await staffRef.get();

    if (snapshot.docs.isEmpty) {
      if (!seedExamples) {
        _log('No staff found. Example staff seeding is disabled.');
        return;
      }

      for (final member in _sampleStaff()) {
        await _setDocument(staffRef.doc(member.id), member.data);
      }

      _log('Seeded example staff records.');
      return;
    }

    var order = 1;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final position = _readString(data, 'position') ?? '';
      final roleType =
          _readString(data, 'roleType') ?? _inferRoleType(position);
      final payload = <String, dynamic>{
        'name': _readString(data, 'name') ?? 'Unnamed Staff Member',
        'position': position,
        'roleType': roleType,
        'department': _readString(data, 'department') ?? '',
        'departmentName':
            _readString(data, 'departmentName') ??
            _readString(data, 'department') ??
            '',
        'email': _readString(data, 'email') ?? '',
        'phone': _readString(data, 'phone') ?? '',
        'office': _readString(data, 'office') ?? '',
        'linkedinUrl': _readString(data, 'linkedinUrl') ?? '',
        'photoUrl': _readString(data, 'photoUrl') ?? '',
        'bio': _readString(data, 'bio') ?? '',
        'specialties': _readStringList(data, 'specialties'),
        'isKeyContact':
            _readBool(data, 'isKeyContact') ??
            roleType == 'dean' ||
                roleType == 'hod' ||
                roleType == 'key_contact',
        'featured':
            _readBool(data, 'featured') ??
            roleType == 'dean' || roleType == 'hod',
        'order': _readInt(data, 'order') ?? order,
        'status': _readString(data, 'status') ?? 'published',
        'createdAt': data['createdAt'] ?? Timestamp.fromDate(_now),
        'updatedAt': Timestamp.fromDate(_now),
      };

      final departmentId = _readString(data, 'departmentId');
      if (departmentId != null && departmentId.isNotEmpty) {
        payload['departmentId'] = departmentId;
      }

      await _setDocument(doc.reference, payload);
      order++;
    }

    _log('Migrated ${snapshot.docs.length} staff documents.');
  }

  Future<void> _seedOrMigrateAnnouncements() async {
    _log('Checking announcements...');
    final announcementsRef = _firestore.collection('announcements');
    final snapshot = await announcementsRef.get();

    if (snapshot.docs.isEmpty) {
      if (!seedExamples) {
        _log(
          'No announcements found. Example announcement seeding is disabled.',
        );
        return;
      }

      for (final announcement in _sampleAnnouncements()) {
        await _setDocument(
          announcementsRef.doc(announcement.id),
          announcement.data,
        );
      }

      _log('Seeded example announcements.');
      return;
    }

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final postedAt = data['postedAt'] ?? Timestamp.fromDate(_now);
      final payload = <String, dynamic>{
        'title': _readString(data, 'title') ?? 'Untitled Update',
        'description': _readString(data, 'description') ?? '',
        'category': _readString(data, 'category') ?? 'General',
        'type': _readString(data, 'type') ?? _inferAnnouncementType(data),
        'priority': _readString(data, 'priority') ?? 'normal',
        'isPinned': _readBool(data, 'isPinned') ?? false,
        'featured':
            _readBool(data, 'featured') ?? _readBool(data, 'isPinned') ?? false,
        'imageUrls': _readStringList(data, 'imageUrls'),
        'tags': _readStringList(data, 'tags'),
        'views': _readInt(data, 'views') ?? 0,
        'audience': _readStringList(data, 'audience', fallback: ['all-users']),
        'departmentIds': _readStringList(data, 'departmentIds'),
        'status': _readString(data, 'status') ?? 'published',
        'postedAt': postedAt,
        'createdAt': data['createdAt'] ?? postedAt,
        'updatedAt': Timestamp.fromDate(_now),
      };

      final ctaLabel = _readString(data, 'ctaLabel');
      final ctaUrl = _readString(data, 'ctaUrl');
      if (ctaLabel != null && ctaLabel.isNotEmpty) {
        payload['ctaLabel'] = ctaLabel;
      }
      if (ctaUrl != null && ctaUrl.isNotEmpty) {
        payload['ctaUrl'] = ctaUrl;
      }

      final startDate = data['startDate'];
      final endDate = data['endDate'];
      if (startDate != null) {
        payload['startDate'] = startDate;
      }
      if (endDate != null) {
        payload['endDate'] = endDate;
      }

      await _setDocument(doc.reference, payload);
    }

    _log('Migrated ${snapshot.docs.length} announcement documents.');
  }

  Future<void> _seedFacultyInfo() async {
    _log('Preparing faculty_info/fast...');
    final departmentsSnapshot =
        await _firestore.collection('departments').get();
    final staffSnapshot = await _firestore.collection('staff').get();

    var programCount = 0;
    for (final department in departmentsSnapshot.docs) {
      final programs = await department.reference.collection('programs').get();
      programCount += programs.docs.length;
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? dean;
    for (final doc in staffSnapshot.docs) {
      final data = doc.data();
      final roleType = _readString(data, 'roleType') ?? '';
      final position = _readString(data, 'position') ?? '';
      if (roleType == 'dean' || position.toLowerCase().contains('dean')) {
        dean = doc;
        break;
      }
    }

    final deanData = dean?.data() ?? <String, dynamic>{};

    final facultyRef = _firestore.collection('faculty_info').doc('fast');
    final snapshot = await facultyRef.get();
    final data = snapshot.data() ?? <String, dynamic>{};

    final deanName =
        _readString(data, 'deanName') ??
        _readString(data, 'dean_name') ??
        _readString(deanData, 'name') ??
        'Dean, FAST';
    final deanMessage =
        _readString(data, 'deanMessage') ??
        _readString(data, 'dean_message') ??
        'Welcome to FAST. Discover our departments, people, achievements, and opportunities through one connected faculty platform.';
    final deanPhotoUrl =
        _readString(data, 'deanPhotoUrl') ??
        _readString(data, 'dean_photo_url') ??
        _readString(deanData, 'photoUrl') ??
        '';
    final heroImageUrl =
        _readString(data, 'heroImageUrl') ??
        _readString(data, 'faculty_image_url') ??
        '';
    final vision =
        _readString(data, 'vision') ??
        _readString(data, 'faculty_vision') ??
        'To be a leading faculty in applied sciences, technology, innovation, and student success.';
    final mission =
        _readString(data, 'mission') ??
        _readString(data, 'faculty_mission') ??
        'To provide transformative education, research, innovation, and community engagement in science and technology.';

    final payload = <String, dynamic>{
      'name':
          _readString(data, 'name') ??
          'Faculty of Applied Sciences and Technology',
      'shortName': _readString(data, 'shortName') ?? 'FAST',
      'appName': _readString(data, 'appName') ?? 'FAST Connect',
      'heroTitle': _readString(data, 'heroTitle') ?? 'Explore FAST',
      'heroSubtitle':
          _readString(data, 'heroSubtitle') ??
          'A faculty platform for branding, discovery, updates, and student support.',
      'heroImageUrl': heroImageUrl,
      'overview':
          _readString(data, 'overview') ??
          'FAST brings together departments, people, programs, stories, and support resources in one experience.',
      'vision': vision,
      'mission': mission,
      'stats': [
        {'label': 'Departments', 'value': departmentsSnapshot.docs.length},
        {'label': 'Programs', 'value': programCount},
        {'label': 'Staff', 'value': staffSnapshot.docs.length},
      ],
      'deanId': _readString(data, 'deanId') ?? dean?.id ?? 'deans1',
      'deanName': deanName,
      'deanMessage': deanMessage,
      'deanPhotoUrl': deanPhotoUrl,
      'contactEmail': _readString(data, 'contactEmail') ?? '',
      'contactPhone': _readString(data, 'contactPhone') ?? '',
      'websiteUrl': _readString(data, 'websiteUrl') ?? '',
      'socialLinks':
          _readMap(data, 'socialLinks') ??
          <String, dynamic>{'facebook': '', 'linkedin': '', 'youtube': ''},
      'createdAt': data['createdAt'] ?? Timestamp.fromDate(_now),
      'updatedAt': Timestamp.fromDate(_now),
      'dean_name': deanName,
      'dean_message': deanMessage,
      'dean_photo_url': deanPhotoUrl,
      'faculty_image_url': heroImageUrl,
      'faculty_vision': vision,
      'faculty_mission': mission,
      'faculty_values': _readStringList(
        data,
        'faculty_values',
        fallback: const [
          'Excellence in teaching and learning',
          'Research and innovation',
          'Integrity and accountability',
          'Collaboration and community impact',
        ],
      ),
    };

    await _setDocument(facultyRef, payload);
    _log('Upserted faculty_info/fast.');
  }

  Future<void> _seedFeaturedStories() async {
    _log('Seeding featured_stories...');
    final stories = <FirestoreSeed>[
      FirestoreSeed(
        id: 'fast-featured-story',
        data: {
          'title': 'FAST Connect expands into a full faculty platform',
          'summary':
              'FAST Connect now brings together faculty updates, people, departments, opportunities, and student support in one place.',
          'content':
              'The FAST platform is evolving from a first-year orientation app into a broader faculty experience that supports visibility, communication, discovery, and student success.',
          'imageUrl': '',
          'authorName': 'FAST Communications Team',
          'departmentIds': <String>[],
          'personIds': <String>[],
          'publishedAt': Timestamp.fromDate(_now),
          'featured': true,
          'order': 1,
          'status': 'published',
          'createdAt': Timestamp.fromDate(_now),
          'updatedAt': Timestamp.fromDate(_now),
        },
      ),
    ];

    final collection = _firestore.collection('featured_stories');
    for (final story in stories) {
      await _setDocument(collection.doc(story.id), story.data);
    }
  }

  Future<void> _seedOrientationContent() async {
    _log(
      'Skipping generic orientation_content seed. Add real entries from Admin Content Hub.',
    );
  }

  Future<void> _seedSupportResources() async {
    _log('Seeding support_resources...');
    final resources = <FirestoreSeed>[
      FirestoreSeed(
        id: 'academic-support',
        data: {
          'title': 'Academic Support',
          'category': 'academic',
          'description':
              'Support for registration questions, course guidance, and academic concerns.',
          'contactEmail': '',
          'contactPhone': '',
          'location': '',
          'url': '',
          'audience': ['students'],
          'order': 1,
          'status': 'published',
          'createdAt': Timestamp.fromDate(_now),
          'updatedAt': Timestamp.fromDate(_now),
        },
      ),
      FirestoreSeed(
        id: 'student-wellbeing',
        data: {
          'title': 'Student Wellbeing',
          'category': 'wellbeing',
          'description':
              'Guidance, welfare, and student support contacts for wellbeing and campus life.',
          'contactEmail': '',
          'contactPhone': '',
          'location': '',
          'url': '',
          'audience': ['students'],
          'order': 2,
          'status': 'published',
          'createdAt': Timestamp.fromDate(_now),
          'updatedAt': Timestamp.fromDate(_now),
        },
      ),
      FirestoreSeed(
        id: 'ict-helpdesk',
        data: {
          'title': 'ICT Helpdesk',
          'category': 'technology',
          'description':
              'Technical support for app access, student systems, and online services.',
          'contactEmail': '',
          'contactPhone': '',
          'location': '',
          'url': '',
          'audience': ['students', 'staff'],
          'order': 3,
          'status': 'published',
          'createdAt': Timestamp.fromDate(_now),
          'updatedAt': Timestamp.fromDate(_now),
        },
      ),
    ];

    final collection = _firestore.collection('support_resources');
    for (final resource in resources) {
      await _setDocument(collection.doc(resource.id), resource.data);
    }
  }

  Future<void> _seedQuickLinksCollection() async {
    _log('Seeding quick_links overrides...');
    final collection = _firestore.collection('quick_links');
    final quickLinks = <FirestoreSeed>[
      FirestoreSeed(
        id: 'sims_student_portal',
        data: {
          'title': 'SIMS STUDENT PORTAL',
          'subtitle': 'Registration, records and academic services',
          'url': 'https://student-portal.must.ac.ug/',
          'order': 1,
          'enabled': true,
        },
      ),
      FirestoreSeed(
        id: 'must_intelligent_student_advisor',
        data: {
          'title': 'MUST Intelligent Student Advisor',
          'subtitle': 'Student support and guidance',
          'url': 'https://misa.must.ac.ug/',
          'order': 2,
          'enabled': true,
        },
      ),
      FirestoreSeed(
        id: 'must_e_learning_platform',
        data: {
          'title': 'MUST E-LEARNING PLATFORM',
          'subtitle': 'Virtual learning environment',
          'url': 'https://vle.must.ac.ug/',
          'order': 3,
          'enabled': true,
        },
      ),
      FirestoreSeed(
        id: 'must_timetable',
        data: {
          'title': 'MUST TIMETABLE',
          'subtitle': 'Teaching and class schedules',
          'url': 'https://timetable.must.ac.ug/',
          'order': 4,
          'enabled': true,
        },
      ),
    ];

    for (final link in quickLinks) {
      await _setDocument(collection.doc(link.id), link.data);
    }
  }

  Future<void> _setDocument(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> data,
  ) async {
    if (dryRun) {
      _log('DRY RUN -> ${reference.path}');
      return;
    }

    await reference.set(data, SetOptions(merge: true));
  }

  List<Map<String, dynamic>> _normalizeCourses(dynamic rawCourses) {
    if (rawCourses is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawCourses.whereType<Map>().map((course) {
      final typed = Map<String, dynamic>.from(course);
      return <String, dynamic>{
        'code': _readString(typed, 'code') ?? '',
        'name': _readString(typed, 'name') ?? '',
        'description': _readString(typed, 'description') ?? '',
        'credits': _readInt(typed, 'credits') ?? 0,
        if (typed.containsKey('semester'))
          'semester': _readInt(typed, 'semester') ?? typed['semester'],
      };
    }).toList();
  }

  String _inferAnnouncementType(Map<String, dynamic> data) {
    final category = (_readString(data, 'category') ?? '').toLowerCase();
    final title = (_readString(data, 'title') ?? '').toLowerCase();
    final description = (_readString(data, 'description') ?? '').toLowerCase();

    if (category.contains('event') ||
        title.contains('event') ||
        title.contains('summit') ||
        title.contains('fair') ||
        title.contains('ceremony')) {
      return 'event';
    }

    if (category.contains('deadline') ||
        title.contains('deadline') ||
        description.contains('deadline')) {
      return 'deadline';
    }

    if (title.contains('opportunit') ||
        title.contains('scholarship') ||
        title.contains('research')) {
      return 'opportunity';
    }

    return 'announcement';
  }

  String _inferRoleType(String position) {
    final normalized = position.toLowerCase();
    if (normalized.contains('dean')) {
      return 'dean';
    }
    if (normalized.contains('head')) {
      return 'hod';
    }
    if (normalized.contains('contact') ||
        normalized.contains('support') ||
        normalized.contains('administrator')) {
      return 'key_contact';
    }
    return 'staff';
  }

  String _inferAward(String programName) {
    final normalized = programName.toLowerCase();
    if (normalized.contains('master')) {
      return 'Master';
    }
    if (normalized.contains('phd') || normalized.contains('doctor')) {
      return 'Doctorate';
    }
    if (normalized.contains('diploma')) {
      return 'Diploma';
    }
    if (normalized.contains('certificate')) {
      return 'Certificate';
    }
    return 'Bachelor';
  }

  int _parseYearFromId(String id) {
    final match = RegExp(r'(\d+)').firstMatch(id);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  String _buildShortName(String name) {
    final words =
        name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();

    if (words.length == 1) {
      return words.first;
    }

    return words
        .where(
          (word) =>
              word.length > 2 || word == words.first || word == words.last,
        )
        .map((word) => word[0].toUpperCase())
        .join();
  }

  String _buildShortDescription(String description, String name) {
    if (description.isEmpty) {
      return 'Learn more about $name at FAST.';
    }

    if (description.length <= 140) {
      return description;
    }

    return '${description.substring(0, 137).trim()}...';
  }

  String _slugify(String value) {
    final lowered = value.toLowerCase();
    final normalized = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Map<String, dynamic>? _readMap(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String? _readString(Map<String, dynamic>? data, String key) {
    if (data == null) {
      return null;
    }

    final value = data[key];
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _readInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  bool? _readBool(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is bool ? value : null;
  }

  List<String> _readStringList(
    Map<String, dynamic> data,
    String key, {
    List<String> fallback = const <String>[],
  }) {
    final value = data[key];
    if (value is! List) {
      return List<String>.from(fallback);
    }

    final items =
        value
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList();

    return items.isEmpty ? List<String>.from(fallback) : items;
  }

  void _log(String message) {
    stdout.writeln(message);
  }
}

class FirestoreSeed {
  const FirestoreSeed({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

class DepartmentSeed extends FirestoreSeed {
  const DepartmentSeed({
    required super.id,
    required super.data,
    required this.programs,
  });

  final List<ProgramSeed> programs;
}

class ProgramSeed extends FirestoreSeed {
  const ProgramSeed({
    required super.id,
    required super.data,
    required this.yearCourses,
  });

  final List<FirestoreSeed> yearCourses;
}

List<DepartmentSeed> _sampleDepartments() {
  final now = Timestamp.now();

  return <DepartmentSeed>[
    DepartmentSeed(
      id: '1',
      data: {
        'id': '1',
        'name': 'Electrical and Electronics Engineering',
        'shortName': 'EEE',
        'slug': 'electrical-and-electronics-engineering',
        'description':
            'The department focuses on electrical systems, electronics, energy, automation, and innovation in engineering practice.',
        'shortDescription':
            'Explore electrical systems, electronics, energy, and automation.',
        'imageUrl': '',
        'headName': 'Head of Department',
        'headTitle': 'Head of Department',
        'headImageUrl': '',
        'headMessage':
            'Welcome to a department committed to practical engineering, innovation, and student growth.',
        'contactEmail': '',
        'contactPhone': '',
        'location': '',
        'featured': true,
        'order': 1,
        'facilities': ['Electrical Machines Lab', 'Electronics Lab'],
        'achievements': ['Student innovation showcases'],
        'status': 'published',
        'createdAt': now,
        'updatedAt': now,
      },
      programs: [
        ProgramSeed(
          id: 'bachelor-electrical-and-electronics-engineering',
          data: {
            'name': 'Bachelor of Electrical and Electronics Engineering',
            'award': 'Bachelor',
            'slug': 'bachelor-of-electrical-and-electronics-engineering',
            'summary':
                'A professional programme focused on electrical systems, power, electronics, and communication engineering.',
            'durationYears': 4,
            'studyMode': 'full-time',
            'intake': ['August'],
            'entryRequirements': '',
            'careerPaths': ['Power systems', 'Telecommunications'],
            'brochureUrl': '',
            'featured': true,
            'order': 1,
            'status': 'published',
            'createdAt': now,
            'updatedAt': now,
          },
          yearCourses: [
            FirestoreSeed(
              id: 'year1',
              data: {
                'year': 1,
                'courses': [
                  {
                    'code': 'EEE101',
                    'name': 'Introduction to Electrical Engineering',
                    'description':
                        'A foundation course introducing core principles and concepts in electrical engineering.',
                    'credits': 3,
                  },
                  {
                    'code': 'MTH101',
                    'name': 'Engineering Mathematics I',
                    'description':
                        'Mathematics tools used across engineering disciplines.',
                    'credits': 4,
                  },
                ],
                'updatedAt': now,
              },
            ),
          ],
        ),
      ],
    ),
    DepartmentSeed(
      id: '2',
      data: {
        'id': '2',
        'name': 'Computer Science and Information Technology',
        'shortName': 'CSIT',
        'slug': 'computer-science-and-information-technology',
        'description':
            'The department covers software development, networking, data systems, and digital innovation.',
        'shortDescription':
            'Study software, systems, networking, and digital innovation.',
        'imageUrl': '',
        'headName': 'Head of Department',
        'headTitle': 'Head of Department',
        'headImageUrl': '',
        'headMessage':
            'Discover a department shaping digital solutions, innovation, and future-ready graduates.',
        'contactEmail': '',
        'contactPhone': '',
        'location': '',
        'featured': true,
        'order': 2,
        'facilities': ['Programming Lab', 'Networking Lab'],
        'achievements': ['Student software exhibitions'],
        'status': 'published',
        'createdAt': now,
        'updatedAt': now,
      },
      programs: [
        ProgramSeed(
          id: 'bachelor-computer-science',
          data: {
            'name': 'Bachelor of Computer Science',
            'award': 'Bachelor',
            'slug': 'bachelor-of-computer-science',
            'summary':
                'A programme focused on computing theory, software engineering, data, and modern digital systems.',
            'durationYears': 3,
            'studyMode': 'full-time',
            'intake': ['August'],
            'entryRequirements': '',
            'careerPaths': ['Software engineering', 'Data systems'],
            'brochureUrl': '',
            'featured': true,
            'order': 1,
            'status': 'published',
            'createdAt': now,
            'updatedAt': now,
          },
          yearCourses: [
            FirestoreSeed(
              id: 'year1',
              data: {
                'year': 1,
                'courses': [
                  {
                    'code': 'CSC101',
                    'name': 'Introduction to Programming',
                    'description':
                        'Foundational programming concepts and problem-solving.',
                    'credits': 4,
                  },
                  {
                    'code': 'CSC102',
                    'name': 'Computer Systems Fundamentals',
                    'description':
                        'An introduction to how computer systems and software platforms work.',
                    'credits': 3,
                  },
                ],
                'updatedAt': now,
              },
            ),
          ],
        ),
      ],
    ),
  ];
}

List<FirestoreSeed> _sampleStaff() {
  final now = Timestamp.now();

  return <FirestoreSeed>[
    FirestoreSeed(
      id: 'deans1',
      data: {
        'name': 'Dean, FAST',
        'position': 'Dean',
        'roleType': 'dean',
        'department': '',
        'departmentName': '',
        'email': '',
        'phone': '',
        'office': '',
        'linkedinUrl': '',
        'photoUrl': '',
        'bio':
            'Faculty leadership profile for the Dean of the Faculty of Applied Sciences and Technology.',
        'specialties': <String>[],
        'isKeyContact': true,
        'featured': true,
        'order': 1,
        'status': 'published',
        'createdAt': now,
        'updatedAt': now,
      },
    ),
    FirestoreSeed(
      id: 'student-support-1',
      data: {
        'name': 'Student Support Officer',
        'position': 'Student Support Officer',
        'roleType': 'key_contact',
        'department': '',
        'departmentName': '',
        'email': '',
        'phone': '',
        'office': '',
        'linkedinUrl': '',
        'photoUrl': '',
        'bio':
            'A key FAST contact for student guidance, support, and referrals.',
        'specialties': ['Student guidance', 'Support referrals'],
        'isKeyContact': true,
        'featured': true,
        'order': 2,
        'status': 'published',
        'createdAt': now,
        'updatedAt': now,
      },
    ),
  ];
}

List<FirestoreSeed> _sampleAnnouncements() {
  final now = DateTime.now();

  return <FirestoreSeed>[
    FirestoreSeed(
      id: 'welcome-fast-connect',
      data: {
        'title': 'Welcome to FAST Connect',
        'description':
            'FAST Connect now brings together faculty visibility, updates, discovery, and student support in one place.',
        'category': 'General',
        'type': 'announcement',
        'priority': 'important',
        'isPinned': true,
        'featured': true,
        'imageUrls': <String>[],
        'tags': ['welcome', 'fast-connect', 'faculty-platform'],
        'views': 0,
        'audience': ['all-users'],
        'departmentIds': <String>[],
        'status': 'published',
        'postedAt': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      },
    ),
    FirestoreSeed(
      id: 'research-opportunity-call',
      data: {
        'title': 'Research Opportunity Call',
        'description':
            'Students are invited to explore new research opportunities across FAST departments and labs.',
        'category': 'Academic',
        'type': 'opportunity',
        'priority': 'normal',
        'isPinned': false,
        'featured': false,
        'imageUrls': <String>[],
        'tags': ['research', 'opportunity'],
        'views': 0,
        'audience': ['students'],
        'departmentIds': <String>[],
        'status': 'published',
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'updatedAt': Timestamp.fromDate(now),
      },
    ),
  ];
}
