import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/services/link_launcher_service.dart';
import 'package:fast/core/theme/fast_brand.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/core/widgets/safe_remote_image.dart';
import 'package:fast/features/orientation/models/orientation_content_item.dart';
import 'package:fast/features/orientation/models/orientation_step_content.dart';
import 'package:flutter/material.dart';

class OrientationScreen extends StatefulWidget {
  const OrientationScreen({super.key});

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  late Future<_OrientationScreenData> _future;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedTopic = 'all';
  String _searchQuery = '';

  static const List<_OrientationTopic> _topics = [
    _OrientationTopic(label: 'All', value: 'all', icon: Icons.apps_rounded),
    _OrientationTopic(
      label: 'Start Here',
      value: 'start',
      icon: Icons.explore_rounded,
    ),
    _OrientationTopic(
      label: 'Checklist',
      value: 'checklist',
      icon: Icons.checklist_rounded,
    ),
    _OrientationTopic(
      label: 'Guides',
      value: 'guide',
      icon: Icons.menu_book_rounded,
    ),
    _OrientationTopic(
      label: 'Dates',
      value: 'dates',
      icon: Icons.event_rounded,
    ),
    _OrientationTopic(
      label: 'Resources',
      value: 'resource',
      icon: Icons.link_rounded,
    ),
    _OrientationTopic(
      label: 'Contacts',
      value: 'contact',
      icon: Icons.support_agent_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<_OrientationScreenData> _loadData() async {
    final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      FirebaseFirestore.instance.collection('orientation_content').get(),
      FirebaseFirestore.instance
          .collection('orientation_steps')
          .orderBy('order')
          .get(),
    ]);
    final snapshot = results[0];
    final stepsSnapshot = results[1];
    final items = snapshot.docs
      .map((doc) => OrientationContentItem.fromMap(doc.id, doc.data()))
      .where((item) => item.isPublished)
      .toList(growable: true)..sort(OrientationContentItem.compareForDisplay);
    final allSteps = stepsSnapshot.docs
      .map((doc) => OrientationStepContent.fromMap(doc.id, doc.data()))
      .toList(growable: true)..sort(OrientationStepContent.compareForDisplay);
    final publishedSteps = allSteps
        .where((step) => step.isPublished)
        .toList(growable: false);

    return _OrientationScreenData(
      items: items,
      steps:
          allSteps.isEmpty
              ? OrientationStepContent.defaultSteps
              : publishedSteps,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastBrand.shellBackground,
      body: FutureBuilder<_OrientationScreenData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _OrientationLoadingState();
          }
          if (snapshot.hasError) {
            return const _OrientationErrorState();
          }

          final data = snapshot.data ?? _OrientationScreenData.empty();
          final items = data.items;
          final filteredItems = items
              .where(_matchesTopic)
              .where(_matchesSearch)
              .toList(growable: false);
          final heroItem = _featuredItemFor(items);
          final startItems = _startItemsFor(items);
          final dateItems = _dateItemsFor(items);
          final bottomInset = MediaQuery.paddingOf(context).bottom;

          return RefreshIndicator(
            onRefresh: _refresh,
            color: mustBlue,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(20, 18, 20, 120 + bottomInset),
              children: [
                _OrientationHero(
                  featuredItem: heroItem,
                  stats: _OrientationStats.fromItems(items),
                  onOpenFeatured:
                      heroItem == null ? null : () => _openDetails(heroItem),
                  onBrowseFeed: () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        560,
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
                const SizedBox(height: 14),
                _OrientationSearchField(
                  controller: _searchController,
                  query: _searchQuery,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
                const SizedBox(height: 12),
                _TopicFilterBar(
                  topics: _topics,
                  selectedTopic: _selectedTopic,
                  onSelected: (value) {
                    setState(() {
                      _selectedTopic = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _QuickActionRail(
                  stats: _OrientationStats.fromItems(items),
                  onSelectTopic: (value) {
                    setState(() {
                      _selectedTopic = value;
                    });
                  },
                ),
                if (data.steps.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _OrientationStepGuide(steps: data.steps),
                  const SizedBox(height: 22),
                ] else
                  const SizedBox(height: 22),
                if (items.isEmpty)
                  const _EmptyOrientationState()
                else if (filteredItems.isEmpty)
                  _NoResultsState(
                    onReset: () {
                      _searchController.clear();
                      setState(() {
                        _selectedTopic = 'all';
                        _searchQuery = '';
                      });
                    },
                  )
                else if (_selectedTopic != 'all' || _searchQuery.isNotEmpty)
                  _ArticleFeedSection(
                    title: _activeSectionTitle(filteredItems.length),
                    subtitle: 'Filtered orientation content for quick reading.',
                    items: filteredItems,
                    onOpen: _openDetails,
                  )
                else ...[
                  if (startItems.isNotEmpty) ...[
                    _StartHereStrip(items: startItems, onOpen: _openDetails),
                    const SizedBox(height: 24),
                  ],
                  if (dateItems.isNotEmpty) ...[
                    _UpcomingDatesSection(
                      items: dateItems,
                      onOpen: _openDetails,
                    ),
                    const SizedBox(height: 24),
                  ],
                  _ArticleFeedSection(
                    title: 'Orientation Feed',
                    subtitle:
                        'Guides, resources, contacts, and steps students can revisit anytime.',
                    items: filteredItems,
                    onOpen: _openDetails,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  bool _matchesTopic(OrientationContentItem item) {
    final type = item.type.toLowerCase();
    switch (_selectedTopic) {
      case 'start':
        return item.pinned || type == 'checklist' || type == 'guide';
      case 'dates':
        return type == 'deadline' || type == 'schedule';
      case 'all':
        return true;
      default:
        return type == _selectedTopic;
    }
  }

  bool _matchesSearch(OrientationContentItem item) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final haystack =
        [
          item.title,
          item.summary,
          item.content,
          item.categoryLabel,
          item.typeLabel,
          item.audience.join(' '),
          item.actionLabel ?? '',
        ].join(' ').toLowerCase();

    return haystack.contains(_searchQuery);
  }

  OrientationContentItem? _featuredItemFor(List<OrientationContentItem> items) {
    if (items.isEmpty) {
      return null;
    }

    final pinnedWithImage = items
        .where((item) {
          return item.pinned &&
              SafeRemoteImage.hasDisplayableSource(item.imageUrl);
        })
        .toList(growable: false);
    if (pinnedWithImage.isNotEmpty) {
      return pinnedWithImage.first;
    }

    final pinned = items.where((item) => item.pinned).toList(growable: false);
    if (pinned.isNotEmpty) {
      return pinned.first;
    }

    return items.first;
  }

  List<OrientationContentItem> _startItemsFor(
    List<OrientationContentItem> items,
  ) {
    return items
        .where((item) {
          final type = item.type.toLowerCase();
          return item.pinned || type == 'checklist' || type == 'guide';
        })
        .take(6)
        .toList(growable: false);
  }

  List<OrientationContentItem> _dateItemsFor(
    List<OrientationContentItem> items,
  ) {
    final dated = items
        .where((item) => item.hasDateRange)
        .toList(growable: true);
    dated.sort((a, b) {
      final aDate = a.startDate ?? a.endDate ?? DateTime(9999);
      final bDate = b.startDate ?? b.endDate ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
    return dated.take(4).toList(growable: false);
  }

  String _activeSectionTitle(int count) {
    final topic = _topics.firstWhere(
      (topic) => topic.value == _selectedTopic,
      orElse: () => _topics.first,
    );
    final label = _selectedTopic == 'all' ? 'Results' : topic.label;
    return '$label ($count)';
  }

  void _openDetails(OrientationContentItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrientationDetailSheet(item: item),
    );
  }
}

class _OrientationTopic {
  const _OrientationTopic({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _OrientationScreenData {
  const _OrientationScreenData({required this.items, required this.steps});

  factory _OrientationScreenData.empty() {
    return const _OrientationScreenData(
      items: <OrientationContentItem>[],
      steps: OrientationStepContent.defaultSteps,
    );
  }

  final List<OrientationContentItem> items;
  final List<OrientationStepContent> steps;
}

class _OrientationStats {
  const _OrientationStats({
    required this.total,
    required this.checklists,
    required this.guides,
    required this.dates,
    required this.resources,
    required this.contacts,
  });

  factory _OrientationStats.fromItems(List<OrientationContentItem> items) {
    return _OrientationStats(
      total: items.length,
      checklists: _countType(items, 'checklist'),
      guides: _countType(items, 'guide'),
      dates: _countTypes(items, const ['deadline', 'schedule']),
      resources: _countType(items, 'resource'),
      contacts: _countType(items, 'contact'),
    );
  }

  final int total;
  final int checklists;
  final int guides;
  final int dates;
  final int resources;
  final int contacts;

  static int _countType(List<OrientationContentItem> items, String type) {
    return items.where((item) => item.type.toLowerCase() == type).length;
  }

  static int _countTypes(
    List<OrientationContentItem> items,
    List<String> types,
  ) {
    return items
        .where((item) => types.contains(item.type.toLowerCase()))
        .length;
  }
}

class _OrientationStepGuide extends StatelessWidget {
  const _OrientationStepGuide({required this.steps});

  final List<OrientationStepContent> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: FastBrand.surfaceDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orientation Steps',
            style: TextStyle(
              color: FastBrand.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'A quick guide to the areas most new and continuing students revisit.',
            style: TextStyle(color: FastBrand.mutedText, height: 1.5),
          ),
          const SizedBox(height: 14),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OrientationStepTile(step: step),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrientationStepTile extends StatelessWidget {
  const _OrientationStepTile({required this.step});

  final OrientationStepContent step;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: FastBrand.mutedSurfaceDecoration(radius: 18),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 38,
            height: 38,
            decoration: FastBrand.tintDecoration(FastBrand.primary, radius: 14),
            child: Icon(
              _iconForStep(step.iconKey),
              color: FastBrand.primary,
              size: 20,
            ),
          ),
          title: Text(
            step.title,
            style: const TextStyle(
              color: FastBrand.headingText,
              fontWeight: FontWeight.w800,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step.summary.trim().isNotEmpty) ...[
                    Text(
                      step.summary,
                      style: const TextStyle(
                        color: FastBrand.headingText,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    step.content,
                    style: const TextStyle(
                      color: FastBrand.supportText,
                      height: 1.5,
                    ),
                  ),
                  if (step.hasAction) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _openStepLink(context, step.actionUrl),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(step.actionLabel ?? 'Open link'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForStep(String iconKey) {
    switch (iconKey) {
      case 'admission':
        return Icons.assignment_turned_in_rounded;
      case 'registration':
        return Icons.app_registration_rounded;
      case 'fees':
        return Icons.payments_rounded;
      case 'academic_calendar':
      case 'calendar':
        return Icons.calendar_month_rounded;
      case 'campus_services':
      case 'services':
        return Icons.location_city_rounded;
      case 'student_support':
      case 'support':
        return Icons.support_agent_rounded;
      case 'faqs':
      case 'faq':
        return Icons.help_outline_rounded;
      default:
        return Icons.checklist_rounded;
    }
  }

  Future<void> _openStepLink(BuildContext context, String? url) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await const LinkLauncherService().openUrl(url ?? '');
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open this orientation link.')),
      );
    }
  }
}

class _OrientationHero extends StatelessWidget {
  const _OrientationHero({
    required this.featuredItem,
    required this.stats,
    required this.onOpenFeatured,
    required this.onBrowseFeed,
  });

  final OrientationContentItem? featuredItem;
  final _OrientationStats stats;
  final VoidCallback? onOpenFeatured;
  final VoidCallback onBrowseFeed;

  @override
  Widget build(BuildContext context) {
    final item = featuredItem;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 268),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: FastBrand.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: SafeRemoteImage(
              imageUrl: item?.imageUrl,
              assetFallbackPath: 'assets/images/home/fast_building_hero.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.35),
              fallback: const DecoratedBox(
                decoration: BoxDecoration(gradient: FastBrand.heroGradient),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FastBrand.primary.withValues(alpha: 0.95),
                    FastBrand.primaryStrong.withValues(alpha: 0.84),
                    FastBrand.secondary.withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const _HeroPill(
                      icon: Icons.school_rounded,
                      label: 'FAST Orientation',
                    ),
                    const Spacer(),
                    _HeroCountBadge(count: stats.total),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  item?.title ?? 'Your student launchpad at FAST',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item?.summary ??
                      'Find the steps, dates, resources, and contacts that help you settle in quickly.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (item != null)
                      ElevatedButton.icon(
                        onPressed: onOpenFeatured,
                        icon: const Icon(Icons.article_rounded),
                        label: const Text('Read Featured'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: FastBrand.primary,
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: onBrowseFeed,
                      icon: const Icon(Icons.auto_stories_rounded),
                      label: const Text('Browse Feed'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: FastBrand.glassPillDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCountBadge extends StatelessWidget {
  const _HeroCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$count live',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _OrientationSearchField extends StatelessWidget {
  const _OrientationSearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: FastBrand.surfaceDecoration(radius: 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search guides, dates, contacts, and resources',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: FastBrand.primary,
          ),
          suffixIcon:
              query.isEmpty
                  ? null
                  : IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _TopicFilterBar extends StatelessWidget {
  const _TopicFilterBar({
    required this.topics,
    required this.selectedTopic,
    required this.onSelected,
  });

  final List<_OrientationTopic> topics;
  final String selectedTopic;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final topic = topics[index];
          final selected = topic.value == selectedTopic;

          return ChoiceChip(
            avatar: Icon(
              topic.icon,
              size: 16,
              color: selected ? Colors.white : FastBrand.primary,
            ),
            label: Text(topic.label),
            selected: selected,
            onSelected: (_) => onSelected(topic.value),
            backgroundColor: Colors.white,
            selectedColor: FastBrand.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : FastBrand.primary,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color:
                    selected
                        ? Colors.transparent
                        : FastBrand.primary.withValues(alpha: 0.16),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionRail extends StatelessWidget {
  const _QuickActionRail({required this.stats, required this.onSelectTopic});

  final _OrientationStats stats;
  final ValueChanged<String> onSelectTopic;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        label: 'Checklist',
        value: stats.checklists,
        icon: Icons.checklist_rounded,
        color: FastBrand.secondary,
        topic: 'checklist',
      ),
      _QuickActionData(
        label: 'Dates',
        value: stats.dates,
        icon: Icons.event_rounded,
        color: const Color(0xFFD97706),
        topic: 'dates',
      ),
      _QuickActionData(
        label: 'Guides',
        value: stats.guides,
        icon: Icons.menu_book_rounded,
        color: FastBrand.primaryStrong,
        topic: 'guide',
      ),
      _QuickActionData(
        label: 'Contacts',
        value: stats.contacts,
        icon: Icons.support_agent_rounded,
        color: const Color(0xFF7C3AED),
        topic: 'contact',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        if (compact) {
          return SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 140,
                  child: _QuickActionTile(
                    data: actions[index],
                    onTap: () => onSelectTopic(actions[index].topic),
                  ),
                );
              },
            ),
          );
        }

        return Row(
          children: actions
              .map(
                (action) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: action == actions.last ? 0 : 10,
                    ),
                    child: _QuickActionTile(
                      data: action,
                      onTap: () => onSelectTopic(action.topic),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.topic,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String topic;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.data, required this.onTap});

  final _QuickActionData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FastBrand.border),
            boxShadow: const [FastBrand.softShadow],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: FastBrand.tintDecoration(data.color, radius: 8),
                child: Icon(data.icon, color: data.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${data.value}',
                      style: const TextStyle(
                        color: FastBrand.headingText,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FastBrand.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartHereStrip extends StatelessWidget {
  const _StartHereStrip({required this.items, required this.onOpen});

  final List<OrientationContentItem> items;
  final ValueChanged<OrientationContentItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Start Here',
          subtitle: 'The first reads students should not miss.',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width =
                (constraints.maxWidth * 0.78).clamp(260.0, 340.0).toDouble();
            return SizedBox(
              height: 228,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return SizedBox(
                    width: width,
                    child: _FeaturedOrientationCard(
                      item: item,
                      onOpen: () => onOpen(item),
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
}

class _FeaturedOrientationCard extends StatelessWidget {
  const _FeaturedOrientationCard({required this.item, required this.onOpen});

  final OrientationContentItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [FastBrand.softShadow],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _ArticleImage(
                    item: item,
                    fallbackIcon: _iconForType(item.type),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          FastBrand.primary.withValues(alpha: 0.86),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeBadge(label: item.typeLabel, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
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
}

class _UpcomingDatesSection extends StatelessWidget {
  const _UpcomingDatesSection({required this.items, required this.onOpen});

  final List<OrientationContentItem> items;
  final ValueChanged<OrientationContentItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Dates To Watch',
          subtitle: 'Schedules and deadlines that shape the first weeks.',
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DateCalloutCard(item: item, onOpen: () => onOpen(item)),
          ),
        ),
      ],
    );
  }
}

class _DateCalloutCard extends StatelessWidget {
  const _DateCalloutCard({required this.item, required this.onOpen});

  final OrientationContentItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: FastBrand.tintDecoration(
                  const Color(0xFFD97706),
                  radius: 8,
                  opacity: 0.14,
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateLabel(item),
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: FastBrand.headingText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FastBrand.supportText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD97706)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleFeedSection extends StatelessWidget {
  const _ArticleFeedSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onOpen,
  });

  final String title;
  final String subtitle;
  final List<OrientationContentItem> items;
  final ValueChanged<OrientationContentItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OrientationArticleCard(
              item: item,
              onOpen: () => onOpen(item),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: FastBrand.primary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(color: FastBrand.mutedText, height: 1.45),
        ),
      ],
    );
  }
}

class _OrientationArticleCard extends StatelessWidget {
  const _OrientationArticleCard({required this.item, required this.onOpen});

  final OrientationContentItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = _colorForType(item.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FastBrand.border),
            boxShadow: const [FastBrand.softShadow],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ArticleThumbnail(item: item, accent: accent),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _TypeBadge(label: item.typeLabel, color: accent),
                        if (item.pinned)
                          const _TypeBadge(
                            label: 'Pinned',
                            color: FastBrand.secondary,
                          ),
                        if (item.hasDateRange)
                          const _TypeBadge(
                            label: 'Date',
                            color: Color(0xFFD97706),
                          ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FastBrand.headingText,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FastBrand.supportText,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          item.hasAction
                              ? Icons.open_in_new_rounded
                              : Icons.article_outlined,
                          size: 16,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.hasAction
                                ? item.actionLabel ?? 'Open resource'
                                : 'Read details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
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
    );
  }
}

class _ArticleThumbnail extends StatelessWidget {
  const _ArticleThumbnail({required this.item, required this.accent});

  final OrientationContentItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 112,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: accent.withValues(alpha: 0.1),
      ),
      child: _ArticleImage(item: item, fallbackIcon: _iconForType(item.type)),
    );
  }
}

class _ArticleImage extends StatelessWidget {
  const _ArticleImage({required this.item, required this.fallbackIcon});

  final OrientationContentItem item;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final accent = _colorForType(item.type);
    return SafeRemoteImage(
      imageUrl: item.imageUrl,
      fit: BoxFit.cover,
      assetFallbackPath: 'assets/images/home/fast_building_hero.jpg',
      fallback: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.9),
              FastBrand.primary.withValues(alpha: 0.92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(child: Icon(fallbackIcon, color: Colors.white, size: 32)),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onDark = color == Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color:
            onDark
                ? Colors.white.withValues(alpha: 0.16)
                : color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border:
            onDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.22))
                : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrientationDetailSheet extends StatelessWidget {
  const _OrientationDetailSheet({required this.item});

  static const LinkLauncherService _linkLauncher = LinkLauncherService();

  final OrientationContentItem item;

  @override
  Widget build(BuildContext context) {
    final accent = _colorForType(item.type);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            controller: controller,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 236,
                    width: double.infinity,
                    child: _ArticleImage(
                      item: item,
                      fallbackIcon: _iconForType(item.type),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.08),
                            FastBrand.primary.withValues(alpha: 0.72),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _TypeBadge(
                              label: item.typeLabel,
                              color: Colors.white,
                            ),
                            if (item.categoryLabel != item.typeLabel)
                              _TypeBadge(
                                label: item.categoryLabel,
                                color: Colors.white,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.summary,
                      style: const TextStyle(
                        color: FastBrand.supportText,
                        fontSize: 16,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.hasDateRange ||
                        item.audience.isNotEmpty ||
                        item.departmentId?.isNotEmpty == true) ...[
                      const SizedBox(height: 18),
                      _DetailMetaGrid(item: item, accent: accent),
                    ],
                    if (item.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const Text(
                        'Read',
                        style: TextStyle(
                          color: FastBrand.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.content,
                        style: const TextStyle(
                          color: FastBrand.headingText,
                          height: 1.65,
                          fontSize: 15,
                        ),
                      ),
                    ],
                    if (item.hasAction) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              () => _linkLauncher.openUrl(item.actionUrl!),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(item.actionLabel ?? 'Open resource'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailMetaGrid extends StatelessWidget {
  const _DetailMetaGrid({required this.item, required this.accent});

  final OrientationContentItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final entries = <_MetaEntry>[
      if (item.hasDateRange)
        _MetaEntry(
          icon: Icons.event_rounded,
          label: 'Date',
          value: _dateLabel(item),
        ),
      if (item.audience.isNotEmpty)
        _MetaEntry(
          icon: Icons.groups_rounded,
          label: 'Audience',
          value: item.audience.join(', '),
        ),
      if (item.departmentId?.isNotEmpty == true)
        _MetaEntry(
          icon: Icons.account_tree_rounded,
          label: 'Department',
          value: item.departmentId!,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * 10)) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: entries
              .map(
                (entry) => SizedBox(
                  width: itemWidth,
                  child: _MetaTile(entry: entry, accent: accent),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _MetaEntry {
  const _MetaEntry({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.entry, required this.accent});

  final _MetaEntry entry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(entry.icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.value,
                  style: const TextStyle(
                    color: FastBrand.headingText,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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

class _EmptyOrientationState extends StatelessWidget {
  const _EmptyOrientationState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: FastBrand.mutedSurfaceDecoration(radius: 8),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 44,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No orientation content is published yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FastBrand.headingText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Published guides, checklists, dates, and resources will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FastBrand.mutedText, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: FastBrand.mutedSurfaceDecoration(radius: 8),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No matching orientation items.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FastBrand.headingText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}

class _OrientationLoadingState extends StatelessWidget {
  const _OrientationLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: mustBlue));
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
                fontWeight: FontWeight.w800,
                color: FastBrand.headingText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again.',
              style: TextStyle(color: FastBrand.mutedText, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
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

Color _colorForType(String type) {
  switch (type.toLowerCase()) {
    case 'checklist':
      return FastBrand.secondary;
    case 'deadline':
    case 'schedule':
      return const Color(0xFFD97706);
    case 'resource':
      return FastBrand.primaryStrong;
    case 'contact':
      return const Color(0xFF7C3AED);
    default:
      return FastBrand.primary;
  }
}

String _dateLabel(OrientationContentItem item) {
  final start =
      item.startDate == null ? null : _formatShortDate(item.startDate!);
  final end = item.endDate == null ? null : _formatShortDate(item.endDate!);
  if (start != null && end != null) {
    return '$start - $end';
  }
  return start ?? end ?? 'Date to be confirmed';
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
