import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/models/quick_link.dart';
import 'package:fast/core/services/quick_links_service.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/admin/widgets/admin_shared.dart';
import 'package:fast/features/orientation/models/orientation_step_content.dart';
import 'package:flutter/material.dart';

class ContentHubSection extends StatefulWidget {
  const ContentHubSection({super.key});

  @override
  State<ContentHubSection> createState() => _ContentHubSectionState();
}

class _ContentHubSectionState extends State<ContentHubSection> {
  int _selectedMobileTab = 1;

  static const _tabs = <_ContentHubTab>[
    _ContentHubTab('Stories', _StoriesTab()),
    _ContentHubTab('Orientation', _OrientationTab()),
    _ContentHubTab('Steps', _OrientationStepsTab()),
    _ContentHubTab('Labs', _LabsTab()),
    _ContentHubTab('Support', _SupportTab()),
    _ContentHubTab('Quick Links', _QuickLinksTab()),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    return AdminSectionFrame(
      title: 'Content Hub',
      subtitle:
          'Manage featured stories, orientation content, support resources, and quick link overrides for the wider FAST platform.',
      child: AdminCard(
        padding: EdgeInsets.zero,
        child: compact ? _buildMobileHub() : _buildWideHub(),
      ),
    );
  }

  Widget _buildWideHub() {
    return DefaultTabController(
      initialIndex: _selectedMobileTab,
      length: _tabs.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: mustBlue,
            unselectedLabelColor: Colors.black54,
            indicatorColor: mustBlue,
            tabs: _tabs.map((tab) => Tab(text: tab.label)).toList(),
          ),
          SizedBox(
            height: 720,
            child: TabBarView(children: _tabs.map((tab) => tab.child).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHub() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: DropdownButtonFormField<int>(
            initialValue: _selectedMobileTab,
            decoration: InputDecoration(
              labelText: 'Content type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: [
              for (var i = 0; i < _tabs.length; i++)
                DropdownMenuItem(value: i, child: Text(_tabs[i].label)),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedMobileTab = value);
              }
            },
          ),
        ),
        SizedBox(
          height: 640,
          child: IndexedStack(
            index: _selectedMobileTab,
            children: _tabs.map((tab) => tab.child).toList(),
          ),
        ),
      ],
    );
  }
}

class _ContentHubTab {
  const _ContentHubTab(this.label, this.child);

  final String label;
  final Widget child;
}

class _StoriesTab extends StatelessWidget {
  const _StoriesTab();

