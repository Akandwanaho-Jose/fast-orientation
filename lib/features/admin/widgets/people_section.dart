import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/core/widgets/safe_network_avatar.dart';
import 'package:fast/features/Staff/models/staff.dart';
import 'package:fast/features/admin/widgets/admin_shared.dart';
import 'package:fast/features/departments/models/department.dart';
import 'package:flutter/material.dart';

class PeopleAdminSection extends StatelessWidget {
  const PeopleAdminSection({super.key});

  @override
  Widget build(BuildContext context) {
    final collection = FirebaseFirestore.instance.collection('staff');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }

        if (snapshot.hasError) {
          return const AdminErrorState(
            message: 'People profiles could not be loaded from Firestore.',
          );
        }

        final people =
            snapshot.data?.docs
                .map((doc) => Staff.fromJson(doc.data(), doc.id))
                .toList(growable: true) ??
            <Staff>[];

        people.sort((a, b) {
          if (a.order != b.order) {
            return a.order.compareTo(b.order);
          }
          return a.displayName.compareTo(b.displayName);
        });

        return AdminSectionFrame(
          title: 'People',
          subtitle:
              'Manage the dean, heads of department, key contacts, and the wider staff directory.',
          actions: [
            AdminPrimaryActionButton(
              onPressed: () => _showEditDialog(context),
              icon: Icons.add_rounded,
              label: 'New Profile',
              compactLabel: 'New',
            ),
          ],
          child:
              people.isEmpty
                  ? const AdminEmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No profiles found',
                    message:
                        'Create the first FAST person profile to populate the People tab.',
                  )
                  : Column(
                    children: people
                        .map(
                          (person) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _PersonAdminCard(
                              person: person,
                              onEdit:
                                  () => _showEditDialog(
                                    context,
                                    existing: person,
                                  ),
                              onDelete:
                                  () => _confirmDelete(
                                    context,
                                    person.id,
                                    person.displayName,
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

  Future<void> _showEditDialog(BuildContext context, {Staff? existing}) async {
    final formKey = GlobalKey<FormState>();
    final departmentOptions = await _loadDepartmentOptions(existing);
    if (!context.mounted) {
      return;
    }
    final existingDepartment =
        (existing?.departmentName ?? existing?.department ?? '').trim();
    var selectedDepartmentName = _initialDepartmentName(
      departmentOptions,
      existingDepartment,
    );
    var selectedDepartmentId = _departmentIdFor(
      departmentOptions,
      selectedDepartmentName,
    );
    final nameController = TextEditingController(text: existing?.name ?? '');
    final positionController = TextEditingController(
      text: existing?.position ?? '',
    );
    final emailController = TextEditingController(text: existing?.email ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final officeController = TextEditingController(
      text: existing?.office ?? '',
    );
    final linkedinController = TextEditingController(
      text: existing?.linkedinUrl ?? '',
    );
    final photoController = TextEditingController(
      text: existing?.photoUrl ?? '',
    );
    final departmentNameController = TextEditingController(
      text: selectedDepartmentName ?? '',
    );
    final bioController = TextEditingController(text: existing?.bio ?? '');
    final orderController = TextEditingController(
      text: '${existing?.order ?? 0}',
    );
    var roleType = existing?.roleType ?? 'staff';
    var featured = existing?.featured ?? false;
    var isKeyContact = existing?.isKeyContact ?? false;
    var isLeadership = existing?.isLeadership ?? false;
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
              title: Text(existing == null ? 'Create Profile' : 'Edit Profile'),
              content: SizedBox(
                width: 760,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _field(nameController, 'Name'),
                        _field(positionController, 'Position'),
                        _departmentField(
                          controller: departmentNameController,
                          options: departmentOptions,
                          selectedDepartmentName: selectedDepartmentName,
                          onChanged: (value) {
                            setState(() {
                              selectedDepartmentName = value;
                              selectedDepartmentId = _departmentIdFor(
                                departmentOptions,
                                value,
                              );
                              departmentNameController.text = value ?? '';
                            });
                          },
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: roleType,
                          decoration: _decoration('Role type'),
                          items: const [
                            DropdownMenuItem(
                              value: 'dean',
                              child: Text('Dean'),
                            ),
                            DropdownMenuItem(value: 'hod', child: Text('HOD')),
                            DropdownMenuItem(
                              value: 'key_contact',
                              child: Text('Key Contact'),
                            ),
                            DropdownMenuItem(
                              value: 'staff',
                              child: Text('Staff'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => roleType = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: _decoration('Status'),
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
                            if (value != null) setState(() => status = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        _field(emailController, 'Email'),
                        _field(phoneController, 'Phone'),
                        _field(officeController, 'Office'),
                        _field(linkedinController, 'LinkedIn URL'),
                        AdminImageUrlField(
                          controller: photoController,
                          label: 'Profile photo',
                        ),
                        _field(bioController, 'Bio', maxLines: 4),
                        _field(orderController, 'Display order'),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: featured,
                          onChanged:
                              (value) => setState(() => featured = value),
                          title: const Text('Featured'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isKeyContact,
                          onChanged:
                              (value) => setState(() => isKeyContact = value),
                          title: const Text('Key contact'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isLeadership,
                          onChanged:
                              (value) => setState(() => isLeadership = value),
                          title: const Text('Leadership'),
                        ),
                      ],
                    ),
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
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    final departmentName = departmentNameController.text.trim();
                    final collection = FirebaseFirestore.instance.collection(
                      'staff',
                    );
                    final doc =
                        existing == null
                            ? collection.doc()
                            : collection.doc(existing.id);
                    await doc.set({
                      'name': nameController.text.trim(),
                      'position': positionController.text.trim(),
                      'department': departmentName,
                      'departmentName': departmentName,
                      'departmentId':
                          selectedDepartmentId ?? FieldValue.delete(),
                      'roleType': roleType,
                      'email': emailController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'office': officeController.text.trim(),
                      'linkedinUrl': linkedinController.text.trim(),
                      'photoUrl': photoController.text.trim(),
                      'bio': bioController.text.trim(),
                      'featured': featured,
                      'isKeyContact': isKeyContact,
                      'isLeadership': isLeadership,
                      'status': status,
                      'order': int.tryParse(orderController.text.trim()) ?? 0,
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

  Future<List<_DepartmentOption>> _loadDepartmentOptions(
    Staff? existing,
  ) async {
    final existingDepartment =
        (existing?.departmentName ?? existing?.department ?? '').trim();

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('departments').get();
      final options = snapshot.docs
          .map((doc) {
            final department = Department.fromJson({
              ...doc.data(),
              'id': doc.id,
            }, const []);
            return _DepartmentOption(
              id: doc.id,
              name: department.name,
              shortName: department.shortName,
            );
          })
          .toList(growable: true);

      options.sort((a, b) => a.name.compareTo(b.name));

      if (existingDepartment.isNotEmpty &&
          !options.any(
            (option) =>
                _normalizeDepartment(option.name) ==
                _normalizeDepartment(existingDepartment),
          )) {
        options.insert(
          0,
          _DepartmentOption(
            id: null,
            name: existingDepartment,
            shortName: Staff.departmentCodeFor(existingDepartment),
          ),
        );
      }

      return options;
    } catch (_) {
      if (existingDepartment.isEmpty) {
        return const [];
      }

      return [
        _DepartmentOption(
          id: null,
          name: existingDepartment,
          shortName: Staff.departmentCodeFor(existingDepartment),
        ),
      ];
    }
  }

  String? _departmentIdFor(List<_DepartmentOption> options, String? name) {
    if (name == null || name.trim().isEmpty) {
      return null;
    }

    final normalizedName = _normalizeDepartment(name);
    for (final option in options) {
      if (_normalizeDepartment(option.name) == normalizedName) {
        return option.id;
      }
    }
    return null;
  }

  String? _initialDepartmentName(
    List<_DepartmentOption> options,
    String existingDepartment,
  ) {
    if (existingDepartment.isEmpty) {
      return options.isNotEmpty ? options.first.name : null;
    }

    for (final option in options) {
      if (option.name == existingDepartment) {
        return option.name;
      }
    }

    final normalizedExisting = _normalizeDepartment(existingDepartment);
    for (final option in options) {
      if (_normalizeDepartment(option.name) == normalizedExisting) {
        return option.name;
      }
    }

    return existingDepartment;
  }

  Widget _departmentField({
    required TextEditingController controller,
    required List<_DepartmentOption> options,
    required String? selectedDepartmentName,
    required ValueChanged<String?> onChanged,
  }) {
    if (options.isEmpty) {
      return _field(
        controller,
        'Department name',
        validator: _requiredDepartment,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: selectedDepartmentName,
        decoration: _decoration('Department'),
        isExpanded: true,
        items: options
            .map(
              (option) => DropdownMenuItem(
                value: option.name,
                child: Text('${option.shortName} - ${option.name}'),
              ),
            )
            .toList(growable: false),
        validator: _requiredDepartment,
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: _decoration(label),
        validator: validator,
      ),
    );
  }

  String? _requiredDepartment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Select the person\'s department.';
    }
    return null;
  }

  String _normalizeDepartment(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Profile'),
          content: Text('Delete "$name"? This action cannot be undone.'),
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
      await FirebaseFirestore.instance.collection('staff').doc(id).delete();
    }
  }
}

class _DepartmentOption {
  const _DepartmentOption({
    required this.id,
    required this.name,
    required this.shortName,
  });

  final String? id;
  final String name;
  final String shortName;
}

class _PersonAdminCard extends StatelessWidget {
  const _PersonAdminCard({
    required this.person,
    required this.onEdit,
    required this.onDelete,
  });

  final Staff person;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeNetworkAvatar(
            radius: 30,
            imageUrl: person.photoUrl,
            backgroundColor: const Color(0xFFEAF1FB),
            fallbackIconColor: mustBlue,
            fallbackIconSize: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminTag(label: person.displayRoleLabel, color: mustBlue),
                    AdminTag(
                      label: person.status,
                      color:
                          person.isPublished
                              ? mustGreen
                              : const Color(0xFFD97706),
                    ),
                    if (person.isKeyContact)
                      const AdminTag(
                        label: 'Key Contact',
                        color: Color(0xFFD97706),
                      ),
                    if (!person.hasDepartment)
                      const AdminTag(
                        label: 'Missing department',
                        color: Colors.red,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  person.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF152033),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  person.displayPosition,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  person.displayDepartment,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AdminOverflowActions(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}
