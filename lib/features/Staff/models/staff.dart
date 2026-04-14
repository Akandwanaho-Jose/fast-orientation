import 'package:cloud_firestore/cloud_firestore.dart';

class Staff {
  final String id;
  final String? name;
  final String? position;
  final String? email;
  final String? linkedinUrl;
  final String? photoUrl;
  final String? department;

  Staff({
    required this.id,
    this.name,
    this.position,
    this.email,
    this.linkedinUrl,
    this.photoUrl,
    this.department,
  });

  factory Staff.fromJson(Map<String, dynamic> json, String id) {
    return Staff(
      id: id,
      name: json['name'] as String?,
      position: json['position'] as String?,
      email: json['email'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      photoUrl: json['photoUrl'] as String?,
      department: json['department'] as String?,
    );
  }
}