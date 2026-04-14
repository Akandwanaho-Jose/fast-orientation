import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String description;
  final DateTime postedAt;
  final String? category;
  final List<String> imageUrls;
  final String priority;
  final bool isPinned;
  final List<String> tags;
  final int views;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.postedAt,
    this.category,
    this.imageUrls = const [],
    this.priority = 'normal',
    this.isPinned = false,
    this.tags = const [],
    this.views = 0,
  });

  /// Production-ready factory method with robust error handling
  factory Announcement.fromJson(Map<String, dynamic> json, String id) {
    try {
      return Announcement(
        id: id,
        title: _getStringValue(json, 'title', 'Untitled'),
        description: _getStringValue(json, 'description', 'No description available'),
        postedAt: _getDateTimeValue(json, 'postedAt'),
        category: _getStringValue(json, 'category', null),
        imageUrls: _getImageUrls(json),
        priority: _getStringValue(json, 'priority', 'normal'),
        isPinned: _getBoolValue(json, 'isPinned', false),
        tags: _getStringList(json, 'tags'),
        views: _getIntValue(json, 'views', 0),
      );
    } catch (e) {
      // Log error for debugging but don't crash the app
      print('Error parsing announcement $id: $e');
      
      // Return a fallback announcement
      return Announcement(
        id: id,
        title: 'Error Loading Announcement',
        description: 'This announcement could not be loaded properly. Please try again later.',
        postedAt: DateTime.now(),
        category: 'General',
        priority: 'normal',
        isPinned: false,
        tags: const [],
        views: 0,
      );
    }
  }

  /// Safe string extraction with fallback
  static String _getStringValue(Map<String, dynamic> json, String key, String? defaultValue) {
    final value = json[key];
    if (value == null) return defaultValue ?? '';
    return value.toString();
  }

  /// Safe boolean extraction with fallback
  static bool _getBoolValue(Map<String, dynamic> json, String key, bool defaultValue) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    return defaultValue;
  }

  /// Safe integer extraction with fallback
  static int _getIntValue(Map<String, dynamic> json, String key, int defaultValue) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Safe DateTime extraction with fallback
  static DateTime _getDateTimeValue(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return DateTime.now();
    
    try {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Safe string list extraction with fallback
  static List<String> _getStringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return [];
    
    try {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Safe image URLs extraction with backward compatibility
  static List<String> _getImageUrls(Map<String, dynamic> json) {
    try {
      // Check for new format first
      if (json['imageUrls'] != null) {
        final urls = json['imageUrls'];
        if (urls is List) {
          return urls.map((e) => e.toString()).where((url) => url.isNotEmpty).toList();
        }
      }
      
      // Fall back to legacy single imageUrl
      if (json['imageUrl'] != null) {
        final url = json['imageUrl'].toString();
        return url.isNotEmpty ? [url] : [];
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'postedAt': Timestamp.fromDate(postedAt),
      'category': category,
      'imageUrls': imageUrls,
      'priority': priority,
      'isPinned': isPinned,
      'tags': tags,
      'views': views,
    };
  }

  /// Helper methods
  bool get isUrgent => priority == 'urgent';
  bool get isImportant => priority == 'important';
  bool get hasImages => imageUrls.isNotEmpty;
  String get mainImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  
  /// Copy with method for immutable updates
  Announcement copyWith({
    String? title,
    String? description,
    DateTime? postedAt,
    String? category,
    List<String>? imageUrls,
    String? priority,
    bool? isPinned,
    List<String>? tags,
    int? views,
  }) {
    return Announcement(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      postedAt: postedAt ?? this.postedAt,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      priority: priority ?? this.priority,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      views: views ?? this.views,
    );
  }

  @override
  String toString() {
    return 'Announcement(id: $id, title: $title, priority: $priority, isPinned: $isPinned)';
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