  @override
  Widget build(BuildContext context) {
    final collection = FirebaseFirestore.instance.collection(
      'featured_stories',
    );
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection.orderBy('order').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }
        if (snapshot.hasError) {
          return const AdminErrorState(message: 'Stories could not load.');
        }

        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return _ContentListFrame(
            title: 'Featured Stories',
            onAdd: () => _showStoryDialog(context),
            child: const AdminEmptyState(
              icon: Icons.auto_stories_outlined,
              title: 'No featured stories yet',
              message:
                  'Create a featured story to spotlight FAST achievements.',
            ),
          );
        }

        return _ContentListFrame(
          title: 'Featured Stories',
          onAdd: () => _showStoryDialog(context),
          child: ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              return _ContentCard(
                title: readString(data, 'title', 'Untitled story'),
                subtitle: readString(data, 'summary', 'No summary'),
                imageUrl: readOptionalString(data, 'imageUrl'),
                tags: [
                  readString(data, 'status', 'draft'),
                  if (readBool(data, 'featured')) 'featured',
                ],
                onEdit: () => _showStoryDialog(context, id: doc.id, data: data),
                onDelete: () => _deleteDoc(context, collection, doc.id),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showStoryDialog(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final titleController = TextEditingController(
      text: readString(data ?? {}, 'title', ''),
    );
    final summaryController = TextEditingController(
      text: readString(data ?? {}, 'summary', ''),
    );
    final contentController = TextEditingController(
      text: readString(data ?? {}, 'content', ''),
    );
    final imageUrlController = TextEditingController(
      text: readString(data ?? {}, 'imageUrl', ''),
    );
    final authorController = TextEditingController(
      text: readString(data ?? {}, 'authorName', ''),
    );
    final orderController = TextEditingController(
      text: '${readInt(data ?? {}, 'order', fallback: 1)}',
    );
    var featured = readBool(data ?? {}, 'featured');
    var status = readString(data ?? {}, 'status', 'published');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(id == null ? 'Create Story' : 'Edit Story'),
              content: SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _textField(titleController, 'Title'),
                      _textField(summaryController, 'Summary', maxLines: 3),
                      _textField(contentController, 'Content', maxLines: 5),
                      AdminImageUrlField(
                        controller: imageUrlController,
                        label: 'Story image',
                      ),
                      _textField(authorController, 'Author name'),
                      _textField(orderController, 'Display order'),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: featured,
                        onChanged: (value) => setState(() => featured = value),
                        title: const Text('Featured'),
                      ),
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
                      'featured_stories',
                    );
                    final doc =
                        id == null ? collection.doc() : collection.doc(id);
                    await doc.set({
                      'title': titleController.text.trim(),
                      'summary': summaryController.text.trim(),
                      'content': contentController.text.trim(),
                      'imageUrl': imageUrlController.text.trim(),
                      'authorName': authorController.text.trim(),
                      'featured': featured,
                      'order': int.tryParse(orderController.text.trim()) ?? 1,
                      'status': status,
                      'updatedAt': FieldValue.serverTimestamp(),
                      'publishedAt':
                          data == null
                              ? FieldValue.serverTimestamp()
                              : data['publishedAt'] ??
                                  FieldValue.serverTimestamp(),
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
}

class _OrientationTab extends StatelessWidget {
  const _OrientationTab();

  @override
  Widget build(BuildContext context) {
    final collection = FirebaseFirestore.instance.collection(
      'orientation_content',
    );
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection.orderBy('order').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }
        if (snapshot.hasError) {
          return const AdminErrorState(
            message: 'Orientation content could not load.',
          );
        }

        final docs = snapshot.data?.docs ?? const [];
        return _ContentListFrame(
          title: 'Orientation Content',
          onAdd: () => _showOrientationDialog(context),
          child:
              docs.isEmpty
                  ? const AdminEmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'No orientation content yet',
                    message:
                        'Create orientation and student-success entries here.',
                  )
                  : ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      return _ContentCard(
                        title: readString(data, 'title', 'Untitled entry'),
                        subtitle: readString(data, 'summary', 'No summary'),
                        imageUrl: readOptionalString(data, 'imageUrl'),
                        tags: [
                          readString(
                            data,
                            'type',
                            readString(data, 'category', 'orientation'),
                          ),
                          readString(data, 'category', 'orientation'),
                          if (readBool(data, 'pinned')) 'pinned',
                          readString(data, 'status', 'draft'),
                        ],
                        onEdit:
                            () => _showOrientationDialog(
                              context,
                              id: doc.id,
                              data: data,
                            ),
                        onDelete: () => _deleteDoc(context, collection, doc.id),
                      );
                    },
                  ),
        );
      },
    );
  }

  Future<void> _showOrientationDialog(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final existing = data ?? <String, dynamic>{};
    final titleController = TextEditingController(
      text: readString(existing, 'title', ''),
    );
    final slugController = TextEditingController(
      text: readString(existing, 'slug', ''),
    );
    const orientationTypes = [
      'guide',
      'checklist',
      'deadline',
      'resource',
      'contact',
      'schedule',
    ];
    final storedType = readString(existing, 'type', 'guide');
    final initialType =
        orientationTypes.contains(storedType) ? storedType : 'guide';
    final typeController = TextEditingController(text: initialType);
    final categoryController = TextEditingController(
      text: readString(existing, 'category', 'orientation'),
    );
    final summaryController = TextEditingController(
      text: readString(existing, 'summary', ''),
    );
    final contentController = TextEditingController(
      text: readString(existing, 'content', ''),
    );
    final imageUrlController = TextEditingController(
      text: readString(existing, 'imageUrl', ''),
    );
    final audienceController = TextEditingController(
      text: joinCsv(
        (data?['audience'] as List?)?.map((e) => '$e').toList() ?? const [],
      ),
    );
    final departmentIdController = TextEditingController(
      text: readString(existing, 'departmentId', ''),
    );
    final actionLabelController = TextEditingController(
      text: readString(existing, 'actionLabel', ''),
    );
    final actionUrlController = TextEditingController(
      text: readString(existing, 'actionUrl', ''),
    );
    final orderController = TextEditingController(
      text: '${readInt(existing, 'order', fallback: 1)}',
    );
    final startDateController = TextEditingController(
      text: _formatDateValue(existing['startDate']),
    );
    final endDateController = TextEditingController(
      text: _formatDateValue(existing['endDate']),
    );
    var status = readString(existing, 'status', 'published');
    var type = initialType;
    var pinned = readBool(existing, 'pinned');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                id == null
                    ? 'Create Orientation Entry'
                    : 'Edit Orientation Entry',
              ),
              content: SizedBox(
                width: 760,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dialogSection(
                        title: 'Basics',
                        children: [
                          _textField(titleController, 'Title'),
                          _textField(
                            slugController,
                            'Slug',
                            helper:
                                'Leave blank to generate one from the title.',
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: type,
                            decoration: _decoration('Type'),
                            items: const [
                              DropdownMenuItem(
                                value: 'guide',
                                child: Text('Guide'),
                              ),
                              DropdownMenuItem(
                                value: 'checklist',
                                child: Text('Checklist'),
                              ),
                              DropdownMenuItem(
                                value: 'deadline',
                                child: Text('Deadline'),
                              ),
                              DropdownMenuItem(
                                value: 'resource',
                                child: Text('Resource'),
                              ),
                              DropdownMenuItem(
                                value: 'contact',
                                child: Text('Contact'),
                              ),
                              DropdownMenuItem(
                                value: 'schedule',
                                child: Text('Schedule'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                type = value;
                                typeController.text = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _textField(
                            categoryController,
                            'Category',
                            helper:
                                'Example: orientation, student-support, registration.',
                          ),
                        ],
                      ),
                      _dialogSection(
                        title: 'Content',
                        children: [
                          _textField(summaryController, 'Summary', maxLines: 3),
                          _textField(contentController, 'Content', maxLines: 7),
                        ],
                      ),
                      _dialogSection(
                        title: 'Media',
                        children: [
                          AdminImageUrlField(
                            controller: imageUrlController,
                            label: 'Orientation image',
                          ),
                        ],
                      ),
                      _dialogSection(
                        title: 'Targeting',
                        children: [
                          _textField(
                            audienceController,
                            'Audience',
                            helper:
                                'Comma separated: first-year, students, staff.',
                          ),
                          _textField(
                            departmentIdController,
                            'Department ID',
                            helper:
                                'Optional. Leave blank for all FAST students.',
                          ),
                        ],
                      ),
                      _dialogSection(
                        title: 'Action',
                        children: [
                          _textField(
                            actionLabelController,
                            'Action label',
                            helper: 'Example: Open portal, Download guide.',
                          ),
                          _textField(actionUrlController, 'Action URL'),
                        ],
                      ),
                      _dialogSection(
                        title: 'Scheduling',
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 560;
                              final children = [
                                Expanded(
                                  child: _dateField(
                                    context,
                                    startDateController,
                                    'Start date',
                                  ),
                                ),
                                const SizedBox(width: 12, height: 12),
                                Expanded(
                                  child: _dateField(
                                    context,
                                    endDateController,
                                    'End date',
                                  ),
                                ),
                              ];
                              return compact
                                  ? Column(
                                    children: [
                                      _dateField(
                                        context,
                                        startDateController,
                                        'Start date',
                                      ),
                                      const SizedBox(height: 12),
                                      _dateField(
                                        context,
                                        endDateController,
                                        'End date',
                                      ),
                                    ],
                                  )
                                  : Row(children: children);
                            },
                          ),
                        ],
                      ),
                      _dialogSection(
                        title: 'Publishing',
                        children: [
                          SwitchListTile.adaptive(
                            value: pinned,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Pin this item'),
                            subtitle: const Text(
                              'Pinned entries appear before regular orientation content.',
                            ),
                            activeThumbColor: mustBlue,
                            onChanged:
                                (value) => setDialogState(() => pinned = value),
                          ),
                          _textField(
                            orderController,
                            'Display order',
                            keyboardType: TextInputType.number,
                          ),
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
                                setDialogState(() => status = value);
                              }
                            },
                          ),
                        ],
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
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final collection = FirebaseFirestore.instance.collection(
                      'orientation_content',
                    );
                    final doc =
                        id == null ? collection.doc() : collection.doc(id);
                    final imageUrl = imageUrlController.text.trim();
                    final departmentId = departmentIdController.text.trim();
                    final actionLabel = actionLabelController.text.trim();
                    final actionUrl = actionUrlController.text.trim();
                    final startDate = _parseDate(startDateController.text);
                    final endDate = _parseDate(endDateController.text);

                    await doc.set({
                      'title': title,
                      'slug':
                          slugController.text.trim().isEmpty
                              ? slugify(title)
                              : slugify(slugController.text.trim()),
                      'type':
                          typeController.text.trim().isEmpty
                              ? type
                              : typeController.text.trim(),
                      'category': categoryController.text.trim(),
                      'summary': summaryController.text.trim(),
                      'content': contentController.text.trim(),
                      'imageUrl':
                          imageUrl.isEmpty ? FieldValue.delete() : imageUrl,
                      'audience': parseCsv(audienceController.text),
                      'departmentId':
                          departmentId.isEmpty
                              ? FieldValue.delete()
                              : departmentId,
                      'actionLabel':
                          actionLabel.isEmpty
                              ? FieldValue.delete()
                              : actionLabel,
                      'actionUrl':
                          actionUrl.isEmpty ? FieldValue.delete() : actionUrl,
                      'pinned': pinned,
                      'order': int.tryParse(orderController.text.trim()) ?? 1,
                      'status': status,
                      'startDate':
                          startDate == null
                              ? FieldValue.delete()
                              : Timestamp.fromDate(startDate),
                      'endDate':
                          endDate == null
                              ? FieldValue.delete()
                              : Timestamp.fromDate(endDate),
                      'updatedAt': FieldValue.serverTimestamp(),
                      if (id == null) 'createdAt': FieldValue.serverTimestamp(),
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
}

class _OrientationStepsTab extends StatelessWidget {
  const _OrientationStepsTab();

  @override
  Widget build(BuildContext context) {
    final collection = FirebaseFirestore.instance.collection(
      'orientation_steps',
    );
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection.orderBy('order').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }
        if (snapshot.hasError) {
          return const AdminErrorState(
            message: 'Orientation steps could not load.',
          );
        }

        final docs = snapshot.data?.docs ?? const [];
        return _ContentListFrame(
          title: 'Orientation Steps',
          onAdd: () => _showStepDialog(context),
          child:
              docs.isEmpty
                  ? _EmptyStepsState(onSeed: () => _seedDefaultSteps(context))
                  : ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final step = OrientationStepContent.fromMap(
                        doc.id,
                        doc.data(),
                      );
                      return _ContentCard(
                        title: step.title,
                        subtitle:
                            step.summary.isNotEmpty
                                ? step.summary
                                : step.content,
                        imageUrl: null,
                        tags: [
                          _iconLabel(step.iconKey),
                          step.status,
                          'order ${step.order}',
                        ],
                        onEdit:
                            () => _showStepDialog(
                              context,
                              id: doc.id,
                              data: doc.data(),
                            ),
                        onDelete: () => _deleteDoc(context, collection, doc.id),
                      );
                    },
                  ),
        );
      },
    );
  }

  Future<void> _seedDefaultSteps(BuildContext context) async {
    final collection = FirebaseFirestore.instance.collection(
      'orientation_steps',
    );
    final batch = FirebaseFirestore.instance.batch();
    for (final step in OrientationStepContent.defaultSteps) {
      batch.set(collection.doc(step.id), step.toFirestore());
    }
    await batch.commit();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default orientation steps created.')),
    );
  }

  Future<void> _showStepDialog(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final existing =
        data == null ? null : OrientationStepContent.fromMap(id!, data);
    final titleController = TextEditingController(text: existing?.title ?? '');
    final summaryController = TextEditingController(
      text: existing?.summary ?? '',
    );
    final contentController = TextEditingController(
      text: existing?.content ?? '',
    );
    final actionLabelController = TextEditingController(
      text: existing?.actionLabel ?? '',
    );
    final actionUrlController = TextEditingController(
      text: existing?.actionUrl ?? '',
    );
    final orderController = TextEditingController(
      text: '${existing?.order ?? 1}',
    );
    var iconKey = existing?.iconKey ?? 'admission';
    var status = existing?.status ?? 'published';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(id == null ? 'Create Step' : 'Edit Step'),
              content: SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _textField(titleController, 'Step title'),
                      DropdownButtonFormField<String>(
                        initialValue: iconKey,
                        decoration: _decoration('Step icon'),
                        items: const [
                          DropdownMenuItem(
                            value: 'admission',
                            child: Text('Admission'),
                          ),
                          DropdownMenuItem(
                            value: 'registration',
                            child: Text('Registration'),
                          ),
                          DropdownMenuItem(value: 'fees', child: Text('Fees')),
                          DropdownMenuItem(
                            value: 'academic_calendar',
                            child: Text('Academic Calendar'),
                          ),
                          DropdownMenuItem(
                            value: 'campus_services',
                            child: Text('Campus Services'),
                          ),
                          DropdownMenuItem(
                            value: 'student_support',
                            child: Text('Student Support'),
                          ),
                          DropdownMenuItem(value: 'faqs', child: Text('FAQs')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => iconKey = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        summaryController,
                        'Short summary',
                        maxLines: 3,
                        helper: 'Shown first when students expand this step.',
                      ),
                      _textField(
                        contentController,
                        'Full information',
                        maxLines: 7,
                      ),
                      _textField(
                        actionLabelController,
                        'Action label',
                        helper: 'Optional. Example: Open portal.',
                      ),
                      _textField(actionUrlController, 'Action URL'),
                      _textField(
                        orderController,
                        'Display order',
                        keyboardType: TextInputType.number,
                      ),
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
                            setDialogState(() => status = value);
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
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final collection = FirebaseFirestore.instance.collection(
                      'orientation_steps',
                    );
                    final doc =
                        id == null
                            ? collection.doc(slugify(title))
                            : collection.doc(id);
                    final actionLabel = actionLabelController.text.trim();
                    final actionUrl = actionUrlController.text.trim();
                    await doc.set({
                      'title': title,
                      'summary': summaryController.text.trim(),
                      'content': contentController.text.trim(),
                      'iconKey': iconKey,
                      'actionLabel':
                          actionLabel.isEmpty
                              ? FieldValue.delete()
                              : actionLabel,
                      'actionUrl':
                          actionUrl.isEmpty ? FieldValue.delete() : actionUrl,
                      'order': int.tryParse(orderController.text.trim()) ?? 1,
                      'status': status,
                      'updatedAt': FieldValue.serverTimestamp(),
                      if (id == null) 'createdAt': FieldValue.serverTimestamp(),
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

  String _iconLabel(String iconKey) {
    switch (iconKey) {
      case 'admission':
        return 'admission';
      case 'registration':
        return 'registration';
      case 'fees':
        return 'fees';
      case 'academic_calendar':
        return 'calendar';
      case 'campus_services':
        return 'services';
      case 'student_support':
        return 'support';
      case 'faqs':
        return 'faqs';
      default:
        return iconKey;
    }
  }
}

class _EmptyStepsState extends StatelessWidget {
  const _EmptyStepsState({required this.onSeed});

  final VoidCallback onSeed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AdminEmptyState(
          icon: Icons.checklist_rounded,
          title: 'No orientation steps yet',
          message:
              'Create the step cards students open for admission, registration, fees, support, and FAQs.',
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onSeed,
          icon: const Icon(Icons.auto_fix_high_rounded),
          label: const Text('Create default steps'),
          style: ElevatedButton.styleFrom(
            backgroundColor: mustBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _LabsTab extends StatelessWidget {
  const _LabsTab();

  @override
  Widget build(BuildContext context) {
    final collection = FirebaseFirestore.instance.collection(
      'labs_and_facilities',
    );
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection.orderBy('order').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }
        if (snapshot.hasError) {
          return const AdminErrorState(
            message: 'Labs and facilities could not load.',
          );
        }

        final docs = snapshot.data?.docs ?? const [];
        return _ContentListFrame(
          title: 'Labs and Facilities',
          onAdd: () => _showLabDialog(context),
          child:
              docs.isEmpty
                  ? const AdminEmptyState(
                    icon: Icons.apartment_outlined,
                    title: 'No labs or facilities yet',
                    message:
                        'Create facility entries with optional image URLs to populate Explore FAST.',
                  )
                  : ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      return _ContentCard(
                        title: readString(data, 'title', 'Untitled facility'),
                        subtitle: readString(data, 'summary', 'No summary'),
                        imageUrl: readOptionalString(data, 'imageUrl'),
                        tags: [
                          readString(data, 'category', 'facility'),
                          readString(data, 'status', 'draft'),
                        ],
                        onEdit:
                            () =>
                                _showLabDialog(context, id: doc.id, data: data),
                        onDelete: () => _deleteDoc(context, collection, doc.id),
                      );
                    },
                  ),
        );
      },
    );
  }

  Future<void> _showLabDialog(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final titleController = TextEditingController(
      text: readString(data ?? {}, 'title', ''),
    );
    final categoryController = TextEditingController(
      text: readString(data ?? {}, 'category', 'facility'),
    );
    final summaryController = TextEditingController(
      text: readString(data ?? {}, 'summary', ''),
    );
    final descriptionController = TextEditingController(
      text: readString(data ?? {}, 'description', ''),
    );
    final imageUrlController = TextEditingController(
      text: readString(data ?? {}, 'imageUrl', ''),
    );
    final orderController = TextEditingController(
      text: '${readInt(data ?? {}, 'order', fallback: 1)}',
    );
    var status = readString(data ?? {}, 'status', 'published');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            id == null ? 'Create Lab or Facility' : 'Edit Lab or Facility',
          ),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _textField(titleController, 'Title'),
                  _textField(categoryController, 'Category'),
                  _textField(summaryController, 'Summary', maxLines: 3),
                  _textField(descriptionController, 'Description', maxLines: 5),
                  AdminImageUrlField(
                    controller: imageUrlController,
                    label: 'Lab or facility image',
                  ),
                  _textField(orderController, 'Display order'),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: _decoration('Status'),
                    items: const [
                      DropdownMenuItem(
                        value: 'published',
                        child: Text('Published'),
                      ),
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        status = value;
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
                final collection = FirebaseFirestore.instance.collection(
                  'labs_and_facilities',
                );
                final doc = id == null ? collection.doc() : collection.doc(id);
                await doc.set({
                  'title': titleController.text.trim(),
                  'category': categoryController.text.trim(),
                  'summary': summaryController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'imageUrl': imageUrlController.text.trim(),
                  'order': int.tryParse(orderController.text.trim()) ?? 1,
                  'status': status,
                  'updatedAt': FieldValue.serverTimestamp(),
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
  }
}

class _SupportTab extends StatelessWidget {
  const _SupportTab();

  @override
  Widget build(BuildContext context) {
    final collection = FirebaseFirestore.instance.collection(
      'support_resources',
    );
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection.orderBy('order').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }
        if (snapshot.hasError) {
          return const AdminErrorState(
            message: 'Support resources could not load.',
          );
        }

        final docs = snapshot.data?.docs ?? const [];
        return _ContentListFrame(
          title: 'Support Resources',
          onAdd: () => _showSupportDialog(context),
          child:
              docs.isEmpty
                  ? const AdminEmptyState(
                    icon: Icons.support_agent_outlined,
                    title: 'No support resources yet',
                    message: 'Create contact and support records here.',
                  )
                  : ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      return _ContentCard(
                        title: readString(data, 'title', 'Untitled resource'),
                        subtitle: readString(
                          data,
                          'description',
                          'No description',
                        ),
                        imageUrl: null,
                        tags: [
                          readString(data, 'category', 'support'),
                          readString(data, 'status', 'draft'),
                        ],
                        onEdit:
                            () => _showSupportDialog(
                              context,
                              id: doc.id,
                              data: data,
                            ),
                        onDelete: () => _deleteDoc(context, collection, doc.id),
                      );
                    },
                  ),
        );
      },
    );
  }

  Future<void> _showSupportDialog(
    BuildContext context, {
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final titleController = TextEditingController(
      text: readString(data ?? {}, 'title', ''),
    );
    final categoryController = TextEditingController(
      text: readString(data ?? {}, 'category', 'support'),
    );
    final descriptionController = TextEditingController(
      text: readString(data ?? {}, 'description', ''),
    );
    final emailController = TextEditingController(
      text: readString(data ?? {}, 'contactEmail', ''),
    );
    final phoneController = TextEditingController(
      text: readString(data ?? {}, 'contactPhone', ''),
    );
    final locationController = TextEditingController(
      text: readString(data ?? {}, 'location', ''),
    );
    final urlController = TextEditingController(
      text: readString(data ?? {}, 'url', ''),
    );
    final audienceController = TextEditingController(
      text: joinCsv(
        (data?['audience'] as List?)?.map((e) => '$e').toList() ?? const [],
      ),
    );
    final orderController = TextEditingController(
      text: '${readInt(data ?? {}, 'order', fallback: 1)}',
    );
    var status = readString(data ?? {}, 'status', 'published');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            id == null ? 'Create Support Resource' : 'Edit Support Resource',
          ),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _textField(titleController, 'Title'),
                  _textField(categoryController, 'Category'),
                  _textField(descriptionController, 'Description', maxLines: 4),
                  _textField(emailController, 'Contact email'),
                  _textField(phoneController, 'Contact phone'),
                  _textField(locationController, 'Location'),
                  _textField(urlController, 'URL'),
                  _textField(audienceController, 'Audience (comma separated)'),
                  _textField(orderController, 'Display order'),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: _decoration('Status'),
                    items: const [
                      DropdownMenuItem(
                        value: 'published',
                        child: Text('Published'),
                      ),
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        status = value;
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
                final collection = FirebaseFirestore.instance.collection(
                  'support_resources',
                );
                final doc = id == null ? collection.doc() : collection.doc(id);
                await doc.set({
                  'title': titleController.text.trim(),
                  'category': categoryController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'contactEmail': emailController.text.trim(),
                  'contactPhone': phoneController.text.trim(),
                  'location': locationController.text.trim(),
                  'url': urlController.text.trim(),
                  'audience': parseCsv(audienceController.text),
                  'order': int.tryParse(orderController.text.trim()) ?? 1,
                  'status': status,
                  'updatedAt': FieldValue.serverTimestamp(),
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
  }
}

class _QuickLinksTab extends StatelessWidget {
  const _QuickLinksTab();

  @override
  Widget build(BuildContext context) {
    final service = QuickLinksService();
    return StreamBuilder<List<QuickLink>>(
      stream: service.watchAdminQuickLinks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }
        if (snapshot.hasError) {
          return const AdminErrorState(message: 'Quick links could not load.');
        }

        final links = snapshot.data ?? QuickLinksService.defaultLinks;
        return _ContentListFrame(
          title: 'Quick Links',
          onAdd: null,
          child: ListView.separated(
            itemCount: links.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final link = links[index];
              return _ContentCard(
                title: link.title,
                subtitle: link.subtitle,
                imageUrl: null,
                tags: [if (link.enabled) 'enabled' else 'disabled'],
                onEdit: () => _showQuickLinkDialog(context, service, link),
                onDelete: () => service.deleteQuickLinkOverride(link.id),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showQuickLinkDialog(
    BuildContext context,
    QuickLinksService service,
    QuickLink link,
  ) async {
    final titleController = TextEditingController(text: link.title);
    final subtitleController = TextEditingController(text: link.subtitle);
    final urlController = TextEditingController(text: link.url);
    final orderController = TextEditingController(text: '${link.order}');
    var enabled = link.enabled;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text('Edit ${link.title}'),
              content: SizedBox(
                width: 640,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _textField(titleController, 'Title'),
                    _textField(subtitleController, 'Subtitle', maxLines: 3),
                    _textField(urlController, 'URL'),
                    _textField(orderController, 'Display order'),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: enabled,
                      onChanged: (value) => setState(() => enabled = value),
                      title: const Text('Enabled'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await service.saveQuickLinkOverride(
                      link.copyWith(
                        title: titleController.text.trim(),
                        subtitle: subtitleController.text.trim(),
                        url: urlController.text.trim(),
                        order:
                            int.tryParse(orderController.text.trim()) ??
                            link.order,
                        enabled: enabled,
                      ),
                    );
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
}

class _ContentListFrame extends StatelessWidget {
  const _ContentListFrame({
    required this.title,
    required this.child,
    required this.onAdd,
  });

  final String title;
  final Widget child;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ContentListTitle(title: title),
                if (onAdd != null) ...[
                  const SizedBox(height: 12),
                  AdminPrimaryActionButton(
                    onPressed: onAdd!,
                    icon: Icons.add_rounded,
                    label: 'Add',
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _ContentListTitle(title: title)),
                if (onAdd != null)
                  AdminPrimaryActionButton(
                    onPressed: onAdd!,
                    icon: Icons.add_rounded,
                    label: 'Add',
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ContentListTitle extends StatelessWidget {
  const _ContentListTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF152033),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.tags,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final List<String> tags;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminImageThumbnail(imageUrl: imageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .where((tag) => tag.trim().isNotEmpty)
                      .map(
                        (tag) => AdminTag(
                          label: tag,
                          color:
                              tag == 'published' || tag == 'enabled'
                                  ? mustGreen
                                  : mustBlue,
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF152033),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
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

InputDecoration _decoration(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );
}

Widget _textField(
  TextEditingController controller,
  String label, {
  int maxLines = 1,
  String? helper,
  TextInputType? keyboardType,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _decoration(label).copyWith(helperText: helper),
    ),
  );
}

Widget _dialogSection({required String title, required List<Widget> children}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF152033),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

Widget _dateField(
  BuildContext context,
  TextEditingController controller,
  String label,
) {
  return TextField(
    controller: controller,
    readOnly: true,
    decoration: _decoration(label).copyWith(
      helperText: 'Optional',
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.text.trim().isNotEmpty)
            IconButton(
              tooltip: 'Clear date',
              onPressed: () => controller.clear(),
              icon: const Icon(Icons.close_rounded),
            ),
          IconButton(
            tooltip: 'Choose date',
            onPressed: () async {
              final now = DateTime.now();
              final initialDate = _parseDate(controller.text) ?? now;
              final selected = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 5),
              );
              if (selected != null) {
                controller.text = _formatDate(selected);
              }
            },
            icon: const Icon(Icons.calendar_month_rounded),
          ),
        ],
      ),
    ),
  );
}

String _formatDateValue(dynamic value) {
  if (value is Timestamp) {
    return _formatDate(value.toDate());
  }
  if (value is DateTime) {
    return _formatDate(value);
  }
  if (value is String && value.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(value.trim());
    return parsed == null ? value.trim() : _formatDate(parsed);
  }
  return '';
}

String _formatDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

DateTime? _parseDate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return DateTime.tryParse(trimmed);
}

Future<void> _deleteDoc(
  BuildContext context,
  CollectionReference<Map<String, dynamic>> collection,
  String id,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Item'),
        content: const Text('Delete this item? This action cannot be undone.'),
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
    await collection.doc(id).delete();
  }
}
