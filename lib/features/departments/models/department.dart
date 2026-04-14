import 'package:fast/features/departments/models/program.dart';

/// Production-ready Department model with proper null safety and validation
class Department {
  final String id;
  final String name;
  final String description;
  final String? imageUrl; // Nullable - can be empty or null
  final String? headMessage; // Nullable - might not be available
  final String? headImageUrl; // Nullable - might not be available
  final List<Program> programs;

  Department({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.headMessage,
    this.headImageUrl,
    required this.programs,
  });

  /// Factory method to create a Department from Firestore data with proper validation
  factory Department.fromJson(
    Map<String, dynamic> json,
    List<Program> programs,
  ) {
    try {
      return Department(
        id: _validateAndGetString(json, 'id', isRequired: true),
        name: _validateAndGetString(json, 'name', isRequired: true),
        description: _validateAndGetString(json, 'description', isRequired: true),
        imageUrl: _validateAndGetString(json, 'imageUrl', isRequired: false),
        headMessage: _validateAndGetString(json, 'headMessage', isRequired: false),
        headImageUrl: _validateAndGetString(json, 'headImageUrl', isRequired: false),
        programs: programs,
      );
    } catch (e) {
      throw FormatException('Invalid department data: $e');
    }
  }

  /// Helper method to validate and extract string values from JSON
  static String _validateAndGetString(
    Map<String, dynamic> json, 
    String key, {
    required bool isRequired,
    String? defaultValue,
  }) {
    final value = json[key];
    
    if (value == null) {
      if (isRequired) {
        throw ArgumentError('Required field "$key" is missing');
      }
      return defaultValue ?? '';
    }
    
    if (value is! String) {
      throw ArgumentError('Field "$key" must be a string, got ${value.runtimeType}');
    }
    
    // Return the string, but return empty string if it's just whitespace and not required
    final trimmedValue = value.trim();
    if (!isRequired && trimmedValue.isEmpty) {
      return '';
    }
    
    if (isRequired && trimmedValue.isEmpty) {
      throw ArgumentError('Required field "$key" cannot be empty');
    }
    
    return trimmedValue;
  }

  /// Method to convert a Department to Firestore-compatible JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'name': name,
      'description': description,
    };
    
    // Only include non-null, non-empty values
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      json['imageUrl'] = imageUrl;
    }
    
    if (headMessage != null && headMessage!.isNotEmpty) {
      json['headMessage'] = headMessage;
    }
    
    if (headImageUrl != null && headImageUrl!.isNotEmpty) {
      json['headImageUrl'] = headImageUrl;
    }
    
    return json;
  }

  /// Utility method to check if department has a valid image URL
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Utility method to check if department has head information
  bool get hasHeadInfo => 
      (headMessage != null && headMessage!.isNotEmpty) ||
      (headImageUrl != null && headImageUrl!.isNotEmpty);

  /// Utility method to get a safe head message
  String get safeHeadMessage => 
      headMessage?.isNotEmpty == true 
          ? headMessage!
          : 'Welcome to our department! We are committed to providing excellent education and fostering innovation in our field of study.';

  /// Create a copy of the department with updated fields
  Department copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? headMessage,
    String? headImageUrl,
    List<Program>? programs,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      headMessage: headMessage ?? this.headMessage,
      headImageUrl: headImageUrl ?? this.headImageUrl,
      programs: programs ?? this.programs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Department &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          imageUrl == other.imageUrl &&
          headMessage == other.headMessage &&
          headImageUrl == other.headImageUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      (imageUrl?.hashCode ?? 0) ^
      (headMessage?.hashCode ?? 0) ^
      (headImageUrl?.hashCode ?? 0);

  @override
  String toString() {
    return 'Department{id: $id, name: $name, description: ${description.length > 50 ? '${description.substring(0, 50)}...' : description}, hasImage: $hasImage, hasHeadInfo: $hasHeadInfo}';
  }
}