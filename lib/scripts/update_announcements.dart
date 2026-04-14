// Replace the content of your scripts/update_announcements.dart file with this:

import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateAnnouncementsScript {
  static Future<void> updateAnnouncements({bool clearExisting = true}) async {
    print('🚀 Starting announcements update...');

    try {
      final CollectionReference announcementsRef = 
          FirebaseFirestore.instance.collection('announcements');

      // Step 1: Migrate existing announcements (if any)
      if (!clearExisting) {
        await _migrateLegacyAnnouncements(announcementsRef);
      }

      // Step 2: Clear existing announcements if requested
      if (clearExisting) {
        print('🗑️ Clearing existing announcements...');
        final existingAnnouncements = await announcementsRef.get();
        for (var doc in existingAnnouncements.docs) {
          await doc.reference.delete();
        }
        print('✅ Cleared ${existingAnnouncements.docs.length} existing announcements');
      }

      // Step 3: Add new sample announcements
      final sampleAnnouncements = _getSampleAnnouncements();
      
      for (var announcement in sampleAnnouncements) {
        await announcementsRef.add(announcement);
        print('✅ Added announcement: ${announcement['title']}');
      }

      print('🎉 Announcements update completed successfully!');
      print('📊 Added ${sampleAnnouncements.length} new announcements');
      
    } catch (e) {
      print('❌ Error updating announcements: $e');
      rethrow;
    }
  }

  // Migrate legacy announcements to new format
  static Future<void> _migrateLegacyAnnouncements(CollectionReference announcementsRef) async {
    print('🔄 Migrating legacy announcements...');
    
    final snapshot = await announcementsRef.get();
    int migratedCount = 0;
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      bool needsUpdate = false;
      Map<String, dynamic> updates = {};
      
      // Check and add missing fields
      if (!data.containsKey('priority')) {
        updates['priority'] = 'normal';
        needsUpdate = true;
      }
      
      if (!data.containsKey('isPinned')) {
        updates['isPinned'] = false;
        needsUpdate = true;
      }
      
      if (!data.containsKey('tags')) {
        updates['tags'] = <String>[];
        needsUpdate = true;
      }
      
      if (!data.containsKey('views')) {
        updates['views'] = 0;
        needsUpdate = true;
      }
      
      // Handle imageUrls migration
      if (!data.containsKey('imageUrls')) {
        if (data.containsKey('imageUrl') && data['imageUrl'] != null) {
          updates['imageUrls'] = [data['imageUrl']];
        } else {
          updates['imageUrls'] = <String>[];
        }
        needsUpdate = true;
      }
      
      if (needsUpdate) {
        await doc.reference.update(updates);
        migratedCount++;
      }
    }
    
    print('✅ Migrated $migratedCount legacy announcements');
  }

  // Generate comprehensive sample announcements
  static List<Map<String, dynamic>> _getSampleAnnouncements() {
    final now = DateTime.now();
    
    return [
      {
        'title': 'Welcome to FAST Connect 2025',
        'description': 'We are excited to announce the launch of FAST Connect, your new digital platform for staying updated with all Faculty of Applied Sciences and Technology announcements. Get real-time notifications, access important documents, and never miss important updates from your faculty.',
        'category': 'General',
        'priority': 'important',
        'isPinned': true,
        'tags': ['welcome', 'app-launch', 'fast-connect', 'digital-platform'],
        'views': 0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1551434678-e076c223a692?q=80&w=2070&auto=format&fit=crop',
        ],
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      },
      {
        'title': 'Final Examination Timetable Released',
        'description': 'The final examination timetable for Semester 1, Academic Year 2024/2025 has been officially released. All students are strongly advised to check their examination schedules carefully and report any conflicts or issues to the academic office within 48 hours of this announcement.',
        'category': 'Academic',
        'priority': 'urgent',
        'isPinned': true,
        'tags': ['exams', 'timetable', 'semester1', 'academic-year-2024-2025'],
        'views': 0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?q=80&w=2070&auto=format&fit=crop',
        ],
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
      },
      {
        'title': 'FAST Tech Innovation Summit 2025',
        'description': 'Join us for the annual FAST Tech Innovation Summit on March 15, 2025, at the MUST Main Auditorium. Students will showcase their final year projects, and industry leaders will share insights on emerging technologies including AI, IoT, and renewable energy. Registration is now open on the student portal.',
        'category': 'Events',
        'priority': 'important',
        'isPinned': false,
        'tags': ['innovation', 'summit', 'technology', 'final-year-projects', 'ai', 'iot'],
        'views': 0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?q=80&w=2070&auto=format&fit=crop',
          'https://images.unsplash.com/photo-1556761175-b413da4baf72?q=80&w=2070&auto=format&fit=crop',
        ],
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'title': 'Library Extended Hours During Exam Period',
        'description': 'The MUST library will extend operating hours during the examination period (July 20 - August 10, 2025). New operating hours: Monday-Friday: 6:00 AM - 12:00 AM, Saturday-Sunday: 8:00 AM - 10:00 PM. Additional study spaces and computer labs will also be available.',
        'category': 'General',
        'priority': 'normal',
        'isPinned': false,
        'tags': ['library', 'extended-hours', 'exam-period', 'study-spaces'],
        'views': 0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=2070&auto=format&fit=crop',
        ],
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
      },
      {
        'title': 'Course Registration Deadline Extended',
        'description': 'Due to technical issues with the student portal over the weekend, the course registration deadline has been extended to July 25, 2025, at 11:59 PM. Students who experienced difficulties during the original deadline can now complete their registration without incurring late fees.',
        'category': 'Deadlines',
        'priority': 'urgent',
        'isPinned': false,
        'tags': ['registration', 'deadline', 'extension', 'student-portal'],
        'views': 0,
        'imageUrls': [],
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
      {
        'title': 'New Research Opportunities in Emerging Technologies',
        'description': 'The Faculty is offering exciting new research opportunities in Artificial Intelligence, Renewable Energy Systems, and Biotechnology. Interested undergraduate and graduate students should submit their applications along with a brief research proposal by August 1, 2025. Funded positions available.',
        'category': 'Academic',
        'priority': 'normal',
        'isPinned': false,
        'tags': ['research', 'opportunities', 'ai', 'renewable-energy', 'biotechnology', 'funded'],
        'views': 0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?q=80&w=2070&auto=format&fit=crop',
        ],
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
      },
      {
        'title': 'Student Mental Health and Wellness Week',
        'description': 'Join us for Student Mental Health and Wellness Week from July 22-26, 2025. Activities include wellness workshops, stress management sessions, mindfulness training, and free counseling services. Remember, your mental health matters! All events are free for students.',
        'category': 'Events',
        'priority': 'important',
        'isPinned': false,
        'tags': ['mental-health', 'wellness', 'counseling', 'stress-management', 'mindfulness'],
        'views': 0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=2070&auto=format&fit=crop',
        ],
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      },
      {
        'title': 'Campus Network Maintenance Scheduled',
        'description': 'Scheduled campus network maintenance will take place on Sunday, July 21, 2025, from 2:00 AM to 6:00 AM. Internet services, including WiFi and wired connections, may be intermittent during this period. We apologize for any inconvenience and appreciate your patience.',
        'category': 'General',
        'priority': 'normal',
        'isPinned': false,
        'tags': ['network', 'maintenance', 'internet', 'wifi', 'scheduled-downtime'],
        'views': 0,
        'imageUrls': [],
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(days: 6))),
      },
      {
        'title': 'Merit-Based Scholarships Applications Open',
        'description': 'Merit-based scholarships for the 2025/2026 academic year are now available for application. Scholarships cover up to 75% of tuition fees for outstanding students. Applications must be submitted through the student portal by August 15, 2025. Eligibility criteria and application forms are available online.',
        'category': 'Academic',
        'priority': 'important',
        'isPinned': false,
        'tags': ['scholarships', 'merit-based', 'tuition', 'applications', 'financial-aid'],
        'views': 0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=2070&auto=format&fit=crop',
        ],
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
      },
      {
        'title': '2025 Graduation Ceremony Information',
        'description': 'The 2025 graduation ceremony will be held on August 30, 2025, at 10:00 AM in the MUST Main Hall. All graduating students must confirm their attendance by August 1, 2025. Academic regalia rental information and ceremony details will be sent via email to confirmed participants.',
        'category': 'Events',
        'priority': 'important',
        'isPinned': false,
        'tags': ['graduation', 'ceremony', 'academic-regalia', 'confirmation'],
        'views': 0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?q=80&w=2070&auto=format&fit=crop',
        ],
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(days: 8))),
      },
      {
        'title': 'New Laboratory Equipment Installation',
        'description': 'State-of-the-art laboratory equipment has been installed in the Engineering Labs (Blocks A and B). The new equipment includes advanced testing machines, 3D printers, and computer-controlled systems. Training sessions for students and staff will begin next week.',
        'category': 'Academic',
        'priority': 'normal',
        'isPinned': false,
        'tags': ['laboratory', 'equipment', 'engineering', '3d-printers', 'training'],
        'views': 0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1567427017947-545c5f8d16ad?q=80&w=2070&auto=format&fit=crop',
        ],
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(days: 9))),
      },
      {
        'title': 'Industry Partnership Career Fair',
        'description': 'FAST is hosting a Career Fair on August 5, 2025, featuring partnerships with leading technology companies and engineering firms. Students can explore internship and job opportunities, attend company presentations, and network with industry professionals. Bring your updated CVs!',
        'category': 'Events',
        'priority': 'important',
        'isPinned': false,
        'tags': ['career-fair', 'industry', 'internships', 'jobs', 'networking', 'cv'],
        'views': 0,
        'imageUrls': [
          'https://images.unsplash.com/photo-1511632765486-a01980e01a18?q=80&w=2070&auto=format&fit=crop',
        ],
        'postedAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      },
    ];
  }

  // Optional: Clear all announcements (use with caution)
  static Future<void> clearAllAnnouncements() async {
    print('🗑️ Clearing all announcements...');
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('announcements')
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      print('✅ Cleared ${snapshot.docs.length} announcements');
    } catch (e) {
      print('❌ Failed to clear announcements: $e');
      rethrow;
    }
  }
}