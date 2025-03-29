import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/features/departments/models/department.dart';
import 'package:fast/features/departments/screens/department_details_screen.dart';
import 'package:fast/core/utils/constants.dart'; // Import MUST colors

class DepartmentsScreen extends StatelessWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments', style: TextStyle(color: Colors.white)),
        backgroundColor: mustBlue, // Use MUST blue for AppBar
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('departments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading departments',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final departments =
              snapshot.data!.docs.map((doc) {
                return Department.fromJson(
                  doc.data() as Map<String, dynamic>,
                  [],
                );
              }).toList();

          return ListView.builder(
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final department = departments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                child: ListTile(
                  leading: Image.asset(
                    department.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.error,
                        size: 50,
                        color: Colors.grey,
                      );
                    },
                  ),
                  title: Text(
                    department.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: mustBlue, // Use MUST blue for department name
                    ),
                  ),
                  subtitle: Text(
                    department.description,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                DepartmentDetailsScreen(department: department),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
