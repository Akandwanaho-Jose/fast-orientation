import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/services/link_launcher_service.dart';
import 'package:fast/core/theme/fast_brand.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/orientation/models/orientation_content_item.dart';
import 'package:flutter/material.dart';

class OrientationScreen extends StatefulWidget {
  const OrientationScreen({
    super.key,
    required this.isAuthenticated,
    required this.onOpenAdmin,
    required this.onLogout,
  });

  final bool isAuthenticated;
  final VoidCallback onOpenAdmin;
  final Future<void> Function() onLogout;

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  late Future<List<OrientationContentItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadItems();
  }

  Future<List<OrientationContentItem>> _loadItems() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('orientation_content')
            .get();
    final items = snapshot.docs
      .map((doc) => OrientationContentItem.fromMap(doc.id, doc.data()))
      .where((item) => item.isPublished)
      .toList(growable: true)..sort(OrientationContentItem.compareForDisplay);
    return items;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadItems();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrientationContentItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: mustBlue),
          );
        }
        if (snapshot.hasError) {
          return const _OrientationErrorState();
        }

        final items = snapshot.data ?? const <OrientationContentItem>[];
        return RefreshIndicator(
          onRefresh: _refresh,
          color: mustBlue,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              _OrientationHero(totalItems: items.length),
              const SizedBox(height: 16),
              _QuickOrientationGrid(items: items),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const _EmptyOrientationState()
              else ...[
                _PinnedOrientationSection(items: items),
                _OrientationTypeSection(
                  title: 'Checklist',
                  subtitle:
                      'Step-by-step orientation tasks students can act on.',
                  icon: Icons.checklist_rounded,
                  items: _itemsForType(items, 'checklist'),
                ),
                _OrientationTypeSection(
                  title: 'Guides',
                  subtitle:
                      'Longer orientation notes and practical explainers.',
                  icon: Icons.menu_book_rounded,
                  items: _itemsForType(items, 'guide'),
                ),
                _OrientationTypeSection(
                  title: 'Important Dates',
                  subtitle: 'Deadlines, schedules, and time-sensitive items.',
                  icon: Icons.event_rounded,
                  items: [
                    ..._itemsForType(items, 'deadline'),
                    ..._itemsForType(items, 'schedule'),
                  ],
                ),
                _OrientationTypeSection(
                  title: 'Resources',
                  subtitle:
                      'Useful links, files, portals, and support material.',
                  icon: Icons.link_rounded,
                  items: _itemsForType(items, 'resource'),
                ),
                _OrientationTypeSection(
                  title: 'Contacts',
                  subtitle: 'People and offices students can contact for help.',
                  icon: Icons.support_agent_rounded,
                  items: _itemsForType(items, 'contact'),
                ),
              ],
              const SizedBox(height: 16),
              _AdminAccessPanel(
                isAuthenticated: widget.isAuthenticated,
                onOpenAdmin: widget.onOpenAdmin,
                onLogout: widget.onLogout,
              ),
            ],
          ),
        );
      },
    );
  }

  List<OrientationContentItem> _itemsForType(
    List<OrientationContentItem> items,
    String type,
  ) {
    return items
        .where((item) => item.type.toLowerCase() == type)
        .toList(growable: false);
  }
}

class _OrientationHero extends StatelessWidget {
  const _OrientationHero({required this.totalItems});

