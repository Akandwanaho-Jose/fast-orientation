import 'package:cloud_firestore/cloud_firestore.dart';

class OrientationContentItem {
  const OrientationContentItem({
    required this.id,
    required this.title,
    required this.slug,
    required this.type,
    required this.category,
    required this.summary,
    required this.content,
    required this.imageUrl,
    required this.audience,
    required this.departmentId,
    required this.actionLabel,
    required this.actionUrl,
    required this.pinned,
    required this.order,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory OrientationContentItem.fromMap(String id, Map<String, dynamic> data) {
    final title = _readString(data, 'title', 'Untitled section');
    final content = _readString(data, 'content', '');
    final summary = _readString(
      data,
      'summary',
      content.isEmpty ? 'No summary available yet.' : content,
    );
    final category = _readString(data, 'category', 'orientation');

    return OrientationContentItem(
      id: id,
      title: title,
      slug: _readString(data, 'slug', _slugify(title)),
      type: _readString(data, 'type', category),
      category: category,
      summary: summary,
      content: content,
      imageUrl: _readNullableString(data, 'imageUrl'),
      audience: _readStringList(data, 'audience'),
      departmentId: _readNullableString(data, 'departmentId'),
      actionLabel: _readNullableString(data, 'actionLabel'),
      actionUrl: _readNullableString(data, 'actionUrl'),
      pinned: _readBool(data, 'pinned', false),
      order: _readInt(data, 'order', 0),
      status: _readString(data, 'status', 'draft'),
      startDate: _readDateTime(data, 'startDate'),
      endDate: _readDateTime(data, 'endDate'),
    );
  }

  final String id;
  final String title;
  final String slug;
  final String type;
  final String category;
  final String summary;
  final String content;
  final String? imageUrl;
  final List<String> audience;
  final String? departmentId;
  final String? actionLabel;
  final String? actionUrl;
  final bool pinned;
  final int order;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get isPublished => status == 'published';
  bool get hasAction => actionUrl?.isNotEmpty == true;
  bool get hasDateRange => startDate != null || endDate != null;

  String get categoryLabel => _labelize(category.isEmpty ? type : category);
  String get typeLabel => _labelize(type.isEmpty ? category : type);

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'slug': slug,
      'type': type,
      'category': category,
      'summary': summary,
      'content': content,
      if (imageUrl?.isNotEmpty == true) 'imageUrl': imageUrl,
      'audience': audience,
      if (departmentId?.isNotEmpty == true) 'departmentId': departmentId,
      if (actionLabel?.isNotEmpty == true) 'actionLabel': actionLabel,
      if (actionUrl?.isNotEmpty == true) 'actionUrl': actionUrl,
      'pinned': pinned,
      'order': order,
      'status': status,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
    };
  }

  static int compareForDisplay(
    OrientationContentItem a,
    OrientationContentItem b,
  ) {
    if (a.pinned != b.pinned) {
      return a.pinned ? -1 : 1;
    }
    final orderCompare = a.order.compareTo(b.order);
    if (orderCompare != 0) {
      return orderCompare;
    }
    return a.title.compareTo(b.title);
  }

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

  static List<String> _readStringList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is List) {
      return value
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static bool _readBool(Map<String, dynamic> data, String key, bool fallback) {
    final value = data[key];
    return value is bool ? value : fallback;
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

  static DateTime? _readDateTime(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }

  static String _labelize(String value) {
    final label = value
        .split(RegExp(r'[-_\s]+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');

    return label.isEmpty ? 'Guide' : label;
  }

  static String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
