import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/theme/fast_brand.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/core/widgets/safe_remote_image.dart';
import 'package:fast/features/departments/models/department.dart';
import 'package:fast/features/departments/models/program.dart';
import 'package:fast/features/departments/screens/department_details_screen.dart';
import 'package:fast/features/departments/screens/program_details_screen.dart';
import 'package:flutter/material.dart';

class ExploreFastScreen extends StatefulWidget {
  const ExploreFastScreen({super.key});

  @override
  State<ExploreFastScreen> createState() => _ExploreFastScreenState();
}

class _ExploreFastScreenState extends State<ExploreFastScreen> {
  late Future<_ExploreData> _future;

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

  Future<_ExploreData> _loadData() async {
    final firestore = FirebaseFirestore.instance;
    final facultyInfoFuture =
        firestore.collection('faculty_info').doc('fast').get();
    final departmentsFuture = firestore.collection('departments').get();
    final storiesFuture = firestore.collection('featured_stories').get();
    final orientationFuture = firestore.collection('orientation_content').get();
    final facilitiesFuture = firestore.collection('labs_and_facilities').get();

    final results = await Future.wait([
      facultyInfoFuture,
      departmentsFuture,
      storiesFuture,
      orientationFuture,
      facilitiesFuture,
    ]);

    final facultySnapshot =
        results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final departmentsSnapshot =
        results[1] as QuerySnapshot<Map<String, dynamic>>;
    final storiesSnapshot = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final orientationSnapshot =
        results[3] as QuerySnapshot<Map<String, dynamic>>;
    final facilitiesSnapshot =
        results[4] as QuerySnapshot<Map<String, dynamic>>;

    final facultyInfo = facultySnapshot.data() ?? <String, dynamic>{};
    final departments = departmentsSnapshot.docs
      .map(
        (doc) => Department.fromJson({...doc.data(), 'id': doc.id}, const []),
      )
      .where((department) => department.isPublished)
      .toList(growable: true)..sort((a, b) {
      if (a.featured != b.featured) {
        return a.featured ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    final rawPrograms = <_ProgramExplorerItem>[];
    for (final department in departments) {
      final programSnapshot =
          await firestore
              .collection('departments')
              .doc(department.id)
              .collection('programs')
              .get();

      for (final doc in programSnapshot.docs) {
        final program = Program.fromJson(
          {...doc.data(), 'id': doc.id},
          const [],
          id: doc.id,
        );
        if (!program.isPublished) {
          continue;
        }
        rawPrograms.add(
          _ProgramExplorerItem(
            department: department,
            program: program,
            programDocId: doc.id,
          ),
        );
      }
    }

    rawPrograms.sort((a, b) {
      if (a.program.featured != b.program.featured) {
        return a.program.featured ? -1 : 1;
      }
      if (a.department.featured != b.department.featured) {
        return a.department.featured ? -1 : 1;
      }
      final programNameCompare = a.program.name.compareTo(b.program.name);
      if (programNameCompare != 0) {
        return programNameCompare;
      }
      return a.department.name.compareTo(b.department.name);
    });

    final programs = _dedupePrograms(rawPrograms);

    final stories = storiesSnapshot.docs
      .map((doc) => _StoryItem.fromMap(doc.id, doc.data()))
      .where((story) => story.isPublished)
      .toList(growable: true)..sort((a, b) {
      if (a.order != b.order) {
        return a.order.compareTo(b.order);
      }
      return b.publishedAt.compareTo(a.publishedAt);
    });

    final orientationItems = orientationSnapshot.docs
      .map((doc) => _OrientationItem.fromMap(doc.id, doc.data()))
      .where((item) => item.isPublished)
      .toList(growable: true)..sort((a, b) => a.order.compareTo(b.order));

    final facilityItems = facilitiesSnapshot.docs
      .map((doc) => _FacilityItem.fromMap(doc.id, doc.data()))
      .where((item) => item.isPublished)
      .toList(growable: true)..sort((a, b) => a.order.compareTo(b.order));

    return _ExploreData(
      facultyInfo: facultyInfo,
      departments: departments,
      programs: programs,
      stories: stories,
      orientationItems: orientationItems,
      facilityItems: facilityItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastBrand.shellBackground,
      body: FutureBuilder<_ExploreData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ExploreLoadingState();
          }
          if (snapshot.hasError) {
            return _ExploreErrorState(onRetry: _refresh);
          }

          final data = snapshot.data ?? _ExploreData.empty();
          return RefreshIndicator(
            onRefresh: _refresh,
            color: mustBlue,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHero(data)),
                SliverToBoxAdapter(
                  child: _buildDepartmentsSection(data.departments),
                ),
                SliverToBoxAdapter(child: _buildProgramsSection(data.programs)),
                SliverToBoxAdapter(
                  child: _buildLabsAndFacilitiesSection(data.facilityItems),
                ),
                SliverToBoxAdapter(
                  child: _buildStudentExperienceSection(data.orientationItems),
                ),
                SliverToBoxAdapter(
                  child: _buildAchievementsSection(data.stories),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(_ExploreData data) {
    final overview =
        _readString(data.facultyInfo, 'overview') ??
        'Discover departments, programs, stories, and opportunities across FAST.';
    final facultyName =
        _readString(data.facultyInfo, 'name') ??
        'Faculty of Applied Sciences and Technology';
    final heroImageUrl =
        _readString(data.facultyInfo, 'heroImageUrl') ??
        _readString(data.facultyInfo, 'faculty_image_url');

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: FastBrand.glassPillDecoration(),
                  child: const Text(
                    'Explore FAST',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  facultyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  overview,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.account_balance_rounded,
                        label: '${data.departments.length} departments',
                      ),
                      const SizedBox(width: 10),
                      _buildStatChip(
                        icon: Icons.school_rounded,
                        label: '${data.programs.length} programs',
                      ),
                      const SizedBox(width: 10),
                      _buildStatChip(
                        icon: Icons.apartment_rounded,
                        label: '${data.facilityItems.length} facilities',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentsSection(List<Department> departments) {
    return _SectionCard(
      title: 'Departments',
      subtitle: 'Browse the academic homes that make up FAST.',
      child:
          departments.isEmpty
              ? const _EmptySectionMessage(
                icon: Icons.account_balance_outlined,
                title: 'No departments published yet.',
              )
              : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 278,
                ),
                itemCount: departments.length,
                itemBuilder: (context, index) {
                  final department = departments[index];
                  return _DepartmentCard(
                    department: department,
                    onOpen: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) => DepartmentDetailsScreen(
                                department: department,
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }

  Widget _buildProgramsSection(List<_ProgramExplorerItem> programs) {
    return _SectionCard(
      title: 'Programs',
      subtitle:
          'See the degrees and study paths currently available across FAST.',
      child:
          programs.isEmpty
              ? const _EmptySectionMessage(
                icon: Icons.school_outlined,
                title: 'Programs will appear here once published.',
              )
              : Column(
                children: programs
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProgramCard(
                          item: item,
                          onOpen: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder:
                                    (_) => ProgramDetailsScreen(
                                      departmentId: item.department.id,
                                      program: item.program,
                                      programDocId: item.programDocId,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
    );
  }

  Widget _buildLabsAndFacilitiesSection(List<_FacilityItem> facilityItems) {
    return _SectionCard(
      title: 'Labs and Facilities',
      subtitle:
          'Showcase the spaces, labs, studios, and facilities students use across FAST.',
      child:
          facilityItems.isEmpty
              ? const _EmptySectionMessage(
                icon: Icons.apartment_outlined,
                title: 'No labs or facilities published yet.',
              )
              : Column(
                children: facilityItems
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StoryLikeCard(
                          title: item.title,
                          summary: item.summary,
                          pillLabel: item.categoryLabel,
                          icon: Icons.apartment_rounded,
                          imageUrl: item.imageUrl,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
    );
  }

  Widget _buildStudentExperienceSection(
    List<_OrientationItem> orientationItems,
  ) {
    return _SectionCard(
      title: 'Student Experience',
      subtitle:
          'Share onboarding guides, student-life highlights, and support content for new learners.',
      child:
          orientationItems.isEmpty
              ? const _EmptySectionMessage(
                icon: Icons.groups_rounded,
                title: 'No student experience items are published yet.',
              )
              : Column(
                children: orientationItems
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StoryLikeCard(
                          title: item.title,
                          summary: item.summary,
                          pillLabel: item.categoryLabel,
                          icon: Icons.groups_rounded,
                          imageUrl: item.imageUrl,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
    );
  }

  Widget _buildAchievementsSection(List<_StoryItem> stories) {
    return _SectionCard(
      title: 'Faculty Achievements',
      subtitle:
          'Stories and highlights that help showcase FAST to students and partners.',
      child:
          stories.isEmpty
              ? const _EmptySectionMessage(
                icon: Icons.workspace_premium_outlined,
                title: 'No featured stories are published yet.',
              )
              : Column(
                children: stories
                    .take(3)
                    .map(
                      (story) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StoryLikeCard(
                          title: story.title,
                          summary: story.summary,
                          pillLabel:
                              story.featured ? 'Featured story' : 'Story',
                          icon: Icons.workspace_premium_rounded,
                          imageUrl: story.imageUrl,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: FastBrand.glassPillDecoration().copyWith(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String? _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}

class _ExploreData {
  const _ExploreData({
    required this.facultyInfo,
    required this.departments,
    required this.programs,
    required this.stories,
    required this.orientationItems,
    required this.facilityItems,
  });

  factory _ExploreData.empty() {
    return const _ExploreData(
      facultyInfo: <String, dynamic>{},
      departments: <Department>[],
      programs: <_ProgramExplorerItem>[],
      stories: <_StoryItem>[],
      orientationItems: <_OrientationItem>[],
      facilityItems: <_FacilityItem>[],
    );
  }

  final Map<String, dynamic> facultyInfo;
  final List<Department> departments;
  final List<_ProgramExplorerItem> programs;
  final List<_StoryItem> stories;
  final List<_OrientationItem> orientationItems;
  final List<_FacilityItem> facilityItems;
}

class _ProgramExplorerItem {
  const _ProgramExplorerItem({
    required this.department,
    required this.program,
    required this.programDocId,
  });

  final Department department;
  final Program program;
  final String programDocId;
}

List<_ProgramExplorerItem> _dedupePrograms(List<_ProgramExplorerItem> items) {
  final seenKeys = <String>{};
  final uniquePrograms = <_ProgramExplorerItem>[];

  for (final item in items) {
    final key = _programDedupKey(item.program);
    if (seenKeys.add(key)) {
      uniquePrograms.add(item);
    }
  }

  return uniquePrograms;
}

String _programDedupKey(Program program) {
  final slug = program.slug.trim().toLowerCase();
  if (slug.isNotEmpty) {
    return 'slug:$slug';
  }

  final normalizedName =
      program.name
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  return 'name:$normalizedName';
}

class _StoryItem {
  const _StoryItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.imageUrl,
    required this.featured,
    required this.order,
    required this.publishedAt,
    required this.status,
  });

  factory _StoryItem.fromMap(String id, Map<String, dynamic> data) {
    return _StoryItem(
      id: id,
      title: _readString(data, 'title', 'Untitled story'),
      summary: _readString(
        data,
        'summary',
        _readString(data, 'content', 'No story summary available yet.'),
      ),
      imageUrl: _readNullableString(data, 'imageUrl'),
      featured: _readBool(data, 'featured'),
      order: _readInt(data, 'order'),
      publishedAt: _readDate(data, 'publishedAt'),
      status: _readString(data, 'status', 'draft'),
    );
  }

  final String id;
  final String title;
  final String summary;
  final String? imageUrl;
  final bool featured;
  final int order;
  final DateTime publishedAt;
  final String status;

  bool get isPublished => status == 'published';
}

class _OrientationItem {
  const _OrientationItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.imageUrl,
    required this.order,
    required this.status,
  });

  factory _OrientationItem.fromMap(String id, Map<String, dynamic> data) {
    return _OrientationItem(
      id: id,
      title: _readString(data, 'title', 'Untitled section'),
      summary: _readString(
        data,
        'summary',
        _readString(data, 'content', 'No summary available yet.'),
      ),
      category: _readString(data, 'category', 'orientation'),
      imageUrl: _readNullableString(data, 'imageUrl'),
      order: _readInt(data, 'order'),
      status: _readString(data, 'status', 'draft'),
    );
  }

  final String id;
  final String title;
  final String summary;
  final String category;
  final String? imageUrl;
  final int order;
  final String status;

  bool get isPublished => status == 'published';

  String get categoryLabel {
    if (category.isEmpty) return 'Guide';
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

class _FacilityItem {
  const _FacilityItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.imageUrl,
    required this.order,
    required this.status,
  });

  factory _FacilityItem.fromMap(String id, Map<String, dynamic> data) {
    return _FacilityItem(
      id: id,
      title: _readString(data, 'title', 'Untitled facility'),
      summary: _readString(
        data,
        'summary',
        _readString(data, 'description', 'No summary available yet.'),
      ),
      category: _readString(data, 'category', 'facility'),
      imageUrl: _readNullableString(data, 'imageUrl'),
      order: _readInt(data, 'order'),
      status: _readString(data, 'status', 'draft'),
    );
  }

  final String id;
  final String title;
  final String summary;
  final String category;
  final String? imageUrl;
  final int order;
  final String status;

  bool get isPublished => status == 'published';

  String get categoryLabel {
    if (category.isEmpty) return 'Facility';
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
            style: const TextStyle(
              color: FastBrand.mutedText,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({required this.department, required this.onOpen});

  final Department department;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accentColor = _departmentAccentColor(department.shortName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FastBrand.border),
            boxShadow: const [FastBrand.softShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _DepartmentImage(
                        imageUrl: department.displayImageUrl,
                        fallbackLabel: department.shortName,
                        accentColor: accentColor,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            department.shortName,
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: FastBrand.headingText,
                          height: 1.25,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        department.shortDescription,
                        style: const TextStyle(
                          fontSize: 12,
                          color: FastBrand.mutedText,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              department.hasImage ? '' : 'Awaiting image',
                              style: TextStyle(
                                color:
                                    department.hasImage
                                        ? accentColor
                                        : FastBrand.mutedText,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentImage extends StatelessWidget {
  const _DepartmentImage({
    required this.imageUrl,
    required this.fallbackLabel,
    required this.accentColor,
  });

  final String? imageUrl;
  final String fallbackLabel;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SafeRemoteImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      fallback: _imageFallback(),
    );
  }

  Widget _imageFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FastBrand.primary.withValues(alpha: 0.94),
            accentColor.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -10,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  fallbackLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.8,
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

Color _departmentAccentColor(String shortName) {
  switch (shortName.toUpperCase()) {
    case 'EEE':
      return const Color(0xFF1A73E8);
    case 'BME':
      return const Color(0xFF2D9C6A);
    case 'CVE':
      return const Color(0xFF1C7ED6);
    case 'MIE':
      return const Color(0xFFB06A12);
    case 'PEEM':
      return const Color(0xFF0D8B75);
    default:
      return FastBrand.secondary;
  }
}

class _DepartmentCodeTag extends StatelessWidget {
  const _DepartmentCodeTag({required this.label, required this.color});

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
          letterSpacing: 0.25,
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.item, required this.onOpen});

  final _ProgramExplorerItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accentColor = _departmentAccentColor(item.department.shortName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: FastBrand.mutedSurfaceDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: FastBrand.tintDecoration(
                  accentColor,
                  opacity: 0.12,
                ),
                child: Icon(Icons.school_rounded, color: accentColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DepartmentCodeTag(
                      label: item.department.shortName,
                      color: accentColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.program.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: FastBrand.headingText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.department.name,
                      style: const TextStyle(
                        color: FastBrand.supportText,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.program.safeDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FastBrand.mutedText,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: FastBrand.solidPillDecoration(
                        FastBrand.primary,
                        opacity: 0.08,
                      ),
                      child: Text(
                        item.program.durationLabel,
                        style: const TextStyle(
                          color: FastBrand.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: FastBrand.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryLikeCard extends StatelessWidget {
  const _StoryLikeCard({
    required this.title,
    required this.summary,
    required this.pillLabel,
    required this.icon,
    this.imageUrl,
  });

  final String title;
  final String summary;
  final String pillLabel;
  final IconData icon;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: FastBrand.mutedSurfaceDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (SafeRemoteImage.hasDisplayableSource(imageUrl))
            SizedBox(
              height: 170,
              width: double.infinity,
              child: SafeRemoteImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                fallback: _imageFallback(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: FastBrand.tintDecoration(FastBrand.primary),
                  child: Icon(icon, color: FastBrand.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: FastBrand.solidPillDecoration(
                          FastBrand.secondary,
                        ),
                        child: Text(
                          pillLabel,
                          style: const TextStyle(
                            color: FastBrand.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                        summary,
                        style: const TextStyle(
                          color: FastBrand.mutedText,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: FastBrand.logoSurface,
      child: const Center(
        child: Icon(Icons.image_rounded, size: 34, color: FastBrand.mutedText),
      ),
    );
  }
}

class _EmptySectionMessage extends StatelessWidget {
  const _EmptySectionMessage({required this.icon, required this.title});

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
          Icon(icon, size: 34, color: FastBrand.mutedText),
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

class _ExploreLoadingState extends StatelessWidget {
  const _ExploreLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: mustBlue));
  }
}

class _ExploreErrorState extends StatelessWidget {
  const _ExploreErrorState({required this.onRetry});

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
              'Explore FAST could not load right now.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FastBrand.headingText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again.',
              style: TextStyle(color: FastBrand.mutedText, height: 1.5),
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

bool _readBool(Map<String, dynamic> data, String key) {
  final value = data[key];
  return value is bool ? value : false;
}

int _readInt(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

DateTime _readDate(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
