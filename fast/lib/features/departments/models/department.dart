import 'package:fast/features/departments/models/program.dart';

class Department {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<Program> programs;

  Department({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.programs,
  });

  // Factory method to create a Department from Firestore data
  factory Department.fromJson(
    Map<String, dynamic> json,
    List<Program> programs,
  ) {
    return Department(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      programs: programs,
    );
  }

  // Method to convert a Department to Firestore-compatible JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
