import 'package:fast/features/departments/models/program.dart';

class Department {
  final String id;
  final String name;
  final String description;
  final String shortName;
  final String slug;
  final String shortDescription;
  final String? imageUrl;
  final String? headName;
  final String? headTitle;
  final String? headMessage;
  final String? headImageUrl;
  final String? contactEmail;
  final String? contactPhone;
  final String? location;
  final bool featured;
  final String status;
  final List<Program> programs;

  const Department({
    required this.id,
    required this.name,
    required this.description,
    required this.shortName,
    required this.slug,
    required this.shortDescription,
    this.imageUrl,
    this.headName,
    this.headTitle,
    this.headMessage,
    this.headImageUrl,
    this.contactEmail,
    this.contactPhone,
    this.location,
    this.featured = false,
    this.status = 'published',
    this.programs = const [],
  });

  factory Department.fromJson(
    Map<String, dynamic> json,
    List<Program> programs,
  ) {
    final name = _readString(json, 'name', fallback: 'Unnamed Department');
    final description = _readString(
      json,
      'description',
      fallback: _readString(
        json,
        'shortDescription',
        fallback: 'Learn more about $name at FAST.',
      ),
    );

    return Department(
      id: _readString(json, 'id', fallback: ''),
      name: name,
      description: description,
      shortName: _resolveShortName(
        name,
        _readNullableString(json, 'shortName'),
      ),
      slug: _readString(json, 'slug', fallback: _slugify(name)),
      shortDescription: _readString(
        json,
        'shortDescription',
        fallback: _truncate(description, maxLength: 110),
      ),
      imageUrl: _readFirstAvailableString(json, const [
        'imageUrl',
        'image_url',
        'photoUrl',
        'photo_url',
      ]),
      headName: _readNullableString(json, 'headName'),
      headTitle: _readNullableString(json, 'headTitle'),
      headMessage: _readNullableString(json, 'headMessage'),
      headImageUrl: _readFirstAvailableString(json, const [
        'headImageUrl',
        'head_image_url',
      ]),
      contactEmail: _readNullableString(json, 'contactEmail'),
      contactPhone: _readNullableString(json, 'contactPhone'),
      location: _readNullableString(json, 'location'),
      featured: _readBool(json, 'featured', false),
      status: _readString(json, 'status', fallback: 'published'),
      programs: programs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'shortName': shortName,
      'slug': slug,
      'shortDescription': shortDescription,
      if (imageUrl?.isNotEmpty == true) 'imageUrl': imageUrl,
      if (headName?.isNotEmpty == true) 'headName': headName,
      if (headTitle?.isNotEmpty == true) 'headTitle': headTitle,
      if (headMessage?.isNotEmpty == true) 'headMessage': headMessage,
      if (headImageUrl?.isNotEmpty == true) 'headImageUrl': headImageUrl,
      if (contactEmail?.isNotEmpty == true) 'contactEmail': contactEmail,
      if (contactPhone?.isNotEmpty == true) 'contactPhone': contactPhone,
      if (location?.isNotEmpty == true) 'location': location,
      'featured': featured,
      'status': status,
    };
  }

  bool get hasImage => displayImageUrl?.isNotEmpty == true;
  String? get displayImageUrl =>
      imageUrl?.trim().isNotEmpty == true
          ? imageUrl!.trim()
          : headImageUrl?.trim().isNotEmpty == true
          ? headImageUrl!.trim()
          : null;
  bool get hasHeadInfo =>
      headName?.isNotEmpty == true ||
      headTitle?.isNotEmpty == true ||
      headMessage?.isNotEmpty == true ||
      headImageUrl?.isNotEmpty == true;
  bool get hasContactInfo =>
      contactEmail?.isNotEmpty == true ||
      contactPhone?.isNotEmpty == true ||
      location?.isNotEmpty == true;
  bool get isPublished => status == 'published';

  String get safeHeadMessage =>
      headMessage?.isNotEmpty == true
          ? headMessage!
          : 'Welcome to $name. Explore our programs, people, and opportunities.';

  String get displayHeadName =>
      headName?.isNotEmpty == true ? headName! : 'Head of Department';

  String get displayHeadTitle =>
      headTitle?.isNotEmpty == true ? headTitle! : 'Head of Department';

  Department copyWith({
    String? id,
    String? name,
    String? description,
    String? shortName,
    String? slug,
    String? shortDescription,
    String? imageUrl,
    String? headName,
    String? headTitle,
    String? headMessage,
    String? headImageUrl,
    String? contactEmail,
    String? contactPhone,
    String? location,
    bool? featured,
    String? status,
    List<Program>? programs,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      shortName: shortName ?? this.shortName,
      slug: slug ?? this.slug,
      shortDescription: shortDescription ?? this.shortDescription,
      imageUrl: imageUrl ?? this.imageUrl,
      headName: headName ?? this.headName,
      headTitle: headTitle ?? this.headTitle,
      headMessage: headMessage ?? this.headMessage,
      headImageUrl: headImageUrl ?? this.headImageUrl,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      location: location ?? this.location,
      featured: featured ?? this.featured,
      status: status ?? this.status,
      programs: programs ?? this.programs,
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

  static String? _readFirstAvailableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = _readNullableString(json, key);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static bool _readBool(Map<String, dynamic> json, String key, bool fallback) {
    final value = json[key];
    return value is bool ? value : fallback;
  }

  static String _buildShortName(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) {
      return 'FAST';
    }

    final initials =
        words
            .where((word) => word.length > 2 || word == words.first)
            .map((word) => word[0].toUpperCase())
            .join();

    return initials.isEmpty ? name.substring(0, 1).toUpperCase() : initials;
  }

  static String _resolveShortName(String name, String? providedShortName) {
    final mapped = _mappedShortName(name);
    if (mapped != null) {
      return mapped;
    }

    if (providedShortName?.trim().isNotEmpty == true) {
      return providedShortName!.trim().toUpperCase();
    }

    return _buildShortName(name);
  }

  static String? _mappedShortName(String name) {
    final normalized = name.toLowerCase();

    if (normalized.contains('electrical') &&
        normalized.contains('electronics')) {
      return 'EEE';
    }
    if (normalized.contains('biomedical')) {
      return 'BME';
    }
    if (normalized.contains('civil')) {
      return 'CVE';
    }
    if (normalized.contains('mechanical') &&
        normalized.contains('industrial')) {
      return 'MIE';
    }
    if ((normalized.contains('petroleum') ||
            normalized.contains('petrolium')) &&
        (normalized.contains('environmental') ||
            normalized.contains('enviromental'))) {
      return 'PEEM';
    }

    return null;
  }

  static String _truncate(String value, {required int maxLength}) {
    final normalized = value.trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength - 1).trimRight()}...';
  }

  static String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Department &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() {
    return 'Department(id: $id, name: $name, shortName: $shortName)';
  }
}
