import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/services/link_launcher_service.dart';
import 'package:fast/core/theme/fast_brand.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({
    super.key,
    required this.isAuthenticated,
    required this.onOpenAdmin,
    required this.onLogout,
  });

  final bool isAuthenticated;
  final VoidCallback onOpenAdmin;
  final Future<void> Function() onLogout;

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  static const LinkLauncherService _linkLauncher = LinkLauncherService();
  late Future<_MoreData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  Future<_MoreData> _loadData() async {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore.collection('faculty_info').doc('fast').get(),
      firestore.collection('orientation_content').get(),
      firestore.collection('support_resources').get(),
    ]);

    final facultySnapshot =
        results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final orientationSnapshot =
        results[1] as QuerySnapshot<Map<String, dynamic>>;
    final supportSnapshot = results[2] as QuerySnapshot<Map<String, dynamic>>;

    final orientationItems = orientationSnapshot.docs
      .map((doc) => _ContentItem.fromMap(doc.id, doc.data()))
      .where((item) => item.isPublished)
      .toList(growable: true)..sort((a, b) => a.order.compareTo(b.order));

    final supportItems = supportSnapshot.docs
      .map((doc) => _SupportItem.fromMap(doc.id, doc.data()))
      .where((item) => item.isPublished)
      .toList(growable: true)..sort((a, b) => a.order.compareTo(b.order));

    return _MoreData(
      facultyInfo: facultySnapshot.data() ?? <String, dynamic>{},
      orientationItems: orientationItems,
      supportItems: supportItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastBrand.shellBackground,
      body: FutureBuilder<_MoreData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: mustBlue),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final data = snapshot.data ?? _MoreData.empty();
          return RefreshIndicator(
            onRefresh: _refresh,
            color: mustBlue,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                _buildHero(),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'First-Year Orientation Guide',
                  subtitle:
                      'Orientation remains part of the wider FAST experience.',
                  child: _buildOrientationContent(data.orientationItems),
                ),
                _SectionCard(
                  title: 'About FAST',
                  subtitle:
                      'Faculty overview, mission, and vision from your central faculty record.',
                  child: _buildAboutFast(data.facultyInfo),
                ),
                _SectionCard(
                  title: 'Support Resources',
                  subtitle: 'Core support channels for students and staff.',
                  child: _buildSupportResources(data.supportItems),
                ),
                _SectionCard(
                  title: 'Social and Contact',
                  subtitle:
                      'Official FAST links, website, and direct contact points.',
                  child: _buildContactAndSocial(data.facultyInfo),
                ),
                _SectionCard(
                  title: 'Admin Access',
                  subtitle:
                      'Keep public browsing open while giving administrators a clear management entry point.',
                  child: _buildAdminAccess(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: FastBrand.heroDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: FastBrand.glassPillDecoration(),
            child: const Text(
              'More',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Orientation, about FAST, support, and official contact points.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This keeps student support inside the broader faculty platform instead of isolating it as a separate app purpose.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrientationContent(List<_ContentItem> items) {
    if (items.isEmpty) {
      return const _EmptyMessage(
        icon: Icons.menu_book_rounded,
        title: 'No orientation content is published yet.',
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InfoCard(
                icon: Icons.menu_book_rounded,
                title: item.title,
                subtitle: item.summary,
                trailing: item.categoryLabel,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildAboutFast(Map<String, dynamic> facultyInfo) {
    final overview =
        _readString(facultyInfo, 'overview') ??
        'FAST brings together departments, people, programs, stories, and student support in one experience.';
    final vision =
        _readString(facultyInfo, 'vision') ??
        _readString(facultyInfo, 'faculty_vision') ??
        'Vision details will appear here once updated.';
    final mission =
        _readString(facultyInfo, 'mission') ??
        _readString(facultyInfo, 'faculty_mission') ??
        'Mission details will appear here once updated.';

    return Column(
      children: [
        _InfoCard(
          icon: Icons.info_outline_rounded,
          title: 'Overview',
          subtitle: overview,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.visibility_outlined,
          title: 'Vision',
          subtitle: vision,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.flag_outlined,
          title: 'Mission',
          subtitle: mission,
        ),
      ],
    );
  }

  Widget _buildSupportResources(List<_SupportItem> items) {
    if (items.isEmpty) {
      return const _EmptyMessage(
        icon: Icons.support_agent_rounded,
        title: 'No support resources are published yet.',
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SupportCard(
                item: item,
                onOpenUrl:
                    item.url == null
                        ? null
                        : () => _linkLauncher.openUrl(item.url!),
                onEmail:
                    item.contactEmail == null
                        ? null
                        : () => _launchUri(
                          Uri(scheme: 'mailto', path: item.contactEmail),
                        ),
                onCall:
                    item.contactPhone == null
                        ? null
                        : () => _launchUri(
                          Uri(scheme: 'tel', path: item.contactPhone),
                        ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildContactAndSocial(Map<String, dynamic> facultyInfo) {
    final websiteUrl = _readString(facultyInfo, 'websiteUrl');
    final email = _readString(facultyInfo, 'contactEmail');
    final phone = _readString(facultyInfo, 'contactPhone');
    final socialLinks =
        facultyInfo['socialLinks'] is Map
            ? Map<String, dynamic>.from(facultyInfo['socialLinks'] as Map)
            : <String, dynamic>{};

    return Column(
      children: [
        _InfoCard(
          icon: Icons.mail_outline_rounded,
          title: 'Contact',
          subtitle:
              [
                    if (email != null) email,
                    if (phone != null) phone,
                    if (websiteUrl != null) websiteUrl,
                  ].isEmpty
                  ? 'Update faculty_info/fast with contactEmail, contactPhone, and websiteUrl to populate this section.'
                  : [
                    if (email != null) 'Email: $email',
                    if (phone != null) 'Phone: $phone',
                    if (websiteUrl != null) 'Website: $websiteUrl',
                  ].join('\n'),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (websiteUrl != null)
              ElevatedButton.icon(
                onPressed: () => _linkLauncher.openUrl(websiteUrl),
                icon: const Icon(Icons.public_rounded),
                label: const Text('Website'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mustBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ...socialLinks.entries
                .where(
                  (entry) =>
                      entry.value is String &&
                      (entry.value as String).trim().isNotEmpty,
                )
                .map(
                  (entry) => OutlinedButton.icon(
                    onPressed:
                        () => _linkLauncher.openUrl(entry.value as String),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(_titleCase(entry.key)),
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminAccess() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: FastBrand.mutedSurfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isAuthenticated
                ? 'You are signed in.'
                : 'Administrator sign-in is available here.',
            style: const TextStyle(
              color: FastBrand.headingText,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isAuthenticated
                ? 'Use this to leave the public app view and return to signed-out browsing.'
                : 'Keep this entry here instead of in the bottom navigation so the public shell stays focused on students and visitors.',
            style: const TextStyle(
              color: FastBrand.supportText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed:
                widget.isAuthenticated ? widget.onLogout : widget.onOpenAdmin,
            icon: Icon(
              widget.isAuthenticated
                  ? Icons.logout_rounded
                  : Icons.admin_panel_settings_rounded,
            ),
            label: Text(widget.isAuthenticated ? 'Sign Out' : 'Admin Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 14),
            const Text(
              'More could not load right now.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FastBrand.headingText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your Firestore connection and try again.',
              style: const TextStyle(
                color: FastBrand.mutedText,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'[-_\s]+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _MoreData {
  const _MoreData({
    required this.facultyInfo,
    required this.orientationItems,
    required this.supportItems,
  });

  factory _MoreData.empty() {
    return const _MoreData(
      facultyInfo: <String, dynamic>{},
      orientationItems: <_ContentItem>[],
      supportItems: <_SupportItem>[],
    );
  }

  final Map<String, dynamic> facultyInfo;
  final List<_ContentItem> orientationItems;
  final List<_SupportItem> supportItems;
}

class _ContentItem {
  const _ContentItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.order,
    required this.status,
  });

  factory _ContentItem.fromMap(String id, Map<String, dynamic> data) {
    return _ContentItem(
      id: id,
      title: _readString(data, 'title', 'Untitled section'),
      summary: _readString(
        data,
        'summary',
        _readString(data, 'content', 'No summary available yet.'),
      ),
      category: _readString(data, 'category', 'orientation'),
      order: _readInt(data, 'order'),
      status: _readString(data, 'status', 'draft'),
    );
  }

  final String id;
  final String title;
  final String summary;
  final String category;
  final int order;
  final String status;

  bool get isPublished => status == 'published';
  String get categoryLabel {
    return category
        .split(RegExp(r'[-_\s]+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _SupportItem {
  const _SupportItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.contactEmail,
    required this.contactPhone,
    required this.location,
    required this.url,
    required this.order,
    required this.status,
  });

  factory _SupportItem.fromMap(String id, Map<String, dynamic> data) {
    return _SupportItem(
      id: id,
      title: _readString(data, 'title', 'Untitled resource'),
      description: _readString(
        data,
        'description',
        'Support details will appear here once updated.',
      ),
      category: _readString(data, 'category', 'support'),
      contactEmail: _readNullableString(data, 'contactEmail'),
      contactPhone: _readNullableString(data, 'contactPhone'),
      location: _readNullableString(data, 'location'),
      url: _readNullableString(data, 'url'),
      order: _readInt(data, 'order'),
      status: _readString(data, 'status', 'draft'),
    );
  }

  final String id;
  final String title;
  final String description;
  final String category;
  final String? contactEmail;
  final String? contactPhone;
  final String? location;
  final String? url;
  final int order;
  final String status;

  bool get isPublished => status == 'published';
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: FastBrand.surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: FastBrand.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: FastBrand.mutedText, height: 1.5),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: FastBrand.mutedSurfaceDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: FastBrand.tintDecoration(FastBrand.primary, radius: 14),
            child: Icon(icon, color: FastBrand.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trailing != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  decoration: FastBrand.solidPillDecoration(
                    FastBrand.secondary,
                  ),
                  child: Text(
                    trailing!,
                    style: const TextStyle(
                      color: FastBrand.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: FastBrand.headingText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: FastBrand.supportText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.item,
    required this.onOpenUrl,
    required this.onEmail,
    required this.onCall,
  });

  final _SupportItem item;
  final VoidCallback? onOpenUrl;
  final VoidCallback? onEmail;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: FastBrand.mutedSurfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: FastBrand.headingText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: const TextStyle(
              color: FastBrand.supportText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onEmail != null)
                OutlinedButton.icon(
                  onPressed: onEmail,
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Email'),
                ),
              if (onCall != null)
                OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Call'),
                ),
              if (onOpenUrl != null)
                ElevatedButton.icon(
                  onPressed: onOpenUrl,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: FastBrand.mutedSurfaceDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FastBrand.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _readString(Map<String, dynamic> data, String key, String fallback) {
  final value = data[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

String? _readNullableString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

int _readInt(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }
  return 0;
}
