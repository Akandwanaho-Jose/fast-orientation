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
            AdminHorizontalScroller(
              child: Row(
                children: [
                  _filterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _filterChip('announcement', 'Announcements'),
                  const SizedBox(width: 8),
                  _filterChip('event', 'Events'),
                  const SizedBox(width: 8),
                  _filterChip('deadline', 'Deadlines'),
                  const SizedBox(width: 8),
                  _filterChip('opportunity', 'Opportunities'),
                ],
              ),
            ),
            AdminPrimaryActionButton(
              onPressed: () => _showEditDialog(),
              icon: Icons.add_rounded,
              label: 'New Update',
              compactLabel: 'New',
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
    final notificationTitleController = TextEditingController(
      text: existing?.pushNotificationTitle ?? '',
    );
    final notificationBodyController = TextEditingController(
      text: existing?.pushNotificationBody ?? '',
    );
    var type = existing?.type ?? 'announcement';
    var priority = existing?.priority ?? 'normal';
    var status = existing?.status ?? 'published';
    var sendPushNotification = existing == null && status == 'published';
    var notificationTopic =
        existing?.pushNotificationTopic ??
        _defaultNotificationTopic(type: type, priority: priority);
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
                        initialValue: type,
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
                          if (value != null) {
                            setState(() {
                              type = value;
                              notificationTopic = _defaultNotificationTopic(
                                type: type,
                                priority: priority,
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _field(categoryController, 'Category'),
                      DropdownButtonFormField<String>(
                        initialValue: priority,
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
                          if (value != null) {
                            setState(() {
                              priority = value;
                              notificationTopic = _defaultNotificationTopic(
                                type: type,
                                priority: priority,
                              );
                            });
                          }
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
                          if (value != null) {
                            setState(() {
                              status = value;
                              if (status != 'published') {
                                sendPushNotification = false;
                              } else if (existing == null) {
                                sendPushNotification = true;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _field(tagsController, 'Tags (comma separated)'),
                      _field(audienceController, 'Audience (comma separated)'),
                      _field(
                        departmentIdsController,
                        'Department IDs (comma separated)',
                      ),
                      AdminImageUrlField(
                        controller: imageUrlsController,
                        label: 'Update images',
                        multiple: true,
                      ),
                      _field(actionLabelController, 'Action label'),
                      _field(actionUrlController, 'Action URL'),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: sendPushNotification,
                              onChanged:
                                  (value) => setState(
                                    () => sendPushNotification = value,
                                  ),
                              title: const Text('Send phone notification'),
                              subtitle: const Text(
                                'New published updates send a short push alert by default. Turn this off for quiet content edits.',
                              ),
                            ),
                            if (sendPushNotification) ...[
                              const SizedBox(height: 10),
                              _field(
                                notificationTitleController,
                                'Notification title',
                              ),
                              _field(
                                notificationBodyController,
                                'Notification highlight',
                                maxLines: 3,
                              ),
                              DropdownButtonFormField<String>(
                                initialValue: notificationTopic,
                                decoration: _decoration(
                                  'Notification audience',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'announcements',
                                    child: Text('All update subscribers'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'urgent_announcements',
                                    child: Text('Urgent alerts'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'events',
                                    child: Text('Events'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'deadlines',
                                    child: Text('Deadlines'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'opportunities',
                                    child: Text('Opportunities'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'academic',
                                    child: Text('Academic'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'general',
                                    child: Text('General'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => notificationTopic = value);
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
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
                    if (sendPushNotification && status != 'published') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Publish the update before sending a phone notification.',
                          ),
                        ),
                      );
                      return;
                    }

                    final title = titleController.text.trim();
                    final description = descriptionController.text.trim();
                    final collection = FirebaseFirestore.instance.collection(
                      'announcements',
                    );
                    final doc =
                        existing == null
                            ? collection.doc()
                            : collection.doc(existing.id);
                    await doc.set({
                      'title': title,
                      'description': description,
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
                    if (sendPushNotification) {
                      await doc.update({
                        'pushNotification.enabled': true,
                        'pushNotification.title':
                            notificationTitleController.text.trim().isEmpty
                                ? _defaultNotificationTitle(title)
                                : notificationTitleController.text.trim(),
                        'pushNotification.body':
                            notificationBodyController.text.trim().isEmpty
                                ? _defaultNotificationBody(description)
                                : notificationBodyController.text.trim(),
                        'pushNotification.topic': notificationTopic,
                        'pushNotification.status': 'pending',
                        'pushNotification.requestedAt':
                            FieldValue.serverTimestamp(),
                        'pushNotification.error': FieldValue.delete(),
                      });
                    } else {
                      await doc.update({'pushNotification.enabled': false});
                    }
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

  String _defaultNotificationTitle(String title) {
    final trimmed = title.trim();
    return trimmed.isEmpty ? 'FAST Update' : trimmed;
  }

  String _defaultNotificationBody(String description) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      return 'A new FAST update has been published.';
    }
    if (trimmed.length <= 120) {
      return trimmed;
    }
    return '${trimmed.substring(0, 117).trimRight()}...';
  }

  String _defaultNotificationTopic({
    required String type,
    required String priority,
  }) {
    if (priority == 'urgent') {
      return 'urgent_announcements';
    }
    switch (type) {
      case 'event':
        return 'events';
      case 'deadline':
        return 'deadlines';
      case 'opportunity':
        return 'opportunities';
      default:
        return 'announcements';
    }
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
          AdminImageThumbnail(
            imageUrl: announcement.mainImageUrl,
            icon: Icons.campaign_rounded,
          ),
          const SizedBox(width: 14),
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
                    if (announcement.hasSentPushNotification)
                      const AdminTag(label: 'Push sent', color: mustGreen),
                    if (announcement.pushNotificationStatus == 'failed')
                      const AdminTag(label: 'Push failed', color: Colors.red),
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
          const SizedBox(width: 8),
          AdminOverflowActions(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}
