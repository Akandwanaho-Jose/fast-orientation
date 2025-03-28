import 'package:flutter/material.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/departments/data/mock_data.dart';
import 'package:fast/features/departments/screens/department_details_screen.dart';

class DepartmentsScreen extends StatelessWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments', style: TextStyle(color: Colors.white)),
        backgroundColor: mustBlue,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: mockDepartments.length,
        itemBuilder: (context, index) {
          final department = mockDepartments[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading:
                  department.imageUrl.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          department.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.school,
                                size: 50,
                                color: Colors.grey,
                              ),
                        ),
                      )
                      : const Icon(Icons.school, size: 50, color: Colors.grey),
              title: Text(
                department.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mustBlue,
                ),
              ),
              subtitle: Text(
                department.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
              trailing: const Icon(Icons.arrow_forward, color: mustGreen),
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
      ),
    );
  }
}
