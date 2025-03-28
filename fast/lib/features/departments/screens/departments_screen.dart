import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/features/departments/models/department.dart';
import 'package:fast/features/departments/screens/department_details_screen.dart';

class DepartmentsScreen extends StatelessWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('departments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading departments'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final departments =
              snapshot.data!.docs.map((doc) {
                return Department.fromJson(
                  doc.data() as Map<String, dynamic>,
                  [], // Programs are fetched separately
                );
              }).toList();

          return ListView.builder(
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final department = departments[index];
              return ListTile(
                title: Text(department.name),
                subtitle: Text(department.description),
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
              );
            },
          );
        },
      ),
    );
  }
}
