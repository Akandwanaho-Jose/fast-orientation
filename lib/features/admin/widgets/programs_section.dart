import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/admin/widgets/admin_shared.dart';
import 'package:fast/features/departments/models/course.dart';
import 'package:fast/features/departments/models/department.dart';
import 'package:fast/features/departments/models/program.dart';
import 'package:flutter/material.dart';

class ProgramsAdminSection extends StatefulWidget {
  const ProgramsAdminSection({super.key});

  @override
  State<ProgramsAdminSection> createState() => _ProgramsAdminSectionState();
}

class _ProgramsAdminSectionState extends State<ProgramsAdminSection> {
  String? _selectedDepartmentId;

  @override
  Widget build(BuildContext context) {
    final departmentsRef = FirebaseFirestore.instance.collection('departments');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: departmentsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }

        if (snapshot.hasError) {
          return const AdminErrorState(
            message: 'Departments could not be loaded for program editing.',
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

        if (departments.isNotEmpty &&
            !_hasDepartment(departments, _selectedDepartmentId)) {
          _selectedDepartmentId = departments.first.id;
        }

        final selectedDepartment = _selectedDepartment(departments);

        return AdminSectionFrame(
          title: 'Programs',
          subtitle:
              'Edit each department program and the year-by-year course outline shown on the public department pages.',
          actions: [
            if (selectedDepartment != null)
              AdminPrimaryActionButton(
                onPressed:
                    () =>
                        _showProgramDialog(departmentId: selectedDepartment.id),
                icon: Icons.add_rounded,
                label: 'New Program',
                compactLabel: 'New',
              ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminCard(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDepartmentId,
                  decoration: InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: departments
                      .map(
                        (department) => DropdownMenuItem(
                          value: department.id,
                          child: Text(department.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() => _selectedDepartmentId = value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (departments.isEmpty)
                const AdminEmptyState(
                  icon: Icons.account_balance_outlined,
                  title: 'No departments found',
                  message:
                      'Create a department before adding programs and course outlines.',
                )
              else if (selectedDepartment == null)
                const AdminEmptyState(
                  icon: Icons.school_outlined,
                  title: 'Select a department',
                  message: 'Choose a department to manage its programs.',
                )
              else
                _ProgramsList(
                  department: selectedDepartment,
                  onEditProgram:
                      (program, docId) => _showProgramDialog(
                        departmentId: selectedDepartment.id,
                        program: program,
                        programDocId: docId,
                      ),
                  onDeleteProgram:
                      (program, docId) => _confirmDeleteProgram(
                        departmentId: selectedDepartment.id,
                        program: program,
                        programDocId: docId,
                      ),
                  onManageCourses:
                      (program, docId) => _showCoursesDialog(
                        departmentId: selectedDepartment.id,
                        program: program,
                        programDocId: docId,
                      ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _hasDepartment(List<Department> departments, String? id) {
    return id != null && departments.any((department) => department.id == id);
  }

  Department? _selectedDepartment(List<Department> departments) {
    for (final department in departments) {
      if (department.id == _selectedDepartmentId) {
        return department;
      }
    }
    return null;
  }

  Future<void> _showProgramDialog({
    required String departmentId,
    Program? program,
    String? programDocId,
  }) async {
    final nameController = TextEditingController(text: program?.name ?? '');
    final slugController = TextEditingController(text: program?.slug ?? '');
    final descriptionController = TextEditingController(
      text: program?.description ?? '',
    );
    final durationController = TextEditingController(
      text: '${program?.durationYears ?? 4}',
    );
    var featured = program?.featured ?? false;
    var status = program?.status ?? 'published';

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
              title: Text(program == null ? 'Create Program' : 'Edit Program'),
              content: SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _field(nameController, 'Program name'),
                      _field(
                        slugController,
                        'Slug',
                        helper:
                            'Used as the program document ID when creating.',
                      ),
                      _field(descriptionController, 'Description', maxLines: 4),
                      _field(
                        durationController,
                        'Duration years',
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
                          if (value != null) setState(() => status = value);
                        },
                      ),
                      const SizedBox(height: 12),
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
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final slug =
                        slugController.text.trim().isEmpty
                            ? slugify(name)
                            : slugify(slugController.text.trim());
                    final docId = programDocId ?? slug;
                    final doc = FirebaseFirestore.instance
                        .collection('departments')
                        .doc(departmentId)
                        .collection('programs')
                        .doc(docId);

                    await doc.set({
                      'id': docId,
                      'name': name,
                      'slug': slug,
                      'description': descriptionController.text.trim(),
                      'durationYears':
                          int.tryParse(durationController.text.trim()) ?? 4,
                      'featured': featured,
                      'status': status,
                      'updatedAt': FieldValue.serverTimestamp(),
                      if (program == null)
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

  Future<void> _confirmDeleteProgram({
    required String departmentId,
    required Program program,
    required String programDocId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Program'),
          content: Text(
            'Delete "${program.name}" and its year course outline? This action cannot be undone.',
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

    if (confirmed != true) return;

    final programRef = FirebaseFirestore.instance
        .collection('departments')
        .doc(departmentId)
        .collection('programs')
        .doc(programDocId);
    final yearDocs = await programRef.collection('yearCourses').get();
    final batch = FirebaseFirestore.instance.batch();
    for (final yearDoc in yearDocs.docs) {
      batch.delete(yearDoc.reference);
    }
    batch.delete(programRef);
    await batch.commit();
  }

  Future<void> _showCoursesDialog({
    required String departmentId,
    required Program program,
    required String programDocId,
  }) async {
    await showDialog<void>(
      context: context,
      builder:
          (context) => _CourseOutlineDialog(
            departmentId: departmentId,
            program: program,
            programDocId: programDocId,
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
}

class _ProgramsList extends StatelessWidget {
  const _ProgramsList({
    required this.department,
    required this.onEditProgram,
    required this.onDeleteProgram,
    required this.onManageCourses,
  });

  final Department department;
  final void Function(Program program, String docId) onEditProgram;
  final void Function(Program program, String docId) onDeleteProgram;
  final void Function(Program program, String docId) onManageCourses;

  @override
  Widget build(BuildContext context) {
    final programsRef = FirebaseFirestore.instance
        .collection('departments')
        .doc(department.id)
        .collection('programs');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: programsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }

        if (snapshot.hasError) {
          return const AdminErrorState(
            message: 'Programs could not be loaded from Firestore.',
          );
        }

        final programs =
            snapshot.data?.docs
                .map((doc) {
                  final program = Program.fromJson(
                    doc.data(),
                    const [],
                    id: doc.id,
                  );
                  return _ProgramRecord(program: program, docId: doc.id);
                })
                .toList(growable: true) ??
            <_ProgramRecord>[];
        programs.sort((a, b) => a.program.name.compareTo(b.program.name));

        if (programs.isEmpty) {
          return const AdminEmptyState(
            icon: Icons.school_outlined,
            title: 'No programs found',
            message:
                'Create the first program to populate this department on the frontend.',
          );
        }

        return Column(
          children: programs
              .map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ProgramCard(
                    record: record,
                    onEdit: () => onEditProgram(record.program, record.docId),
                    onDelete:
                        () => onDeleteProgram(record.program, record.docId),
                    onManageCourses:
                        () => onManageCourses(record.program, record.docId),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
    required this.onManageCourses,
  });

  final _ProgramRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageCourses;

  @override
  Widget build(BuildContext context) {
    final program = record.program;

    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: mustBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school_rounded, color: mustBlue),
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
                    AdminTag(label: program.durationLabel, color: mustBlue),
                    AdminTag(
                      label: program.status,
                      color:
                          program.isPublished
                              ? mustGreen
                              : const Color(0xFFD97706),
                    ),
                    if (program.featured)
                      const AdminTag(
                        label: 'Featured',
                        color: Color(0xFFD97706),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  program.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF152033),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  program.safeDescription,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onManageCourses,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Course Outline'),
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

class _CourseOutlineDialog extends StatefulWidget {
  const _CourseOutlineDialog({
    required this.departmentId,
    required this.program,
    required this.programDocId,
  });

  final String departmentId;
  final Program program;
  final String programDocId;

  @override
  State<_CourseOutlineDialog> createState() => _CourseOutlineDialogState();
}

class _CourseOutlineDialogState extends State<_CourseOutlineDialog> {
  int _selectedYear = 1;

  DocumentReference<Map<String, dynamic>> get _programRef => FirebaseFirestore
      .instance
      .collection('departments')
      .doc(widget.departmentId)
      .collection('programs')
      .doc(widget.programDocId);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('${widget.program.name} Course Outline'),
      content: SizedBox(
        width: 820,
        height: 620,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Academic year',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: List.generate(
                      widget.program.durationYears <= 0
                          ? 4
                          : widget.program.durationYears,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('Year ${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedYear = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                AdminPrimaryActionButton(
                  onPressed: () => _showCourseDialog(year: _selectedYear),
                  icon: Icons.add_rounded,
                  label: 'Add Course',
                  compactLabel: 'Add',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildYearCourses()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildYearCourses() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          _programRef
              .collection('yearCourses')
              .doc('year_$_selectedYear')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }

        if (snapshot.hasError) {
          return const AdminErrorState(
            message: 'The selected year course outline could not load.',
          );
        }

        final yearCourses = YearCourses.fromJson(
          snapshot.data?.data() ?? {'year': _selectedYear, 'courses': []},
        );
        final courses = yearCourses.courses;

        if (courses.isEmpty) {
          return AdminEmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No courses in Year $_selectedYear',
            message:
                'Add courses here and they will appear in the public program outline.',
          );
        }

        return ListView.separated(
          itemCount: courses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final course = courses[index];
            return AdminCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: mustGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.book_rounded, color: mustGreen),
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
                            AdminTag(label: course.code, color: mustBlue),
                            AdminTag(
                              label: '${course.credits} credits',
                              color: mustGreen,
                            ),
                            if (course.semester != null)
                              AdminTag(
                                label: 'Semester ${course.semester}',
                                color: const Color(0xFFD97706),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          course.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF152033),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          course.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AdminOverflowActions(
                    onEdit:
                        () => _showCourseDialog(
                          year: _selectedYear,
                          course: course,
                          index: index,
                        ),
                    onDelete:
                        () => _confirmDeleteCourse(
                          year: _selectedYear,
                          course: course,
                          index: index,
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCourseDialog({
    required int year,
    Course? course,
    int? index,
  }) async {
    final codeController = TextEditingController(text: course?.code ?? '');
    final nameController = TextEditingController(text: course?.name ?? '');
    final descriptionController = TextEditingController(
      text: course?.description ?? '',
    );
    final creditsController = TextEditingController(
      text: '${course?.credits ?? 0}',
    );
    final semesterController = TextEditingController(
      text: course?.semester?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(course == null ? 'Add Course' : 'Edit Course'),
          content: SizedBox(
            width: 680,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _field(codeController, 'Course code'),
                  _field(nameController, 'Course name'),
                  _field(
                    descriptionController,
                    'Course description',
                    maxLines: 5,
                  ),
                  _field(
                    creditsController,
                    'Credits',
                    keyboardType: TextInputType.number,
                  ),
                  _field(
                    semesterController,
                    'Semester',
                    helper: 'Optional. Use 1 or 2 if known.',
                    keyboardType: TextInputType.number,
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
                final newCourse = Course(
                  code: codeController.text.trim(),
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  credits: int.tryParse(creditsController.text.trim()) ?? 0,
                  semester: int.tryParse(semesterController.text.trim()),
                );
                await _saveCourse(year: year, course: newCourse, index: index);
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

  Future<void> _saveCourse({
    required int year,
    required Course course,
    int? index,
  }) async {
    if (course.code.trim().isEmpty || course.name.trim().isEmpty) {
      return;
    }

    final doc = _programRef.collection('yearCourses').doc('year_$year');
    final snapshot = await doc.get();
    final current = YearCourses.fromJson(
      snapshot.data() ?? {'year': year, 'courses': []},
    );
    final courses = current.courses.toList(growable: true);
    if (index != null && index >= 0 && index < courses.length) {
      courses[index] = course;
    } else {
      courses.add(course);
    }

    await doc.set({
      'year': year,
      'courses': courses.map((item) => item.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _confirmDeleteCourse({
    required int year,
    required Course course,
    required int index,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Course'),
          content: Text('Delete "${course.name}" from Year $year?'),
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

    if (confirmed != true) return;

    final doc = _programRef.collection('yearCourses').doc('year_$year');
    final snapshot = await doc.get();
    final current = YearCourses.fromJson(
      snapshot.data() ?? {'year': year, 'courses': []},
    );
    final courses = current.courses.toList(growable: true);
    if (index >= 0 && index < courses.length) {
      courses.removeAt(index);
    }

    await doc.set({
      'year': year,
      'courses': courses.map((item) => item.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
}

class _ProgramRecord {
  const _ProgramRecord({required this.program, required this.docId});

  final Program program;
  final String docId;
}
