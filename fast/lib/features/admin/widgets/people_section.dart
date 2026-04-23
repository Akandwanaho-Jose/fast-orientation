import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/Staff/models/staff.dart';
import 'package:fast/features/admin/widgets/admin_shared.dart';
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
            ElevatedButton.icon(
              onPressed: () => _showEditDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: mustBlue,
                foregroundColor: Colors.white,
              ),
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
      text: existing?.departmentName ?? existing?.department ?? '',
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
                  child: Column(
                    children: [
                      _field(nameController, 'Name'),
                      _field(positionController, 'Position'),
                      _field(departmentNameController, 'Department name'),
                      DropdownButtonFormField<String>(
                        value: roleType,
                        decoration: _decoration('Role type'),
                        items: const [
                          DropdownMenuItem(value: 'dean', child: Text('Dean')),
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
                        value: status,
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
                      _field(photoController, 'Photo URL'),
                      _field(bioController, 'Bio', maxLines: 4),
                      _field(orderController, 'Display order'),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: featured,
                        onChanged: (value) => setState(() => featured = value),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
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
                      'department': departmentNameController.text.trim(),
                      'departmentName': departmentNameController.text.trim(),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: _decoration(label),
      ),
    );
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
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFEAF1FB),
            backgroundImage:
                person.hasPhoto ? NetworkImage(person.photoUrl!) : null,
            child:
                person.hasPhoto
                    ? null
                    : const Icon(
                      Icons.person_rounded,
                      color: mustBlue,
                      size: 30,
                    ),
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
          const SizedBox(width: 12),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
