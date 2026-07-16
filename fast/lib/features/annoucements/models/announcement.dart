import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String description;
  final DateTime postedAt;
  final String? category;
  final String type;
  final List<String> imageUrls;
  final String priority;
  final bool isPinned;
  final bool featured;
  final List<String> tags;
  final List<String> audience;
  final List<String> departmentIds;
  final int views;
  final String status;
  final String? actionLabel;
  final String? actionUrl;
  final bool pushNotificationEnabled;
  final String? pushNotificationTitle;
  final String? pushNotificationBody;
  final String pushNotificationTopic;
  final String? pushNotificationStatus;
  final DateTime? pushNotificationSentAt;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.postedAt,
    this.category,
    this.type = 'announcement',
    this.imageUrls = const [],
    this.priority = 'normal',
    this.isPinned = false,
    this.featured = false,
    this.tags = const [],
    this.audience = const [],
    this.departmentIds = const [],
    this.views = 0,
    this.status = 'published',
    this.actionLabel,
    this.actionUrl,
    this.pushNotificationEnabled = false,
    this.pushNotificationTitle,
    this.pushNotificationBody,
    this.pushNotificationTopic = 'announcements',
    this.pushNotificationStatus,
    this.pushNotificationSentAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json, String id) {
    try {
      final resolvedType =
          _getNullableString(json, 'type')?.toLowerCase() ?? 'announcement';

      return Announcement(
        id: id,
        title: _getStringValue(json, 'title', 'Untitled'),
        description: _getStringValue(
          json,
          'description',
          'No description available',
        ),
        postedAt: _getDateTimeValue(json, 'postedAt'),
        category:
            _getNullableString(json, 'category') ??
            _categoryFromType(resolvedType),
        type: resolvedType,
        imageUrls: _getImageUrls(json),
        priority: _getStringValue(json, 'priority', 'normal').toLowerCase(),
        isPinned: _getBoolValue(json, 'isPinned', false),
        featured: _getBoolValue(json, 'featured', false),
        tags: _getStringList(json, 'tags'),
        audience: _getStringList(json, 'audience'),
        departmentIds: _getStringList(json, 'departmentIds'),
        views: _getIntValue(json, 'views', 0),
        status: _getStringValue(json, 'status', 'published').toLowerCase(),
        actionLabel: _getNullableString(json, 'actionLabel'),
        actionUrl: _getNullableString(json, 'actionUrl'),
        pushNotificationEnabled: _getPushBoolValue(json, 'enabled', false),
        pushNotificationTitle: _getPushNullableString(json, 'title'),
        pushNotificationBody: _getPushNullableString(json, 'body'),
        pushNotificationTopic: _getPushStringValue(
          json,
          'topic',
          _defaultNotificationTopic(
            resolvedType,
            _getStringValue(json, 'priority', 'normal').toLowerCase(),
          ),
        ),
        pushNotificationStatus: _getPushNullableString(json, 'status'),
        pushNotificationSentAt: _getPushDateTimeValue(json, 'sentAt'),
      );
    } catch (e) {
      return Announcement(
        id: id,
        title: 'Error Loading Update',
        description:
            'This item could not be loaded properly. Please try again later.',
        postedAt: DateTime.now(),
        category: 'General',
      );
    }
  }

  static String _getStringValue(
    Map<String, dynamic> json,
    String key,
    String fallback,
  ) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static String? _getNullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static bool _getBoolValue(
    Map<String, dynamic> json,
    String key,
    bool defaultValue,
  ) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    return defaultValue;
  }

  static int _getIntValue(
    Map<String, dynamic> json,
    String key,
    int defaultValue,
  ) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? defaultValue;
    }
    return defaultValue;
  }

  static DateTime _getDateTimeValue(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return DateTime.now();
    }

    try {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
    } catch (_) {
      return DateTime.now();
    }

    return DateTime.now();
  }

  static List<String> _getStringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) {
      return const [];
    }

    return value
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _getImageUrls(Map<String, dynamic> json) {
    final imageUrls = json['imageUrls'];
    if (imageUrls is List) {
      final urls = imageUrls
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
      if (urls.isNotEmpty) {
        return urls;
      }
    }

    final imageUrl = _getNullableString(json, 'imageUrl');
    return imageUrl == null ? const [] : <String>[imageUrl];
  }

  static String _categoryFromType(String type) {
    switch (type) {
      case 'event':
        return 'Events';
      case 'deadline':
        return 'Deadlines';
      case 'opportunity':
        return 'Opportunities';
      default:
        return 'Announcements';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'postedAt': Timestamp.fromDate(postedAt),
      'category': category,
      'type': type,
      'imageUrls': imageUrls,
      'priority': priority,
      'isPinned': isPinned,
      'featured': featured,
      'tags': tags,
      'audience': audience,
      'departmentIds': departmentIds,
      'views': views,
      'status': status,
      if (actionLabel?.isNotEmpty == true) 'actionLabel': actionLabel,
      if (actionUrl?.isNotEmpty == true) 'actionUrl': actionUrl,
      'pushNotification': {
        'enabled': pushNotificationEnabled,
        if (pushNotificationTitle?.isNotEmpty == true)
          'title': pushNotificationTitle,
        if (pushNotificationBody?.isNotEmpty == true)
          'body': pushNotificationBody,
        'topic': pushNotificationTopic,
        if (pushNotificationStatus?.isNotEmpty == true)
          'status': pushNotificationStatus,
        if (pushNotificationSentAt != null)
          'sentAt': Timestamp.fromDate(pushNotificationSentAt!),
      },
    };
  }

  bool get isUrgent => priority == 'urgent';
  bool get isImportant => priority == 'important';
  bool get hasImages => imageUrls.isNotEmpty;
  bool get isPublished => status == 'published';
  bool get isFeatureCard => featured || isPinned || isUrgent;
  String get mainImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  String get displayType => _titleCase(type.replaceAll('_', ' '));
  String get displayCategory =>
      category?.trim().isNotEmpty == true
          ? category!.trim()
          : _categoryFromType(type);
  bool get hasAction =>
      actionLabel?.isNotEmpty == true && actionUrl?.isNotEmpty == true;
  bool get hasSentPushNotification => pushNotificationStatus == 'sent';

  Announcement copyWith({
    String? title,
    String? description,
    DateTime? postedAt,
    String? category,
    String? type,
    List<String>? imageUrls,
    String? priority,
    bool? isPinned,
    bool? featured,
    List<String>? tags,
    List<String>? audience,
    List<String>? departmentIds,
    int? views,
    String? status,
    String? actionLabel,
    String? actionUrl,
    bool? pushNotificationEnabled,
    String? pushNotificationTitle,
    String? pushNotificationBody,
    String? pushNotificationTopic,
    String? pushNotificationStatus,
    DateTime? pushNotificationSentAt,
  }) {
    return Announcement(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      postedAt: postedAt ?? this.postedAt,
      category: category ?? this.category,
      type: type ?? this.type,
      imageUrls: imageUrls ?? this.imageUrls,
      priority: priority ?? this.priority,
      isPinned: isPinned ?? this.isPinned,
      featured: featured ?? this.featured,
      tags: tags ?? this.tags,
      audience: audience ?? this.audience,
      departmentIds: departmentIds ?? this.departmentIds,
      views: views ?? this.views,
      status: status ?? this.status,
      actionLabel: actionLabel ?? this.actionLabel,
      actionUrl: actionUrl ?? this.actionUrl,
      pushNotificationEnabled:
          pushNotificationEnabled ?? this.pushNotificationEnabled,
      pushNotificationTitle:
          pushNotificationTitle ?? this.pushNotificationTitle,
      pushNotificationBody: pushNotificationBody ?? this.pushNotificationBody,
      pushNotificationTopic:
          pushNotificationTopic ?? this.pushNotificationTopic,
      pushNotificationStatus:
          pushNotificationStatus ?? this.pushNotificationStatus,
      pushNotificationSentAt:
          pushNotificationSentAt ?? this.pushNotificationSentAt,
    );
  }

  static Map<String, dynamic> _getPushMap(Map<String, dynamic> json) {
    final value = json['pushNotification'];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry('$key', value));
    }
    return const <String, dynamic>{};
  }

  static String _getPushStringValue(
    Map<String, dynamic> json,
    String key,
    String fallback,
  ) {
    return _getStringValue(_getPushMap(json), key, fallback);
  }

  static String? _getPushNullableString(Map<String, dynamic> json, String key) {
    return _getNullableString(_getPushMap(json), key);
  }

  static bool _getPushBoolValue(
    Map<String, dynamic> json,
    String key,
    bool fallback,
  ) {
    return _getBoolValue(_getPushMap(json), key, fallback);
  }

  static DateTime? _getPushDateTimeValue(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = _getPushMap(json)[key];
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String _defaultNotificationTopic(String type, String priority) {
    if (priority == 'urgent') {
      return 'urgent_announcements';
    }
    switch (type) {
      case 'event':
        return 'events';
      case 'deadline':
        return 'deadlines';
      case 'opportunity':
        return 'opportunities';
      default:
        return 'announcements';
    }
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  String toString() {
    return 'Announcement(id: $id, title: $title, type: $type, priority: $priority)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Announcement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
