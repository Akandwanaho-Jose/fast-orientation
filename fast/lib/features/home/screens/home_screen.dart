import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/theme/fast_brand.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/core/widgets/safe_network_avatar.dart';
import 'package:fast/core/widgets/safe_remote_image.dart';
import 'package:fast/features/annoucements/models/announcement.dart';
import 'package:fast/features/annoucements/screens/annoucement_details_screen.dart';
import 'package:fast/features/explore/screens/explore_fast_screen.dart';
import 'package:fast/features/orientation/screens/orientation_screen.dart';
import 'package:fast/features/people/screens/people_screen.dart';
import 'package:fast/features/quick_links/widgets/quick_links_grid.dart';
import 'package:fast/features/updates/screens/updates_screen.dart';
import 'package:fast/features/updates/widgets/update_share_sheet.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> _screens() {
    return [
      _FastHomeTab(
        onExplore: () => _selectIndex(1),
        onUpdates: () => _selectIndex(2),
        onPeople: () => _selectIndex(3),
        onOrientation: () => _selectIndex(4),
      ),
      const ExploreFastScreen(),
      const UpdatesScreen(),
      const PeopleScreen(),
      const OrientationScreen(),
    ];
  }

  void _selectIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openDeveloperAdminRoute() {
    Navigator.of(context).pushNamed('/admin');
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens();

    return Scaffold(
      backgroundColor: FastBrand.shellBackground,
      appBar: _ShellAppBar(
        title: _titleForIndex(_selectedIndex),
        onDeveloperAdminAccess: kDebugMode ? _openDeveloperAdminRoute : null,
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: _ShellNavigationBar(
        selectedIndex: _selectedIndex,
        onSelected: _selectIndex,
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 1:
        return 'Explore FAST';
      case 2:
        return 'Updates';
      case 3:
        return 'People';
      case 4:
        return 'Orientation';
      default:
        return 'Home';
    }
  }
}

class _FastHomeTab extends StatefulWidget {
  const _FastHomeTab({
    required this.onExplore,
    required this.onUpdates,
    required this.onPeople,
    required this.onOrientation,
  });

  final VoidCallback onExplore;
  final VoidCallback onUpdates;
  final VoidCallback onPeople;
  final VoidCallback onOrientation;

  @override
  State<_FastHomeTab> createState() => _FastHomeTabState();
}

class _FastHomeTabState extends State<_FastHomeTab> {
  late Future<_HomeData> _future;

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

  Future<_HomeData> _loadData() async {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore.collection('faculty_info').doc('fast').get(),
      firestore.collection('featured_stories').get(),
      firestore
          .collection('announcements')
          .orderBy('postedAt', descending: true)
          .limit(8)
          .get(),
    ]);

    final facultySnapshot =
        results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final storiesSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final announcementsSnapshot =
        results[2] as QuerySnapshot<Map<String, dynamic>>;
    final facultyInfo = facultySnapshot.data() ?? <String, dynamic>{};

    final stories = storiesSnapshot.docs
      .map((doc) => _FeaturedStory.fromMap(doc.id, doc.data()))
      .where((story) => story.isPublished)
      .toList(growable: true)..sort((a, b) {
      if (a.order != b.order) {
        return a.order.compareTo(b.order);
      }
      return b.publishedAt.compareTo(a.publishedAt);
    });

    final announcements = announcementsSnapshot.docs
        .map((doc) => Announcement.fromJson(doc.data(), doc.id))
        .where((announcement) => announcement.isPublished)
        .toList(growable: false);

    final deanProfile = await _resolveDeanProfile(facultyInfo, firestore);
    final stats = await _loadLiveStats(firestore);

    return _HomeData(
      facultyInfo: facultyInfo,
      featuredStory: stories.isEmpty ? null : stories.first,
      announcements: announcements,
      deanProfile: deanProfile,
      stats: stats,
    );
  }

  Future<List<_StatItem>> _loadLiveStats(FirebaseFirestore firestore) async {
    final departmentsSnapshot = await firestore.collection('departments').get();
    final publishedDepartments = departmentsSnapshot.docs
        .where((doc) {
          return _readString(doc.data(), 'status', 'published') == 'published';
        })
        .toList(growable: false);

    final programKeys = <String>{};
    for (final department in publishedDepartments) {
      final programsSnapshot =
          await department.reference.collection('programs').get();
      for (final programDoc in programsSnapshot.docs) {
        final data = programDoc.data();
        if (_readString(data, 'status', 'draft') != 'published') {
          continue;
        }
        final slug = _readString(data, 'slug', programDoc.id);
        final name = _readString(data, 'name', slug);
        programKeys.add(_programStatKey(slug: slug, name: name));
      }
    }

    final staffCount =
        await firestore
            .collection('staff')
            .where('status', isEqualTo: 'published')
            .count()
            .get();
    final updateCount =
        await firestore
            .collection('announcements')
            .where('status', isEqualTo: 'published')
            .count()
            .get();

    return [
      _StatItem(label: 'Departments', value: '${publishedDepartments.length}'),
      _StatItem(label: 'Programs', value: '${programKeys.length}'),
      _StatItem(label: 'Staff', value: '${staffCount.count ?? 0}'),
      _StatItem(label: 'Updates', value: '${updateCount.count ?? 0}'),
    ];
  }

  String _programStatKey({required String slug, required String name}) {
    final normalizedName =
        name
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    if (normalizedName.isNotEmpty) {
      return 'name:$normalizedName';
    }

    final normalizedSlug = slug.trim().toLowerCase();
    if (normalizedSlug.isNotEmpty) {
      return 'slug:$normalizedSlug';
    }

    return 'program:unknown';
  }

  Future<_DeanProfile> _resolveDeanProfile(
    Map<String, dynamic> facultyInfo,
    FirebaseFirestore firestore,
  ) async {
    final fallbackName =
        _readOptionalString(facultyInfo, 'deanName') ??
        _readOptionalString(facultyInfo, 'dean_name') ??
        'Dean';
    final fallbackMessage =
        _readOptionalString(facultyInfo, 'deanMessage') ??
        _readOptionalString(facultyInfo, 'dean_message') ??
        'A dean welcome message will appear here once updated.';
    final fallbackPhoto = _readFirstAvailableString(facultyInfo, const [
      'deanPhotoUrl',
      'dean_photo_url',
      'deanImageUrl',
      'dean_image_url',
      'photoUrl',
      'imageUrl',
    ]);

    final deanId = _readOptionalString(facultyInfo, 'deanId');
    if (deanId != null) {
      final deanDoc = await firestore.collection('staff').doc(deanId).get();
      final deanData = deanDoc.data();
      if (deanData != null) {
        return _DeanProfile(
          name: _readOptionalString(deanData, 'name') ?? fallbackName,
          message: _readOptionalString(deanData, 'bio') ?? fallbackMessage,
          photoUrl: _readOptionalString(deanData, 'photoUrl') ?? fallbackPhoto,
        );
      }
    }

    final deanQuery =
        await firestore
            .collection('staff')
            .where('roleType', isEqualTo: 'dean')
            .limit(1)
            .get();
    if (deanQuery.docs.isNotEmpty) {
      final deanData = deanQuery.docs.first.data();
      return _DeanProfile(
        name: _readOptionalString(deanData, 'name') ?? fallbackName,
        message: _readOptionalString(deanData, 'bio') ?? fallbackMessage,
        photoUrl: _readOptionalString(deanData, 'photoUrl') ?? fallbackPhoto,
      );
    }

    final allStaff = await firestore.collection('staff').limit(20).get();
    for (final doc in allStaff.docs) {
      final staffData = doc.data();
      final position =
          _readOptionalString(staffData, 'position')?.toLowerCase() ?? '';
      if (position.contains('dean')) {
        return _DeanProfile(
          name: _readOptionalString(staffData, 'name') ?? fallbackName,
          message: _readOptionalString(staffData, 'bio') ?? fallbackMessage,
          photoUrl: _readOptionalString(staffData, 'photoUrl') ?? fallbackPhoto,
        );
      }
    }

    return _DeanProfile(
      name: fallbackName,
      message: fallbackMessage,
      photoUrl: fallbackPhoto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: mustBlue),
          );
        }

        if (snapshot.hasError) {
          return _HomeErrorState(onRetry: _refresh);
        }

        final data = snapshot.data ?? _HomeData.empty();
        return RefreshIndicator(
          onRefresh: _refresh,
          color: mustBlue,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              _buildHero(data),
              const SizedBox(height: 20),
              _buildStats(data),
              const SizedBox(height: 20),
              _buildExploreFastSection(),
              const SizedBox(height: 20),
              if (data.featuredStory != null)
                _buildFeaturedStory(data.featuredStory!),
              if (data.featuredStory != null) const SizedBox(height: 20),
              const QuickLinksGrid(
                title: 'Quick Links',
                subtitle: 'Verified student systems and support tools.',
              ),
              const SizedBox(height: 20),
              _buildLatestUpdates(data.announcements),
              const SizedBox(height: 20),
              _buildUpcomingEvents(data.announcements),
              const SizedBox(height: 20),
              _buildResearchSpotlight(data.announcements),
              const SizedBox(height: 20),
              _buildDeanSpotlight(data.deanProfile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(_HomeData data) {
    final facultyInfo = data.facultyInfo;
    final heroTitle =
        _readOptionalString(facultyInfo, 'heroTitle') ?? 'Explore FAST';
    final heroSubtitle =
        _readOptionalString(facultyInfo, 'heroSubtitle') ??
        'A faculty platform for discovery, updates, people, and student support.';
    final heroImageUrl =
        _readOptionalString(facultyInfo, 'heroImageUrl') ??
        _readOptionalString(facultyInfo, 'faculty_image_url');

    return Container(
      width: double.infinity,
      decoration: FastBrand.heroDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: SafeRemoteImage(
              imageUrl: heroImageUrl,
              assetFallbackPath: 'assets/images/home/fast_building_hero.jpg',
              fit: BoxFit.cover,
              fallback: DecoratedBox(
                decoration: BoxDecoration(gradient: FastBrand.heroGradient),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FastBrand.primary.withValues(alpha: 0.94),
                    FastBrand.primaryStrong.withValues(alpha: 0.82),
                    FastBrand.secondary.withValues(alpha: 0.74),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: FastBrand.glassPillDecoration(),
                  child: const Text(
                    'FAST Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  heroTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  heroSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.onExplore,
                      icon: const Icon(Icons.travel_explore_rounded),
                      label: const Text('Explore FAST'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: mustBlue,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.onUpdates,
                      icon: const Icon(Icons.campaign_rounded),
                      label: const Text('Latest Updates'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.onPeople,
                      icon: const Icon(Icons.people_alt_rounded),
                      label: const Text('People'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.45),
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

  Widget _buildStats(_HomeData data) {
    final stats =
        data.stats.isNotEmpty ? data.stats : _extractStats(data.facultyInfo);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: FastBrand.surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Faculty Highlights',
            style: TextStyle(
              color: FastBrand.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Live highlights pulled from the restructured faculty record.',
            style: const TextStyle(color: FastBrand.mutedText, height: 1.5),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final singleColumn = width < 260;
              final compact = width < 320;
              final valueFontSize = compact ? 22.0 : 24.0;
              final childAspectRatio =
                  singleColumn ? 2.6 : (compact ? 1.08 : 1.32);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: singleColumn ? 1 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return Container(
                    padding: EdgeInsets.all(compact ? 14 : 16),
                    decoration: FastBrand.mutedSurfaceDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stat.value,
                          style: TextStyle(
                            color: FastBrand.primary,
                            fontSize: valueFontSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            stat.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FastBrand.supportText,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedStory(_FeaturedStory story) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: FastBrand.surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: FastBrand.solidPillDecoration(FastBrand.secondary),
            child: const Text(
              'Featured FAST Story',
              style: TextStyle(
                color: FastBrand.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            story.title,
            style: const TextStyle(
              color: FastBrand.headingText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            story.summary,
            style: const TextStyle(color: FastBrand.supportText, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreFastSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: FastBrand.surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore FAST',
            style: TextStyle(
              color: FastBrand.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start with the main public areas students, staff, alumni, and visitors need most.',
            style: TextStyle(color: FastBrand.mutedText, height: 1.5),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 430;
              final items = [
                _HomeAccessItem(
                  icon: Icons.account_balance_rounded,
                  label: 'Departments',
                  color: FastBrand.primary,
                  onTap: widget.onExplore,
                ),
                _HomeAccessItem(
                  icon: Icons.school_rounded,
                  label: 'Programmes',
                  color: FastBrand.secondary,
                  onTap: widget.onExplore,
                ),
                _HomeAccessItem(
                  icon: Icons.campaign_rounded,
                  label: 'Updates',
                  color: FastBrand.warning,
                  onTap: widget.onUpdates,
                ),
                _HomeAccessItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Orientation',
                  color: FastBrand.primaryStrong,
                  onTap: widget.onOrientation,
                ),
              ];

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: compact ? 2 : 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 118,
                ),
                itemBuilder: (context, index) => items[index],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLatestUpdates(List<Announcement> announcements) {
    final visible = announcements.take(4).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: FastBrand.surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Updates',
            style: TextStyle(
              color: FastBrand.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Recent notices and deadlines from the FAST updates stream.',
            style: const TextStyle(color: FastBrand.mutedText, height: 1.5),
          ),
          const SizedBox(height: 18),
          if (visible.isEmpty)
            Text(
              'No updates are published yet.',
              style: const TextStyle(color: FastBrand.mutedText),
            )
          else
            ...visible.map(
              (announcement) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) => AnnouncementDetailsScreen(
                                announcement: announcement,
                              ),
                        ),
                      );
                    },
                    child: Ink(
                      decoration: FastBrand.mutedSurfaceDecoration(radius: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: _HomeUpdateImage(announcement: announcement),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HomeUpdateBadge(
                                  label: announcement.displayType,
                                  color: FastBrand.primary,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  announcement.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: FastBrand.headingText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  announcement.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: FastBrand.supportText,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 15,
                                      color: FastBrand.mutedText,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _relativeHomeDate(
                                          announcement.postedAt,
                                        ),
                                        style: const TextStyle(
                                          color: FastBrand.mutedText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder:
                                                (_) =>
                                                    AnnouncementDetailsScreen(
                                                      announcement:
                                                          announcement,
                                                    ),
                                          ),
                                        );
                                      },
                                      child: const Text('Read More'),
                                    ),
                                    IconButton(
                                      onPressed:
                                          () => showUpdateShareSheet(
                                            context,
                                            announcement,
                                          ),
                                      tooltip: 'Share update',
                                      icon: const Icon(
                                        Icons.ios_share_rounded,
                                        color: FastBrand.primary,
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
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents(List<Announcement> announcements) {
    final events = announcements
        .where((announcement) => announcement.type == 'event')
        .take(3)
        .toList(growable: false);
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }
    return _HomeCompactUpdateSection(
      title: 'Upcoming Events',
      subtitle:
          'Events and activities recently published for the FAST community.',
      announcements: events,
      icon: Icons.event_rounded,
      accent: FastBrand.secondary,
    );
  }

  Widget _buildResearchSpotlight(List<Announcement> announcements) {
    final spotlight = announcements
        .where(_isResearchOrInnovationUpdate)
        .take(3)
        .toList(growable: false);
    if (spotlight.isEmpty) {
      return const SizedBox.shrink();
    }
    return _HomeCompactUpdateSection(
      title: 'Innovation and Research Spotlight',
      subtitle:
          'Research, innovation, and project stories that show FAST in action.',
      announcements: spotlight,
      icon: Icons.lightbulb_rounded,
      accent: const Color(0xFF5B5FC7),
    );
  }

  bool _isResearchOrInnovationUpdate(Announcement announcement) {
    final text =
        [
          announcement.displayCategory,
          announcement.displayType,
          announcement.title,
          ...announcement.tags,
        ].join(' ').toLowerCase();
    return text.contains('research') ||
        text.contains('innovation') ||
        text.contains('project') ||
        text.contains('lab');
  }

  Widget _buildDeanSpotlight(_DeanProfile deanProfile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: FastBrand.surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dean Spotlight',
            style: TextStyle(
              color: FastBrand.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 320;

              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deanProfile.name,
                    style: const TextStyle(
                      color: FastBrand.headingText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    deanProfile.message,
                    style: const TextStyle(
                      color: FastBrand.supportText,
                      height: 1.6,
                    ),
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DeanAvatar(imageUrl: deanProfile.photoUrl),
                    const SizedBox(height: 14),
                    details,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DeanAvatar(imageUrl: deanProfile.photoUrl),
                  const SizedBox(width: 14),
                  Expanded(child: details),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<_StatItem> _extractStats(Map<String, dynamic> facultyInfo) {
    final rawStats = facultyInfo['stats'];
    if (rawStats is List) {
      final stats = rawStats
          .whereType<Map>()
          .map((entry) {
            final data = Map<String, dynamic>.from(entry);
            return _StatItem(
              label: _readString(data, 'label', 'Stat'),
              value: '${data['value'] ?? 0}',
            );
          })
          .toList(growable: false);
      if (stats.isNotEmpty) {
        return stats;
      }
    }

    return const [
      _StatItem(label: 'Departments', value: '0'),
      _StatItem(label: 'Programs', value: '0'),
      _StatItem(label: 'Staff', value: '0'),
      _StatItem(label: 'Updates', value: '0'),
    ];
  }
}

class _HomeAccessItem extends StatelessWidget {
  const _HomeAccessItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: FastBrand.tintDecoration(color, radius: 14),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FastBrand.headingText,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeUpdateImage extends StatelessWidget {
  const _HomeUpdateImage({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 142,
      width: double.infinity,
      child: SafeRemoteImage(
        imageUrl: announcement.mainImageUrl,
        fit: BoxFit.cover,
        fallback: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FastBrand.primary.withValues(alpha: 0.94),
                FastBrand.primaryStrong.withValues(alpha: 0.84),
                _accentColor().withValues(alpha: 0.78),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(_icon(), color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }

  IconData _icon() {
    switch (announcement.type) {
      case 'event':
        return Icons.event_rounded;
      case 'deadline':
        return Icons.schedule_rounded;
      case 'opportunity':
        return Icons.star_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Color _accentColor() {
    switch (announcement.type) {
      case 'event':
        return FastBrand.secondary;
      case 'deadline':
        return FastBrand.danger;
      case 'opportunity':
        return FastBrand.warning;
      default:
        return FastBrand.primaryStrong;
    }
  }
}

class _HomeUpdateBadge extends StatelessWidget {
  const _HomeUpdateBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: FastBrand.solidPillDecoration(color, opacity: 0.09),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HomeCompactUpdateSection extends StatelessWidget {
  const _HomeCompactUpdateSection({
    required this.title,
    required this.subtitle,
    required this.announcements,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final List<Announcement> announcements;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: FastBrand.surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: FastBrand.tintDecoration(accent, radius: 14),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: FastBrand.mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...announcements.map(
            (announcement) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: FastBrand.softSurface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => AnnouncementDetailsScreen(
                              announcement: announcement,
                            ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: FastBrand.headingText,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _relativeHomeDate(announcement.postedAt),
                                style: const TextStyle(
                                  color: FastBrand.mutedText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed:
                              () => showUpdateShareSheet(context, announcement),
                          tooltip: 'Share update',
                          icon: const Icon(
                            Icons.ios_share_rounded,
                            color: FastBrand.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeHomeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inHours < 24) {
    return difference.inHours == 0
        ? '${difference.inMinutes}m ago'
        : '${difference.inHours}h ago';
  }
  if (difference.inDays == 1) {
    return 'Yesterday';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  }
  return '${date.day}/${date.month}/${date.year}';
}

class _ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ShellAppBar({required this.title, this.onDeveloperAdminAccess});

  final String title;
  final VoidCallback? onDeveloperAdminAccess;

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titleSpacing: 20,
      title: GestureDetector(
        onLongPress: onDeveloperAdminAccess,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: FastBrand.logoSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset('assets/images/MUST_LOGO.png', height: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    FastBrand.shortName,
                    style: TextStyle(
                      color: FastBrand.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: FastBrand.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellNavigationBar extends StatelessWidget {
  const _ShellNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  static const List<_ShellNavItemData> _items = [
    _ShellNavItemData(
      label: 'Home',
      compactLabel: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      color: FastBrand.primary,
      accentColor: FastBrand.primaryStrong,
    ),
    _ShellNavItemData(
      label: 'Explore FAST',
      compactLabel: 'Explore',
      icon: Icons.travel_explore_outlined,
      selectedIcon: Icons.travel_explore_rounded,
      color: FastBrand.secondary,
      accentColor: FastBrand.primaryStrong,
    ),
    _ShellNavItemData(
      label: 'Updates',
      compactLabel: 'Updates',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign_rounded,
      color: FastBrand.warning,
      accentColor: FastBrand.primary,
    ),
    _ShellNavItemData(
      label: 'People',
      compactLabel: 'People',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      color: FastBrand.secondary,
      accentColor: FastBrand.primary,
    ),
    _ShellNavItemData(
      label: 'Orientation',
      compactLabel: 'Orient',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      color: FastBrand.primary,
      accentColor: FastBrand.secondary,
    ),
  ];

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(16, 8, 16, compact ? 10 : 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: FastBrand.border.withValues(alpha: 0.95)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 10,
            vertical: compact ? 8 : 10,
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = selectedIndex == index;
              final label = compact ? item.compactLabel : item.label;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => onSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 2 : 4,
                        vertical: compact ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient:
                            selected
                                ? LinearGradient(
                                  colors: [
                                    item.color.withValues(alpha: 0.16),
                                    item.accentColor.withValues(alpha: 0.08),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                                : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: compact ? 34 : 38,
                            height: compact ? 34 : 38,
                            decoration: BoxDecoration(
                              gradient:
                                  selected
                                      ? LinearGradient(
                                        colors: [item.color, item.accentColor],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                      : null,
                              color: selected ? null : FastBrand.logoSurface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              selected ? item.selectedIcon : item.icon,
                              color:
                                  selected ? Colors.white : FastBrand.mutedText,
                              size: compact ? 18 : 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  selected ? item.color : FastBrand.mutedText,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: compact ? 10.2 : 11.2,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ShellNavItemData {
  const _ShellNavItemData({
    required this.label,
    required this.compactLabel,
    required this.icon,
    required this.selectedIcon,
    required this.color,
    required this.accentColor,
  });

  final String label;
  final String compactLabel;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;
  final Color accentColor;
}

class _DeanAvatar extends StatelessWidget {
  const _DeanAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SafeNetworkAvatar(
      radius: 36,
      imageUrl: imageUrl,
      backgroundColor: const Color(0xFFEAF1FB),
      fallbackIconColor: FastBrand.primary,
      fallbackIconSize: 34,
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.facultyInfo,
    required this.featuredStory,
    required this.announcements,
    required this.deanProfile,
    required this.stats,
  });

  factory _HomeData.empty() {
    return const _HomeData(
      facultyInfo: <String, dynamic>{},
      featuredStory: null,
      announcements: <Announcement>[],
      deanProfile: _DeanProfile.empty(),
      stats: <_StatItem>[],
    );
  }

  final Map<String, dynamic> facultyInfo;
  final _FeaturedStory? featuredStory;
  final List<Announcement> announcements;
  final _DeanProfile deanProfile;
  final List<_StatItem> stats;
}

class _DeanProfile {
  const _DeanProfile({
    required this.name,
    required this.message,
    required this.photoUrl,
  });

  const _DeanProfile.empty()
    : name = 'Dean',
      message = 'A dean welcome message will appear here once updated.',
      photoUrl = null;

  final String name;
  final String message;
  final String? photoUrl;
}

class _FeaturedStory {
  const _FeaturedStory({
    required this.id,
    required this.title,
    required this.summary,
    required this.order,
    required this.publishedAt,
    required this.status,
  });

  factory _FeaturedStory.fromMap(String id, Map<String, dynamic> data) {
    return _FeaturedStory(
      id: id,
      title: _readString(data, 'title', 'Untitled story'),
      summary: _readString(
        data,
        'summary',
        _readString(data, 'content', 'No summary available yet.'),
      ),
      order: _readInt(data, 'order'),
      publishedAt: _readDate(data, 'publishedAt'),
      status: _readString(data, 'status', 'draft'),
    );
  }

  final String id;
  final String title;
  final String summary;
  final int order;
  final DateTime publishedAt;
  final String status;

  bool get isPublished => status == 'published';
}

class _StatItem {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

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
              'Home could not load right now.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FastBrand.headingText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your Firestore connection and try again.',
              style: const TextStyle(color: FastBrand.mutedText, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => onRetry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String? _readOptionalString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

String? _readFirstAvailableString(
  Map<String, dynamic> data,
  List<String> keys,
) {
  for (final key in keys) {
    final value = _readOptionalString(data, key);
    if (value != null) {
      return value;
    }
  }
  return null;
}

String _readString(Map<String, dynamic> data, String key, String fallback) {
  final value = data[key];
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
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

DateTime _readDate(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
