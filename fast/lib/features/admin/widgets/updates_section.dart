import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/admin/widgets/admin_shared.dart';
import 'package:fast/features/annoucements/models/announcement.dart';
import 'package:flutter/material.dart';

class UpdatesAdminSection extends StatefulWidget {
  const UpdatesAdminSection({super.key});

  @override
  State<UpdatesAdminSection> createState() => _UpdatesAdminSectionState();
}

class _UpdatesAdminSectionState extends State<UpdatesAdminSection> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final collection = FirebaseFirestore.instance.collection('announcements');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          collection
              .orderBy('isPinned', descending: true)
              .orderBy('postedAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }

        if (snapshot.hasError) {
          return const AdminErrorState(
            message: 'Updates could not be loaded from Firestore.',
          );
        }

        final announcements =
            snapshot.data?.docs
                .map((doc) => Announcement.fromJson(doc.data(), doc.id))
                .where((item) => _filter == 'all' ? true : item.type == _filter)
                .toList(growable: true) ??
            <Announcement>[];

        return AdminSectionFrame(
          title: 'Updates',
          subtitle:
              'Create and manage announcements, events, deadlines, and opportunities from one structured workflow.',
          actions: [
            Wrap(
              spacing: 8,
              children: [
                _filterChip('all', 'All'),
                _filterChip('announcement', 'Announcements'),
                _filterChip('event', 'Events'),
                _filterChip('deadline', 'Deadlines'),
                _filterChip('opportunity', 'Opportunities'),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showEditDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: mustBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          child:
              announcements.isEmpty
                  ? const AdminEmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'No updates found',
                    message: 'Create the first announcement or event for FAST.',
                  )
                  : Column(
                    children: announcements
                        .map(
                          (announcement) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _UpdateAdminCard(
                              announcement: announcement,
                              onEdit:
                                  () => _showEditDialog(existing: announcement),
                              onDelete:
                                  () => _confirmDelete(
                                    announcement.id,
                                    announcement.title,
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

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _filter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: mustBlue,
      labelStyle: TextStyle(
        color: selected ? Colors.white : mustBlue,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Future<void> _showEditDialog({Announcement? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final categoryController = TextEditingController(
      text: existing?.category ?? '',
    );
    final tagsController = TextEditingController(
      text: joinCsv(existing?.tags ?? const []),
    );
    final audienceController = TextEditingController(
      text: joinCsv(existing?.audience ?? const []),
    );
    final departmentIdsController = TextEditingController(
      text: joinCsv(existing?.departmentIds ?? const []),
    );
    final imageUrlsController = TextEditingController(
      text: joinCsv(existing?.imageUrls ?? const []),
    );
    final actionLabelController = TextEditingController(
      text: existing?.actionLabel ?? '',
    );
    final actionUrlController = TextEditingController(
      text: existing?.actionUrl ?? '',
    );
    var type = existing?.type ?? 'announcement';
    var priority = existing?.priority ?? 'normal';
    var status = existing?.status ?? 'published';
    var isPinned = existing?.isPinned ?? false;
    var featured = existing?.featured ?? false;

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
              title: Text(existing == null ? 'Create Update' : 'Edit Update'),
              content: SizedBox(
                width: 760,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _field(titleController, 'Title'),
                      _field(descriptionController, 'Description', maxLines: 5),
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: _decoration('Type'),
                        items: const [
                          DropdownMenuItem(
                            value: 'announcement',
                            child: Text('Announcement'),
                          ),
                          DropdownMenuItem(
                            value: 'event',
                            child: Text('Event'),
                          ),
                          DropdownMenuItem(
                            value: 'deadline',
                            child: Text('Deadline'),
                          ),
                          DropdownMenuItem(
                            value: 'opportunity',
                            child: Text('Opportunity'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => type = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _field(categoryController, 'Category'),
                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration: _decoration('Priority'),
                        items: const [
                          DropdownMenuItem(
                            value: 'normal',
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem(
                            value: 'important',
                            child: Text('Important'),
                          ),
                          DropdownMenuItem(
                            value: 'urgent',
                            child: Text('Urgent'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => priority = value);
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
                      _field(tagsController, 'Tags (comma separated)'),
                      _field(audienceController, 'Audience (comma separated)'),
                      _field(
                        departmentIdsController,
                        'Department IDs (comma separated)',
                      ),
                      _field(
                        imageUrlsController,
                        'Image URLs (comma separated)',
                        maxLines: 3,
                      ),
                      _field(actionLabelController, 'Action label'),
                      _field(actionUrlController, 'Action URL'),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isPinned,
                        onChanged: (value) => setState(() => isPinned = value),
                        title: const Text('Pinned'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: featured,
                        onChanged: (value) => setState(() => featured = value),
                        title: const Text('Featured'),
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
                      'announcements',
                    );
                    final doc =
                        existing == null
                            ? collection.doc()
                            : collection.doc(existing.id);
                    await doc.set({
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'category': categoryController.text.trim(),
                      'type': type,
                      'priority': priority,
                      'isPinned': isPinned,
                      'featured': featured,
                      'tags': parseCsv(tagsController.text),
                      'audience': parseCsv(audienceController.text),
                      'departmentIds': parseCsv(departmentIdsController.text),
                      'imageUrls': parseCsv(imageUrlsController.text),
                      'actionLabel': actionLabelController.text.trim(),
                      'actionUrl': actionUrlController.text.trim(),
                      'status': status,
                      'updatedAt': FieldValue.serverTimestamp(),
                      'postedAt':
                          existing == null
                              ? FieldValue.serverTimestamp()
                              : Timestamp.fromDate(existing.postedAt),
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

  Future<void> _confirmDelete(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Update'),
          content: Text('Delete "$title"? This action cannot be undone.'),
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
          .collection('announcements')
          .doc(id)
          .delete();
    }
  }
}

class _UpdateAdminCard extends StatelessWidget {
  const _UpdateAdminCard({
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
  });

  final Announcement announcement;
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
                    AdminTag(label: announcement.displayType, color: mustBlue),
                    AdminTag(
                      label: announcement.status,
                      color:
                          announcement.isPublished
                              ? mustGreen
                              : const Color(0xFFD97706),
                    ),
                    if (announcement.isPinned)
                      const AdminTag(label: 'Pinned', color: Color(0xFFE53935)),
                    if (announcement.featured)
                      const AdminTag(
                        label: 'Featured',
                        color: Color(0xFFD97706),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  announcement.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF152033),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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
