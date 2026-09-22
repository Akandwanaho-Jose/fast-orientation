class Staff {
  final String id;
  final String? name;
  final String? position;
  final String? email;
  final String? linkedinUrl;
  final String? photoUrl;
  final String? department;
  final String? departmentName;
  final String? roleType;
  final String? phone;
  final String? office;
  final String? bio;
  final bool featured;
  final bool isKeyContact;
  final bool isLeadership;
  final String status;
  final int order;

  const Staff({
    required this.id,
    this.name,
    this.position,
    this.email,
    this.linkedinUrl,
    this.photoUrl,
    this.department,
    this.departmentName,
    this.roleType,
    this.phone,
    this.office,
    this.bio,
    this.featured = false,
    this.isKeyContact = false,
    this.isLeadership = false,
    this.status = 'published',
    this.order = 0,
  });

  factory Staff.fromJson(Map<String, dynamic> json, String id) {
    final position = _readNullableString(json, 'position');
    final department = _readNullableString(json, 'department');
    final resolvedRoleType =
        _readNullableString(json, 'roleType') ?? _inferRoleType(position);

    return Staff(
      id: id,
      name: _readNullableString(json, 'name'),
      position: position,
      email: _readNullableString(json, 'email'),
      linkedinUrl: _readNullableString(json, 'linkedinUrl'),
      photoUrl: _readNullableString(json, 'photoUrl'),
      department: department,
      departmentName: _readNullableString(json, 'departmentName') ?? department,
      roleType: resolvedRoleType,
      phone: _readNullableString(json, 'phone'),
      office: _readNullableString(json, 'office'),
      bio: _readNullableString(json, 'bio'),
      featured: _readBool(json, 'featured', false),
      isKeyContact: _readBool(json, 'isKeyContact', false),
      isLeadership: _readBool(
        json,
        'isLeadership',
        resolvedRoleType == 'dean' || resolvedRoleType == 'hod',
      ),
      status: _readString(json, 'status', fallback: 'published'),
      order: _readInt(json, 'order', 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name?.isNotEmpty == true) 'name': name,
      if (position?.isNotEmpty == true) 'position': position,
      if (email?.isNotEmpty == true) 'email': email,
      if (linkedinUrl?.isNotEmpty == true) 'linkedinUrl': linkedinUrl,
      if (photoUrl?.isNotEmpty == true) 'photoUrl': photoUrl,
      if (department?.isNotEmpty == true) 'department': department,
      if (departmentName?.isNotEmpty == true) 'departmentName': departmentName,
      if (roleType?.isNotEmpty == true) 'roleType': roleType,
      if (phone?.isNotEmpty == true) 'phone': phone,
      if (office?.isNotEmpty == true) 'office': office,
      if (bio?.isNotEmpty == true) 'bio': bio,
      'featured': featured,
      'isKeyContact': isKeyContact,
      'isLeadership': isLeadership,
      'status': status,
      'order': order,
    };
  }

  bool get hasPhoto => photoUrl?.isNotEmpty == true;
  bool get hasLinkedIn => linkedinUrl?.isNotEmpty == true;
  bool get hasEmail => email?.isNotEmpty == true;
  bool get hasPhone => phone?.isNotEmpty == true;
  bool get hasBio => bio?.isNotEmpty == true;
  bool get hasDepartment =>
      departmentName?.trim().isNotEmpty == true ||
      department?.trim().isNotEmpty == true;
  bool get isPublished => status == 'published';
  bool get isDean => roleType == 'dean';
  bool get isHod => roleType == 'hod';

  String get displayName =>
      name?.trim().isNotEmpty == true ? name!.trim() : 'Unnamed Staff';

  String get displayPosition =>
      position?.trim().isNotEmpty == true ? position!.trim() : 'FAST Staff';

  String get displayDepartment {
    if (departmentName?.trim().isNotEmpty == true) {
      return departmentName!.trim();
    }
    if (department?.trim().isNotEmpty == true) {
      return department!.trim();
    }
    return 'FAST';
  }

  String get displayDepartmentCode => departmentCodeFor(
    displayDepartment,
    roleType: roleType,
    position: position,
  );

  String get displayRoleLabel {
    switch (roleType) {
      case 'dean':
        return 'Dean';
      case 'hod':
        return 'Head of Department';
      case 'key_contact':
        return 'Key Contact';
      default:
        return 'Staff';
    }
  }

  static String? _readNullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
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

  static bool _readBool(Map<String, dynamic> json, String key, bool fallback) {
    final value = json[key];
    return value is bool ? value : fallback;
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

  static String? _inferRoleType(String? position) {
    if (position == null || position.trim().isEmpty) {
      return null;
    }

    final normalized = position.toLowerCase();
    if (normalized.contains('dean')) {
      return 'dean';
    }
    if (normalized.contains('head') ||
        normalized.contains('hod') ||
        normalized.contains('chair')) {
      return 'hod';
    }
    if (normalized.contains('contact') ||
        normalized.contains('secretary') ||
        normalized.contains('administrator')) {
      return 'key_contact';
    }
    return 'staff';
  }

  static String departmentCodeFor(
    String? department, {
    String? roleType,
    String? position,
  }) {
    final label = department?.trim() ?? '';
    final normalized = '$label ${position ?? ''} ${roleType ?? ''}'
        .toLowerCase()
        .replaceAll("'", '')
        .replaceAll('’', '');

    if (roleType == 'dean' ||
        normalized.contains('dean') ||
        normalized.contains('deans office')) {
      return "DEAN'S";
    }
    if (normalized.contains('eee') ||
        (normalized.contains('electrical') &&
            normalized.contains('electronics'))) {
      return 'EEE';
    }
    if (normalized.contains('pem') ||
        normalized.contains('peem') ||
        normalized.contains('petroleum')) {
      return 'PEEM';
    }
    if (normalized.contains('cve') || normalized.contains('civil')) {
      return 'CVE';
    }
    if (normalized.contains('bme') || normalized.contains('biomedical')) {
      return 'BME';
    }
    if (normalized.contains('mie') ||
        normalized.contains('mechanical') ||
        normalized.contains('industrial')) {
      return 'MIE';
    }

    final words = label
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

    return initials.isEmpty ? label.substring(0, 1).toUpperCase() : initials;
  }
}
