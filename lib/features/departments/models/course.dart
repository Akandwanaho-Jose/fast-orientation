class Course {
  final String code;
  final String name;
  final String description;
  final int credits;

  Course({
    required this.code,
    required this.name,
    required this.description,
    required this.credits,
  });

  // Factory method to create a Course from Firestore data
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      credits: json['credits'] as int,
    );
  }

  // Method to convert a Course to Firestore-compatible JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'credits': credits,
    };
  }
}
