import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/admin/widgets/admin_shared.dart';
import 'package:fast/features/departments/models/department.dart';
import 'package:flutter/material.dart';

class DepartmentsAdminSection extends StatelessWidget {
  const DepartmentsAdminSection({super.key});

  @override
  Widget build(BuildContext context) {
    final collection = FirebaseFirestore.instance.collection('departments');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }

        if (snapshot.hasError) {
          return const AdminErrorState(
            message: 'Departments could not be loaded from Firestore.',
          );
        }

        final departments =
            snapshot.data?.docs
                .map(
                  (doc) => Department.fromJson({
                    ...doc.data(),
                    'id': doc.id,
                  }, const []),
                )
                .toList(growable: true) ??
            <Department>[];

        departments.sort((a, b) => a.name.compareTo(b.name));

        return AdminSectionFrame(
          title: 'Departments',
          subtitle:
              'Manage the faculty’s public department profiles and the information students see in Explore FAST.',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showEditDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Department'),
              style: ElevatedButton.styleFrom(
                backgroundColor: mustBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          child:
              departments.isEmpty
                  ? const AdminEmptyState(
                    icon: Icons.account_balance_outlined,
                    title: 'No departments found',
                    message:
                        'Create the first department profile to populate Explore FAST.',
                  )
                  : Column(
                    children: departments
                        .map(
                          (department) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _DepartmentAdminCard(
                              department: department,
                              onEdit:
                                  () => _showEditDialog(
                                    context,
                                    existing: department,
                                  ),
                              onDelete:
                                  () => _confirmDelete(
                                    context,
                                    department.id,
                                    department.name,
                                  ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
        );
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context, {
    Department? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final shortNameController = TextEditingController(
      text: existing?.shortName ?? '',
    );
    final slugController = TextEditingController(text: existing?.slug ?? '');
    final shortDescriptionController = TextEditingController(
      text: existing?.shortDescription ?? '',
    );
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final imageUrlController = TextEditingController(
      text: existing?.imageUrl ?? '',
    );
    final headNameController = TextEditingController(
      text: existing?.headName ?? '',
    );
    final headTitleController = TextEditingController(
      text: existing?.headTitle ?? '',
    );
    final headMessageController = TextEditingController(
      text: existing?.headMessage ?? '',
    );
    final headImageUrlController = TextEditingController(
      text: existing?.headImageUrl ?? '',
    );
    final emailController = TextEditingController(
      text: existing?.contactEmail ?? '',
    );
    final phoneController = TextEditingController(
      text: existing?.contactPhone ?? '',
    );
    final locationController = TextEditingController(
      text: existing?.location ?? '',
    );
    var featured = existing?.featured ?? false;
    var status = existing?.status ?? 'published';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                existing == null ? 'Create Department' : 'Edit Department',
              ),
              content: SizedBox(
                width: 760,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _field(nameController, 'Department name'),
                      _field(shortNameController, 'Short name'),
                      _field(
                        slugController,
                        'Slug',
                        helper:
                            'Used for clean IDs if you create a new department.',
                      ),
                      _field(
                        shortDescriptionController,
                        'Short description',
                        maxLines: 3,
                      ),
                      _field(
                        descriptionController,
                        'Full description',
                        maxLines: 5,
                      ),
                      _field(imageUrlController, 'Image URL'),
                      _field(headNameController, 'Head name'),
                      _field(headTitleController, 'Head title'),
                      _field(
                        headMessageController,
                        'Head message',
                        maxLines: 4,
                      ),
                      _field(headImageUrlController, 'Head image URL'),
                      _field(emailController, 'Contact email'),
                      _field(phoneController, 'Contact phone'),
                      _field(locationController, 'Location'),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: featured,
                        onChanged: (value) => setState(() => featured = value),
                        title: const Text('Featured'),
                      ),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'published',
                            child: Text('Published'),
                          ),
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('Draft'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => status = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final firestore = FirebaseFirestore.instance;
                    final slugValue =
                        slugController.text.trim().isEmpty
                            ? slugify(nameController.text.trim())
                            : slugController.text.trim();
                    final docId =
                        existing?.id.isNotEmpty == true
                            ? existing!.id
                            : slugValue;
                    await firestore.collection('departments').doc(docId).set({
                      'id': docId,
                      'name': nameController.text.trim(),
                      'shortName': shortNameController.text.trim(),
                      'slug': slugValue,
                      'shortDescription':
                          shortDescriptionController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'imageUrl': imageUrlController.text.trim(),
                      'headName': headNameController.text.trim(),
                      'headTitle': headTitleController.text.trim(),
                      'headMessage': headMessageController.text.trim(),
                      'headImageUrl': headImageUrlController.text.trim(),
                      'contactEmail': emailController.text.trim(),
                      'contactPhone': phoneController.text.trim(),
                      'location': locationController.text.trim(),
                      'featured': featured,
                      'status': status,
                      'updatedAt': FieldValue.serverTimestamp(),
                      if (existing == null)
                        'createdAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mustBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String departmentId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Department'),
          content: Text(
            'Delete "$name"? Existing programs under this department will remain in Firestore unless removed separately.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('departments')
          .doc(departmentId)
          .delete();
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _DepartmentAdminCard extends StatelessWidget {
  const _DepartmentAdminCard({
    required this.department,
    required this.onEdit,
    required this.onDelete,
  });

  final Department department;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminTag(label: department.shortName, color: mustBlue),
                    AdminTag(
                      label: department.status,
                      color:
                          department.isPublished
                              ? mustGreen
                              : const Color(0xFFD97706),
                    ),
                    if (department.featured)
                      const AdminTag(
                        label: 'Featured',
                        color: Color(0xFFD97706),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  department.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF152033),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  department.shortDescription,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
