import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/services/auth_service.dart';
import 'package:fast/core/theme/fast_brand.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/core/widgets/safe_network_avatar.dart';
import 'package:fast/core/widgets/safe_remote_image.dart';
import 'package:fast/features/annoucements/models/announcement.dart';
import 'package:fast/features/annoucements/screens/annoucement_details_screen.dart';
import 'package:fast/features/auth/screens/login_screen.dart';
import 'package:fast/features/explore/screens/explore_fast_screen.dart';
import 'package:fast/features/more/screens/more_screen.dart';
import 'package:fast/features/people/screens/people_screen.dart';
import 'package:fast/features/quick_links/widgets/quick_links_grid.dart';
import 'package:fast/features/updates/screens/updates_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoggingOut = false;

  List<Widget> _screens(bool isAuthenticated) {
    return [
      _FastHomeTab(
        onExplore: () => _selectIndex(1),
        onUpdates: () => _selectIndex(2),
        onPeople: () => _selectIndex(3),
      ),
      const ExploreFastScreen(),
      const UpdatesScreen(),
      const PeopleScreen(),
      MoreScreen(
        isAuthenticated: isAuthenticated,
        onOpenAdmin: _openAdminLogin,
        onLogout: _logout,
      ),
    ];
  }

  void _selectIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openAdminLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAuthenticated = authService.isLoggedIn;
    final screens = _screens(isAuthenticated);

    return Scaffold(
      backgroundColor: FastBrand.shellBackground,
      appBar: _ShellAppBar(title: _titleForIndex(_selectedIndex)),
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: screens),
          if (_isLoggingOut)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.78),
                child: const Center(
                  child: CircularProgressIndicator(color: mustBlue),
                ),
              ),
            ),
        ],
      ),
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
        return 'More';
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
  });

  final VoidCallback onExplore;
  final VoidCallback onUpdates;
  final VoidCallback onPeople;

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

    return _HomeData(
      facultyInfo: facultyInfo,
      featuredStory: stories.isEmpty ? null : stories.first,
      announcements: announcements,
      deanProfile: deanProfile,
    );
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
              const SizedBox(height: 16),
              _buildStats(data),
              const SizedBox(height: 16),
              if (data.featuredStory != null)
                _buildFeaturedStory(data.featuredStory!),
              if (data.featuredStory != null) const SizedBox(height: 16),
              const QuickLinksGrid(
                title: 'Quick Links',
                subtitle: 'Verified student systems and support tools.',
              ),
              const SizedBox(height: 16),
              _buildLatestUpdates(data.announcements),
              const SizedBox(height: 16),
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
    final stats = _extractStats(data.facultyInfo);

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
          const SizedBox(height: 16),
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
                      padding: const EdgeInsets.all(16),
                      decoration: FastBrand.mutedSurfaceDecoration(radius: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: FastBrand.tintDecoration(
                              FastBrand.primary,
                              radius: 14,
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: FastBrand.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
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
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  announcement.displayType,
                                  style: const TextStyle(
                                    color: FastBrand.mutedText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: FastBrand.primary,
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

class _ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ShellAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titleSpacing: 20,
      title: Row(
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
      label: 'More',
      compactLabel: 'More',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
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
  });

  factory _HomeData.empty() {
    return const _HomeData(
      facultyInfo: <String, dynamic>{},
      featuredStory: null,
      announcements: <Announcement>[],
      deanProfile: _DeanProfile.empty(),
    );
  }

  final Map<String, dynamic> facultyInfo;
  final _FeaturedStory? featuredStory;
  final List<Announcement> announcements;
  final _DeanProfile deanProfile;
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
