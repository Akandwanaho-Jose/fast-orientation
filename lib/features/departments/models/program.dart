import 'package:fast/features/departments/models/course.dart';

class Program {
  final String id;
  final String name;
  final String? description;
  final String slug;
  final int durationYears;
  final bool featured;
  final String status;
  final List<YearCourses> yearCourses;

  const Program({
    required this.id,
    required this.name,
    this.description,
    required this.slug,
    required this.durationYears,
    this.featured = false,
    this.status = 'published',
    this.yearCourses = const [],
  });

  factory Program.fromJson(
    Map<String, dynamic> json,
    List<YearCourses> yearCourses, {
    String? id,
  }) {
    final name = _readString(json, 'name', fallback: 'Unnamed Program');

    return Program(
      id: id ?? _readString(json, 'id', fallback: ''),
      name: name,
      description: _readNullableString(json, 'description'),
      slug: _readString(json, 'slug', fallback: _slugify(name)),
      durationYears: _readInt(json, 'durationYears', 0),
      featured: _readBool(json, 'featured', false),
      status: _readString(json, 'status', fallback: 'published'),
      yearCourses: yearCourses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      if (description?.isNotEmpty == true) 'description': description,
      'slug': slug,
      'durationYears': durationYears,
      'featured': featured,
      'status': status,
    };
  }

  bool get isPublished => status == 'published';
  bool get hasDescription => description?.isNotEmpty == true;
  String get safeDescription =>
      hasDescription ? description! : 'Explore the $name program at FAST.';
  String get durationLabel =>
      durationYears == 1 ? '1 year' : '$durationYears years';

  Program copyWith({
    String? id,
    String? name,
    String? description,
    String? slug,
    int? durationYears,
    bool? featured,
    String? status,
    List<YearCourses>? yearCourses,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      slug: slug ?? this.slug,
      durationYears: durationYears ?? this.durationYears,
      featured: featured ?? this.featured,
      status: status ?? this.status,
      yearCourses: yearCourses ?? this.yearCourses,
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    String key, {
    required String fallback,
  }) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static String? _readNullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static int _readInt(Map<String, dynamic> json, String key, int fallback) {
    final value = json[key];
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

  static bool _readBool(Map<String, dynamic> json, String key, bool fallback) {
    final value = json[key];
    return value is bool ? value : fallback;
  }

  static String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

class YearCourses {
  final int year;
  final List<Course> courses;

  const YearCourses({required this.year, required this.courses});

  factory YearCourses.fromJson(Map<String, dynamic> json) {
    final rawCourses = json['courses'];
    final courses =
        rawCourses is List
            ? rawCourses
                .whereType<Map>()
                .map(
                  (courseJson) =>
                      Course.fromJson(Map<String, dynamic>.from(courseJson)),
                )
                .toList(growable: false)
            : const <Course>[];

    return YearCourses(year: _readInt(json, 'year', 0), courses: courses);
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'courses': courses.map((course) => course.toJson()).toList(),
    };
  }

  static int _readInt(Map<String, dynamic> json, String key, int fallback) {
    final value = json[key];
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
}
