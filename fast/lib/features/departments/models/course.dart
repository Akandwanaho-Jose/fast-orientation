class Course {
  final String code;
  final String name;
  final String description;
  final int credits;
  final int? semester;

  const Course({
    required this.code,
    required this.name,
    required this.description,
    required this.credits,
    this.semester,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      code: _readString(json, 'code', fallback: 'N/A'),
      name: _readString(json, 'name', fallback: 'Unnamed Course'),
      description: _readString(
        json,
        'description',
        fallback: 'Course description is not available yet.',
      ),
      credits: _readInt(json, 'credits', 0),
      semester: _readNullableInt(json, 'semester'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'credits': credits,
      if (semester != null) 'semester': semester,
    };
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

  static int? _readNullableInt(Map<String, dynamic> json, String key) {
    final value = json[key];
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
}
