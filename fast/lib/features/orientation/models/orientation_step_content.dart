import 'package:cloud_firestore/cloud_firestore.dart';

class OrientationStepContent {
  const OrientationStepContent({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.iconKey,
    required this.actionLabel,
    required this.actionUrl,
    required this.order,
    required this.status,
  });

  factory OrientationStepContent.fromMap(String id, Map<String, dynamic> data) {
    final title = _readString(data, 'title', _labelFromId(id));
    final summary = _readString(data, 'summary', '');
    final content = _readString(data, 'content', summary);

    return OrientationStepContent(
      id: id,
      title: title,
      summary: summary.isEmpty ? content : summary,
      content: content,
      iconKey: _readString(data, 'iconKey', id),
      actionLabel: _readNullableString(data, 'actionLabel'),
      actionUrl: _readNullableString(data, 'actionUrl'),
      order: _readInt(data, 'order', 0),
      status: _readString(data, 'status', 'published').toLowerCase(),
    );
  }

  final String id;
  final String title;
  final String summary;
  final String content;
  final String iconKey;
  final String? actionLabel;
  final String? actionUrl;
  final int order;
  final String status;

  bool get isPublished => status == 'published';
  bool get hasAction =>
      actionLabel?.trim().isNotEmpty == true &&
      actionUrl?.trim().isNotEmpty == true;

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      'iconKey': iconKey,
      if (actionLabel?.trim().isNotEmpty == true)
        'actionLabel': actionLabel!.trim(),
      if (actionUrl?.trim().isNotEmpty == true) 'actionUrl': actionUrl!.trim(),
      'order': order,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static int compareForDisplay(
    OrientationStepContent a,
    OrientationStepContent b,
  ) {
    final orderCompare = a.order.compareTo(b.order);
    if (orderCompare != 0) {
      return orderCompare;
    }
    return a.title.compareTo(b.title);
  }

  static const defaultSteps = <OrientationStepContent>[
    OrientationStepContent(
      id: 'admission',
      title: 'Admission',
      summary:
          'Confirm admission details, programme placement, and official reporting instructions.',
      content:
          'Confirm admission details, programme placement, and official reporting instructions from MUST and FAST.',
      iconKey: 'admission',
      actionLabel: null,
      actionUrl: null,
      order: 1,
      status: 'published',
    ),
    OrientationStepContent(
      id: 'registration',
      title: 'Registration',
      summary:
          'Complete required registration steps and keep student records accurate.',
      content:
          'Follow the registration notices, complete required forms, and keep your student records accurate.',
      iconKey: 'registration',
      actionLabel: null,
      actionUrl: null,
      order: 2,
      status: 'published',
    ),
    OrientationStepContent(
      id: 'fees',
      title: 'Fees',
      summary: 'Review official fees guidance and payment timelines.',
      content:
          'Review official fees guidance and payment timelines before registration deadlines.',
      iconKey: 'fees',
      actionLabel: null,
      actionUrl: null,
      order: 3,
      status: 'published',
    ),
    OrientationStepContent(
      id: 'academic_calendar',
      title: 'Academic Calendar',
      summary: 'Check semester dates and key academic deadlines.',
      content:
          'Check semester dates, teaching weeks, examination periods, and key academic deadlines.',
      iconKey: 'academic_calendar',
      actionLabel: null,
      actionUrl: null,
      order: 4,
      status: 'published',
    ),
    OrientationStepContent(
      id: 'campus_services',
      title: 'Campus Services',
      summary: 'Find services that support daily campus life.',
      content:
          'Find services that support daily campus life, including library, ICT, health, and student offices.',
      iconKey: 'campus_services',
      actionLabel: null,
      actionUrl: null,
      order: 5,
      status: 'published',
    ),
    OrientationStepContent(
      id: 'student_support',
      title: 'Student Support',
      summary: 'Know where to get academic guidance and welfare support.',
      content:
          'Use FAST and MUST contacts when you need academic guidance, welfare support, or help finding information.',
      iconKey: 'student_support',
      actionLabel: null,
      actionUrl: null,
      order: 6,
      status: 'published',
    ),
    OrientationStepContent(
      id: 'faqs',
      title: 'FAQs',
      summary: 'Browse common questions before contacting support offices.',
      content:
          'Browse common questions first, then use the published contacts when more help is needed.',
      iconKey: 'faqs',
      actionLabel: null,
      actionUrl: null,
      order: 7,
      status: 'published',
    ),
  ];

  static String _readString(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static String? _readNullableString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static int _readInt(Map<String, dynamic> data, String key, int fallback) {
    final value = data[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  static String _labelFromId(String id) {
    final label = id
        .split(RegExp(r'[-_\s]+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
    return label.isEmpty ? 'Orientation Step' : label;
  }
}
