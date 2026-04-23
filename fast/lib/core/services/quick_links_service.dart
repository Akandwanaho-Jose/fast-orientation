import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fast/core/models/quick_link.dart';
import 'package:fast/core/utils/constants.dart';

class QuickLinksService {
  QuickLinksService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'quick_links';

  static final List<QuickLink> defaultLinks = [
    QuickLink(
      id: 'sims_student_portal',
      title: 'SIMS STUDENT PORTAL',
      subtitle: 'Registration, records and academic services',
      url: 'https://student-portal.must.ac.ug/',
      icon: Icons.school_rounded,
      graphicAssetPath: 'assets/images/quick_links/sims_student_portal.png',
      color: mustBlue,
      gradientColors: const [mustBlue, Color(0xFF1A4AB8)],
      order: 1,
    ),
    QuickLink(
      id: 'must_intelligent_student_advisor',
      title: 'MUST Intelligent Student Advisor',
      subtitle: 'Student support and guidance',
      url: 'https://misa.must.ac.ug/',
      icon: Icons.smart_toy_rounded,
      graphicAssetPath: 'assets/images/quick_links/must_student_advisor.png',
      color: mustGreen,
      gradientColors: const [mustGreen, Color(0xFF34B65B)],
      order: 2,
    ),
    QuickLink(
      id: 'must_e_learning_platform',
      title: 'MUST E-LEARNING PLATFORM',
      subtitle: 'Virtual learning environment',
      url: 'https://vle.must.ac.ug/',
      icon: Icons.laptop_chromebook_rounded,
      graphicAssetPath: 'assets/images/quick_links/must_elearning.png',
      color: mustYellow,
      gradientColors: const [mustYellow, Color(0xFFFFD54F)],
      order: 3,
    ),
    QuickLink(
      id: 'must_timetable',
      title: 'MUST TIMETABLE',
      subtitle: 'Teaching and class schedules',
      url: 'https://timetable.must.ac.ug/',
      icon: Icons.schedule_rounded,
      graphicAssetPath: 'assets/images/quick_links/must_timetable.png',
      color: mustBlue,
      gradientColors: const [Color(0xFF00579B), Color(0xFF2D7CC0)],
      order: 4,
    ),
  ];

  static QuickLink? defaultLinkById(String id) {
    for (final link in defaultLinks) {
      if (link.id == id) {
        return link;
      }
    }
    return null;
  }

  Stream<List<QuickLink>> watchQuickLinks() {
    return _firestore.collection(collectionName).snapshots().map((snapshot) {
      final overridesById = <String, Map<String, dynamic>>{
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };

      final mergedLinks =
          defaultLinks.map((defaultLink) {
            final data = overridesById[defaultLink.id];
            if (data == null) {
              return defaultLink;
            }

            return defaultLink.copyWith(
              title: _readString(data, 'title') ?? defaultLink.title,
              subtitle: _readString(data, 'subtitle') ?? defaultLink.subtitle,
              url: _readUrl(data, 'url') ?? defaultLink.url,
              order: _readInt(data, 'order') ?? defaultLink.order,
              enabled: _readBool(data, 'enabled') ?? defaultLink.enabled,
            );
          }).where((link) => link.enabled).toList();

      mergedLinks.sort((a, b) => a.order.compareTo(b.order));
      return mergedLinks;
    });
  }

  Stream<List<QuickLink>> watchAdminQuickLinks() {
    return _firestore.collection(collectionName).snapshots().map((snapshot) {
      final overridesById = <String, Map<String, dynamic>>{
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };

      final mergedLinks =
          defaultLinks.map((defaultLink) {
            final data = overridesById[defaultLink.id];
            if (data == null) {
              return defaultLink;
            }

            return defaultLink.copyWith(
              title: _readString(data, 'title') ?? defaultLink.title,
              subtitle: _readString(data, 'subtitle') ?? defaultLink.subtitle,
              url: _readUrl(data, 'url') ?? defaultLink.url,
              order: _readInt(data, 'order') ?? defaultLink.order,
              enabled: _readBool(data, 'enabled') ?? defaultLink.enabled,
            );
          }).toList();

      mergedLinks.sort((a, b) => a.order.compareTo(b.order));
      return mergedLinks;
    });
  }

  Future<void> saveQuickLinkOverride(QuickLink link) async {
    await _firestore.collection(collectionName).doc(link.id).set({
      'title': link.title,
      'subtitle': link.subtitle,
      'url': link.url,
      'order': link.order,
      'enabled': link.enabled,
    }, SetOptions(merge: true));
  }

  Future<void> deleteQuickLinkOverride(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }

  String? _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _readUrl(Map<String, dynamic> data, String key) {
    final value = _readString(data, key);
    if (value == null) {
      return null;
    }

    final directUri = Uri.tryParse(value);
    if (directUri != null &&
        directUri.hasScheme &&
        (directUri.scheme == 'http' || directUri.scheme == 'https')) {
      return directUri.toString();
    }

    if (!value.contains('://')) {
      final httpsUri = Uri.tryParse('https://$value');
      if (httpsUri != null && httpsUri.host.isNotEmpty) {
        return httpsUri.toString();
      }
    }

    return null;
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
}
