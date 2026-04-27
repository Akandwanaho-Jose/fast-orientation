import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/theme/fast_brand.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/annoucements/models/announcement.dart';
import 'package:fast/features/annoucements/screens/annoucement_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _readIds = <String>{};

  String _selectedType = 'all';
  String _searchQuery = '';

  static const List<_TypeFilter> _filters = [
    _TypeFilter(label: 'All', value: 'all', icon: Icons.apps_rounded),
    _TypeFilter(
      label: 'Announcements',
      value: 'announcement',
      icon: Icons.campaign_rounded,
    ),
    _TypeFilter(label: 'Events', value: 'event', icon: Icons.event_rounded),
    _TypeFilter(
      label: 'Deadlines',
      value: 'deadline',
      icon: Icons.schedule_rounded,
    ),
    _TypeFilter(
      label: 'Opportunities',
      value: 'opportunity',
      icon: Icons.star_rounded,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastBrand.shellBackground,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('announcements')
                .orderBy('isPinned', descending: true)
                .orderBy('postedAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: mustBlue),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final all =
              snapshot.data?.docs
                  .map((doc) => Announcement.fromJson(doc.data(), doc.id))
                  .where((announcement) => announcement.isPublished)
                  .where(_matchesType)
                  .where(_matchesSearch)
                  .toList(growable: false) ??
              <Announcement>[];

          final featured = all
              .where((announcement) => announcement.isFeatureCard)
              .take(5)
              .toList(growable: false);

          final groups = _groupByDate(all);
          final bottomInset = MediaQuery.paddingOf(context).bottom;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            color: mustBlue,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(20, 18, 20, 120 + bottomInset),
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildFilterChips(),
                const SizedBox(height: 18),
                if (all.isEmpty)
                  _buildEmptyState()
                else ...[
                  if (featured.isNotEmpty) _buildFeaturedStrip(featured),
                  const SizedBox(height: 22),
                  ..._buildGroupedList(groups),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: FastBrand.surfaceDecoration(radius: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search headlines, notices, and tags...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: FastBrand.primary,
          ),
          suffixIcon:
              _searchQuery.isEmpty
                  ? null
                  : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = filter.value == _selectedType;

          return ChoiceChip(
            avatar: Icon(
              filter.icon,
              size: 16,
              color: selected ? Colors.white : FastBrand.primary,
            ),
            label: Text(filter.label),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedType = filter.value;
              });
            },
            backgroundColor: Colors.white,
            selectedColor: FastBrand.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : FastBrand.primary,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color:
                    selected
                        ? Colors.transparent
                        : FastBrand.primary.withValues(alpha: 0.18),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedStrip(List<Announcement> featured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Top Stories',
                style: TextStyle(
                  color: FastBrand.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              'Editors\' picks',
              style: TextStyle(
                color: FastBrand.mutedText.withValues(alpha: 0.95),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth =
                (constraints.maxWidth * 0.78).clamp(252.0, 330.0).toDouble();

            return SizedBox(
              height: 212,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = featured[index];
                  return SizedBox(
                    width: cardWidth,
                    child: _FeaturedUpdateCard(
                      announcement: item,
                      onOpen: () => _openDetails(item),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Map<String, List<Announcement>> _groupByDate(List<Announcement> items) {
    final groups = <String, List<Announcement>>{
      'Today': <Announcement>[],
      'This Week': <Announcement>[],
      'Earlier': <Announcement>[],
    };

    for (final item in items) {
      groups[_dateBucketFor(item.postedAt)]!.add(item);
    }

    return groups;
  }

  String _dateBucketFor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final day = DateTime(date.year, date.month, date.day);

    if (!day.isBefore(today)) {
      return 'Today';
    }
    if (day.isAfter(weekAgo)) {
      return 'This Week';
    }
    return 'Earlier';
  }

  List<Widget> _buildGroupedList(Map<String, List<Announcement>> groups) {
    final widgets = <Widget>[];

    for (final entry in groups.entries) {
      if (entry.value.isEmpty) {
        continue;
      }

      widgets.add(_buildDateLabel(entry.key));
      for (final announcement in entry.value) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _UpdateCard(
              announcement: announcement,
              isRead: _readIds.contains(announcement.id),
              onOpen: () => _openDetails(announcement),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildDateLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FastBrand.primary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: FastBrand.border, thickness: 1)),
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
              'Updates could not load right now.',
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

  Widget _buildEmptyState() {
    final showingFilteredResults =
        _searchQuery.isNotEmpty || _selectedType != 'all';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: FastBrand.surfaceDecoration(radius: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: FastBrand.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 32,
              color: FastBrand.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No updates match this view yet.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: FastBrand.headingText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            showingFilteredResults
                ? 'Try broadening the search or switch back to all updates.'
                : 'As announcements are published they will appear here.',
            style: const TextStyle(color: FastBrand.mutedText, height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (showingFilteredResults) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedType = 'all';
                });
              },
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  bool _matchesType(Announcement announcement) {
    return _selectedType == 'all' || announcement.type == _selectedType;
  }

  bool _matchesSearch(Announcement announcement) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final searchableText =
        [
          announcement.title,
          announcement.description,
          announcement.displayCategory,
          announcement.displayType,
          ...announcement.tags,
        ].join(' ').toLowerCase();

    return searchableText.contains(_searchQuery);
  }

  void _openDetails(Announcement announcement) {
    HapticFeedback.lightImpact();
    setState(() {
      _readIds.add(announcement.id);
    });

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder:
            (_, animation, __) =>
                AnnouncementDetailsScreen(announcement: announcement),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }
}

class _TypeFilter {
  const _TypeFilter({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _FeaturedUpdateCard extends StatelessWidget {
  const _FeaturedUpdateCard({required this.announcement, required this.onOpen});

  final Announcement announcement;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accent =
        announcement.isUrgent
            ? FastBrand.danger
            : announcement.isPinned
            ? FastBrand.accent
            : FastBrand.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [FastBrand.softShadow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (announcement.hasImages)
                  Image.network(
                    announcement.mainImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gradientFallback(accent),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }
                      return _gradientFallback(accent);
                    },
                  )
                else
                  _gradientFallback(accent),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.28),
                        Colors.black.withValues(alpha: 0.76),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _glassPill(announcement.displayType),
                          const Spacer(),
                          if (announcement.isPinned)
                            const Icon(
                              Icons.push_pin_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          if (announcement.isUrgent)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.priority_high_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            announcement.title,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${announcement.displayCategory} / ${_relativeDate(announcement.postedAt)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_outward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradientFallback(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF122544),
            FastBrand.primary,
            accent.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _glassPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.announcement,
    required this.isRead,
    required this.onOpen,
  });

  final Announcement announcement;
  final bool isRead;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor();
    final priorityLabel = _priorityLabel();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Ink(
          decoration: BoxDecoration(
            color: FastBrand.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  isRead
                      ? FastBrand.border
                      : FastBrand.primary.withValues(alpha: 0.18),
              width: isRead ? 1 : 1.3,
            ),
            boxShadow: const [FastBrand.softShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (announcement.hasImages)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: _ImageStrip(announcement: announcement),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _pill(
                                announcement.displayType,
                                background: FastBrand.primary.withValues(
                                  alpha: 0.10,
                                ),
                                foreground: FastBrand.primary,
                              ),
                              if (priorityLabel != null &&
                                  priorityColor != null)
                                _pill(
                                  priorityLabel,
                                  background: priorityColor.withValues(
                                    alpha: 0.10,
                                  ),
                                  foreground: priorityColor,
                                ),
                              if (announcement.isImportant &&
                                  !announcement.isUrgent)
                                _pill(
                                  'Important',
                                  background: FastBrand.success.withValues(
                                    alpha: 0.10,
                                  ),
                                  foreground: FastBrand.success,
                                ),
                            ],
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(left: 12, top: 4),
                            decoration: const BoxDecoration(
                              color: FastBrand.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color:
                            isRead
                                ? FastBrand.supportText
                                : FastBrand.headingText,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      announcement.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FastBrand.supportText,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    if (announcement.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: announcement.tags
                            .take(3)
                            .map(
                              (tag) => _pill(
                                '#$tag',
                                background: FastBrand.secondary.withValues(
                                  alpha: 0.08,
                                ),
                                foreground: FastBrand.secondary,
                                fontSize: 11,
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_relativeDate(announcement.postedAt)} / ${announcement.displayCategory}',
                            style: const TextStyle(
                              color: FastBrand.mutedText,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_outward_rounded,
                          size: 16,
                          color: FastBrand.primary,
                        ),
                      ],
                    ),
                    if (announcement.hasAction) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: FastBrand.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 15,
                              color: FastBrand.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                announcement.actionLabel ?? 'Learn more',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: FastBrand.secondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _priorityColor() {
    if (announcement.isPinned) {
      return const Color(0xFFD97706);
    }
    if (announcement.isUrgent) {
      return FastBrand.danger;
    }
    return null;
  }

  String? _priorityLabel() {
    if (announcement.isPinned) {
      return 'Pinned';
    }
    if (announcement.isUrgent) {
      return 'Urgent';
    }
    return null;
  }

  Widget _pill(
    String label, {
    required Color background,
    required Color foreground,
    double fontSize = 12,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

class _ImageStrip extends StatefulWidget {
  const _ImageStrip({required this.announcement});

  final Announcement announcement;

  @override
  State<_ImageStrip> createState() => _ImageStripState();
}

class _ImageStripState extends State<_ImageStrip> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.announcement.imageUrls;

    return SizedBox(
      height: 168,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: urls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                urls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: FastBrand.softSurface,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        size: 32,
                        color: FastBrand.mutedText,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }

                  return Container(
                    color: FastBrand.softSurface,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: mustBlue,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (urls.length > 1)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentIndex + 1}/${urls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _relativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }
  if (difference.inDays == 1) {
    return 'Yesterday';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  }
  return '${date.day}/${date.month}/${date.year}';
}
