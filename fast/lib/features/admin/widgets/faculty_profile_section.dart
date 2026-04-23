import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/core/widgets/safe_network_avatar.dart';
import 'package:fast/features/admin/widgets/admin_shared.dart';
import 'package:flutter/material.dart';

class FacultyProfileSection extends StatefulWidget {
  const FacultyProfileSection({super.key});

  @override
  State<FacultyProfileSection> createState() => _FacultyProfileSectionState();
}

class _FacultyProfileSectionState extends State<FacultyProfileSection> {
  final _facultyRef = FirebaseFirestore.instance
      .collection('faculty_info')
      .doc('fast');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _facultyRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }

        if (snapshot.hasError) {
          return const AdminErrorState(
            message: 'The faculty profile could not be loaded.',
          );
        }

        final data = snapshot.data?.data() ?? <String, dynamic>{};

        return AdminSectionFrame(
          title: 'Faculty Profile',
          subtitle:
              'Manage the core FAST branding, hero content, dean spotlight, and official contact details.',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showEditDialog(data),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: mustBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          child: Column(
            children: [
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      readString(
                        data,
                        'appName',
                        readString(data, 'shortName', 'FAST Connect'),
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF152033),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      readString(data, 'heroTitle', 'Explore FAST'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: mustBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      readString(
                        data,
                        'heroSubtitle',
                        'Update the faculty profile to define the FAST home experience.',
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 920;
                  if (!wide) {
                    return Column(
                      children: [
                        _buildDeanCard(data),
                        const SizedBox(height: 16),
                        _buildContactCard(data),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDeanCard(data)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildContactCard(data)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview and Direction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF152033),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      readString(
                        data,
                        'overview',
                        'FAST overview text will appear here.',
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vision',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      readString(
                        data,
                        'vision',
                        'Vision details are not set yet.',
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mission',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      readString(
                        data,
                        'mission',
                        'Mission details are not set yet.',
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeanCard(Map<String, dynamic> data) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dean Spotlight',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF152033),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeNetworkAvatar(
                radius: 34,
                imageUrl:
                    readOptionalString(data, 'deanPhotoUrl') ??
                    readOptionalString(data, 'dean_photo_url'),
                backgroundColor: const Color(0xFFEAF1FB),
                fallbackIconColor: mustBlue,
                fallbackIconSize: 34,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      readString(
                        data,
                        'deanName',
                        readString(data, 'dean_name', 'Dean'),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF152033),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      readString(
                        data,
                        'deanMessage',
                        readString(
                          data,
                          'dean_message',
                          'Update the faculty profile with a current dean message.',
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> data) {
    final socialLinks =
        data['socialLinks'] is Map
            ? Map<String, dynamic>.from(data['socialLinks'] as Map)
            : <String, dynamic>{};

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact and Social',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF152033),
            ),
          ),
          const SizedBox(height: 14),
          _infoRow('Email', readOptionalString(data, 'contactEmail')),
          _infoRow('Phone', readOptionalString(data, 'contactPhone')),
          _infoRow('Website', readOptionalString(data, 'websiteUrl')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: socialLinks.entries
                .where(
                  (entry) =>
                      entry.value is String &&
                      (entry.value as String).trim().isNotEmpty,
                )
                .map((entry) => AdminTag(label: entry.key, color: mustGreen))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.trim().isNotEmpty == true ? value!.trim() : 'Not set',
              style: const TextStyle(
                color: Color(0xFF152033),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> data) async {
    final appNameController = TextEditingController(
      text: readString(data, 'appName', 'FAST Connect'),
    );
    final shortNameController = TextEditingController(
      text: readString(data, 'shortName', 'FAST'),
    );
    final heroTitleController = TextEditingController(
      text: readString(data, 'heroTitle', 'Explore FAST'),
    );
    final heroSubtitleController = TextEditingController(
      text: readString(data, 'heroSubtitle', ''),
    );
    final overviewController = TextEditingController(
      text: readString(data, 'overview', ''),
    );
    final visionController = TextEditingController(
      text: readString(data, 'vision', ''),
    );
    final missionController = TextEditingController(
      text: readString(data, 'mission', ''),
    );
    final heroImageController = TextEditingController(
      text: readString(data, 'heroImageUrl', ''),
    );
    final deanNameController = TextEditingController(
      text: readString(data, 'deanName', ''),
    );
    final deanMessageController = TextEditingController(
      text: readString(data, 'deanMessage', ''),
    );
    final deanPhotoController = TextEditingController(
      text: readString(data, 'deanPhotoUrl', ''),
    );
    final emailController = TextEditingController(
      text: readString(data, 'contactEmail', ''),
    );
    final phoneController = TextEditingController(
      text: readString(data, 'contactPhone', ''),
    );
    final websiteController = TextEditingController(
      text: readString(data, 'websiteUrl', ''),
    );
    final socialLinks =
        data['socialLinks'] is Map
            ? Map<String, dynamic>.from(data['socialLinks'] as Map)
            : <String, dynamic>{};
    final facebookController = TextEditingController(
      text: readString(socialLinks, 'facebook', ''),
    );
    final linkedinController = TextEditingController(
      text: readString(socialLinks, 'linkedin', ''),
    );
    final youtubeController = TextEditingController(
      text: readString(socialLinks, 'youtube', ''),
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
          title: const Text('Edit Faculty Profile'),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _field(appNameController, 'App name'),
                  _field(shortNameController, 'Short name'),
                  _field(heroTitleController, 'Hero title'),
                  _field(heroSubtitleController, 'Hero subtitle', maxLines: 3),
                  _field(heroImageController, 'Hero image URL'),
                  _field(overviewController, 'Overview', maxLines: 4),
                  _field(visionController, 'Vision', maxLines: 4),
                  _field(missionController, 'Mission', maxLines: 4),
                  _field(deanNameController, 'Dean name'),
                  _field(deanMessageController, 'Dean message', maxLines: 4),
                  _field(deanPhotoController, 'Dean photo URL'),
                  _field(emailController, 'Contact email'),
                  _field(phoneController, 'Contact phone'),
                  _field(websiteController, 'Website URL'),
                  _field(facebookController, 'Facebook URL'),
                  _field(linkedinController, 'LinkedIn URL'),
                  _field(youtubeController, 'YouTube URL'),
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
                final navigator = Navigator.of(context);
                final stats = await _buildStats();
                await _facultyRef.set({
                  'appName': appNameController.text.trim(),
                  'shortName': shortNameController.text.trim(),
                  'heroTitle': heroTitleController.text.trim(),
                  'heroSubtitle': heroSubtitleController.text.trim(),
                  'heroImageUrl': heroImageController.text.trim(),
                  'overview': overviewController.text.trim(),
                  'vision': visionController.text.trim(),
                  'mission': missionController.text.trim(),
                  'deanName': deanNameController.text.trim(),
                  'deanMessage': deanMessageController.text.trim(),
                  'deanPhotoUrl': deanPhotoController.text.trim(),
                  'contactEmail': emailController.text.trim(),
                  'contactPhone': phoneController.text.trim(),
                  'websiteUrl': websiteController.text.trim(),
                  'socialLinks': {
                    'facebook': facebookController.text.trim(),
                    'linkedin': linkedinController.text.trim(),
                    'youtube': youtubeController.text.trim(),
                  },
                  'stats': stats,
                  'dean_name': deanNameController.text.trim(),
                  'dean_message': deanMessageController.text.trim(),
                  'dean_photo_url': deanPhotoController.text.trim(),
                  'faculty_image_url': heroImageController.text.trim(),
                  'faculty_vision': visionController.text.trim(),
                  'faculty_mission': missionController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
                if (!mounted) return;
                navigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mustBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _buildStats() async {
    final firestore = FirebaseFirestore.instance;
    final departments = await firestore.collection('departments').count().get();
    final staff = await firestore.collection('staff').count().get();
    final programDepartments = await firestore.collection('departments').get();
    var programCount = 0;
    for (final doc in programDepartments.docs) {
      final programs = await doc.reference.collection('programs').count().get();
      programCount += programs.count ?? 0;
    }
    return [
      {'label': 'Departments', 'value': departments.count ?? 0},
      {'label': 'Programs', 'value': programCount},
      {'label': 'Staff', 'value': staff.count ?? 0},
    ];
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
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