  final int totalItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: FastBrand.heroDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: FastBrand.glassPillDecoration(),
            child: const Text(
              'FAST Orientation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Start here for guides, checklists, deadlines, and support.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            totalItems == 0
                ? 'Published orientation content will appear here once it is added from the admin panel.'
                : '$totalItems published orientation ${totalItems == 1 ? 'item' : 'items'} available.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickOrientationGrid extends StatelessWidget {
  const _QuickOrientationGrid({required this.items});

  final List<OrientationContentItem> items;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{
      'Checklist': _countType('checklist'),
      'Guides': _countType('guide'),
      'Dates': _countTypes(['deadline', 'schedule']),
      'Resources': _countType('resource'),
    };

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: counts.entries
          .map(
            (entry) => Container(
              padding: const EdgeInsets.all(16),
              decoration: FastBrand.mutedSurfaceDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      color: FastBrand.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      color: FastBrand.headingText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  int _countType(String type) {
    return items.where((item) => item.type.toLowerCase() == type).length;
  }

  int _countTypes(List<String> types) {
    return items
        .where((item) => types.contains(item.type.toLowerCase()))
        .length;
  }
}

class _PinnedOrientationSection extends StatelessWidget {
  const _PinnedOrientationSection({required this.items});

  final List<OrientationContentItem> items;

  @override
  Widget build(BuildContext context) {
    final pinned = items.where((item) => item.pinned).toList(growable: false);
    if (pinned.isEmpty) {
      return const SizedBox.shrink();
    }
    return _OrientationSection(
      title: 'Pinned',
      subtitle: 'Priority orientation items for students.',
      child: Column(
        children: pinned
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrientationItemCard(item: item, emphasized: true),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _OrientationTypeSection extends StatelessWidget {
  const _OrientationTypeSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<OrientationContentItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return _OrientationSection(
      title: title,
      subtitle: subtitle,
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrientationItemCard(item: item, icon: icon),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _OrientationSection extends StatelessWidget {
  const _OrientationSection({
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
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [FastBrand.softShadow],
      ),
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

class _OrientationItemCard extends StatelessWidget {
  const _OrientationItemCard({
    required this.item,
    this.icon,
    this.emphasized = false,
  });

  static const LinkLauncherService _linkLauncher = LinkLauncherService();

  final OrientationContentItem item;
  final IconData? icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final accent = emphasized ? FastBrand.secondary : FastBrand.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showDetails(context),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                emphasized
                    ? FastBrand.secondary.withValues(alpha: 0.08)
                    : FastBrand.shellBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: FastBrand.tintDecoration(accent, radius: 14),
                child: Icon(icon ?? _iconForType(item.type), color: accent),
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
                        _TinyPill(label: item.typeLabel, color: accent),
                        if (item.hasDateRange)
                          _TinyPill(label: _dateLabel(item), color: mustGreen),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: FastBrand.headingText,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FastBrand.supportText,
                        height: 1.45,
                      ),
                    ),
                    if (item.hasAction) ...[
                      const SizedBox(height: 10),
                      Text(
                        item.actionLabel?.isNotEmpty == true
                            ? item.actionLabel!
                            : 'Open resource',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: FastBrand.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TinyPill(label: item.typeLabel, color: FastBrand.primary),
                  const SizedBox(height: 14),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: FastBrand.headingText,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.summary,
                    style: const TextStyle(
                      color: FastBrand.supportText,
                      height: 1.5,
                    ),
                  ),
                  if (item.content.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      item.content,
                      style: const TextStyle(
                        color: FastBrand.headingText,
                        height: 1.58,
                      ),
                    ),
                  ],
                  if (item.hasDateRange) ...[
                    const SizedBox(height: 18),
                    _DetailRow(
                      icon: Icons.event_rounded,
                      text: _dateLabel(item),
                    ),
                  ],
                  if (item.audience.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.groups_rounded,
                      text: item.audience.join(', '),
                    ),
                  ],
                  if (item.hasAction) ...[
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: () => _linkLauncher.openUrl(item.actionUrl!),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(
                        item.actionLabel?.isNotEmpty == true
                            ? item.actionLabel!
                            : 'Open resource',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mustBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'checklist':
        return Icons.checklist_rounded;
      case 'deadline':
      case 'schedule':
        return Icons.event_rounded;
      case 'resource':
        return Icons.link_rounded;
      case 'contact':
        return Icons.support_agent_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  String _dateLabel(OrientationContentItem item) {
    final start =
        item.startDate == null ? null : _formatShortDate(item.startDate!);
    final end = item.endDate == null ? null : _formatShortDate(item.endDate!);
    if (start != null && end != null) {
      return '$start - $end';
    }
    return start ?? end ?? '';
  }

  String _formatShortDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: FastBrand.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: FastBrand.supportText,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminAccessPanel extends StatelessWidget {
  const _AdminAccessPanel({
    required this.isAuthenticated,
    required this.onOpenAdmin,
    required this.onLogout,
  });

  final bool isAuthenticated;
  final VoidCallback onOpenAdmin;
  final Future<void> Function() onLogout;

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
            isAuthenticated
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
            isAuthenticated
                ? 'Use this to leave the admin session and return to public browsing.'
                : 'Sign in here to manage FAST orientation and content.',
            style: const TextStyle(color: FastBrand.supportText, height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isAuthenticated ? onLogout : onOpenAdmin,
            icon: Icon(
              isAuthenticated
                  ? Icons.logout_rounded
                  : Icons.admin_panel_settings_rounded,
            ),
            label: Text(isAuthenticated ? 'Sign Out' : 'Admin Sign In'),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrientationState extends StatelessWidget {
  const _EmptyOrientationState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: FastBrand.mutedSurfaceDecoration(),
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            'No orientation content is published yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FastBrand.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrientationErrorState extends StatelessWidget {
  const _OrientationErrorState();

  @override
  Widget build(BuildContext context) {
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
              'Orientation could not load right now.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FastBrand.headingText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your Firestore connection and try again.',
              style: TextStyle(color: FastBrand.mutedText, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
