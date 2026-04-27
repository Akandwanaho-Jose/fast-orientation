import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/theme/fast_brand.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/core/widgets/safe_remote_image.dart';
import 'package:fast/features/Staff/models/staff.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  static const String _allDepartmentsValue = 'all_departments';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  String _selectedFilter = 'all';
  String _selectedDepartment = _allDepartmentsValue;
  String _searchQuery = '';

  static const List<_PeopleFilter> _filters = [
    _PeopleFilter(label: 'All', value: 'all'),
    _PeopleFilter(label: 'Leadership', value: 'leadership'),
    _PeopleFilter(label: 'Key Contacts', value: 'key_contact'),
    _PeopleFilter(label: 'Staff', value: 'staff'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastBrand.shellBackground,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('staff').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: mustBlue),
            );
          }

          final bottomInset = MediaQuery.paddingOf(context).bottom;

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              color: mustBlue,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(20, 20, 20, 120 + bottomInset),
                children: [
                  _buildHeader(
                    departmentFilters: const [
                      _DepartmentFilter(
                        label: 'All Departments',
                        shortLabel: 'All',
                        value: _allDepartmentsValue,
                      ),
                    ],
                    selectedDepartment: _allDepartmentsValue,
                  ),
                  const SizedBox(height: 18),
                  _buildErrorState(),
                ],
              ),
            );
          }

          final allPeople =
              snapshot.data?.docs
                  .map((doc) => Staff.fromJson(doc.data(), doc.id))
                  .where((person) => person.isPublished)
                  .where(_matchesSearch)
                  .toList(growable: true) ??
              <Staff>[];

          allPeople.sort((a, b) {
            final scoreA = _sortScore(a);
            final scoreB = _sortScore(b);
            if (scoreA != scoreB) {
              return scoreB.compareTo(scoreA);
            }
            if (a.order != b.order) {
              return a.order.compareTo(b.order);
            }
            return a.displayName.compareTo(b.displayName);
          });

          final leadership = allPeople
              .where(
                (person) =>
                    person.isLeadership || person.isDean || person.isHod,
              )
              .toList(growable: false);
          final keyContacts = allPeople
              .where(
                (person) =>
                    person.isKeyContact &&
                    !leadership.any((leader) => leader.id == person.id),
              )
              .toList(growable: false);
          final remainingStaff = allPeople
              .where(
                (person) =>
                    !leadership.any((leader) => leader.id == person.id) &&
                    !keyContacts.any((contact) => contact.id == person.id),
              )
              .toList(growable: false);
          final departmentFilters = _departmentFiltersFor(remainingStaff);
          final effectiveSelectedDepartment =
              departmentFilters.any(
                    (department) => department.value == _selectedDepartment,
                  )
                  ? _selectedDepartment
                  : _allDepartmentsValue;
          final selectedDepartmentLabel =
              departmentFilters
                  .firstWhere(
                    (department) =>
                        department.value == effectiveSelectedDepartment,
                  )
                  .label;
          final selectedDepartmentShortLabel =
              departmentFilters
                  .firstWhere(
                    (department) =>
                        department.value == effectiveSelectedDepartment,
                  )
                  .shortLabel;
          final filteredStaff = _filterStaffByDepartment(
            remainingStaff,
            effectiveSelectedDepartment,
          );

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            color: mustBlue,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(20, 20, 20, 120 + bottomInset),
              children: [
                _buildHeader(
                  departmentFilters: departmentFilters,
                  selectedDepartment: effectiveSelectedDepartment,
                ),
                const SizedBox(height: 18),
                if (allPeople.isEmpty)
                  _buildEmptyState()
                else if (_selectedFilter != 'all') ...[
                  _SectionTitle(
                    title:
                        _selectedFilter == 'staff' &&
                                effectiveSelectedDepartment !=
                                    _allDepartmentsValue
                            ? '$selectedDepartmentShortLabel Staff'
                            : _filterHeading(_selectedFilter),
                    subtitle:
                        _selectedFilter == 'staff'
                            ? effectiveSelectedDepartment ==
                                    _allDepartmentsValue
                                ? 'Browse staff across FAST or narrow the list by department.'
                                : 'Staff profiles published under $selectedDepartmentLabel.'
                            : 'People and contacts published for this view.',
                  ),
                  if (_selectedFilter == 'staff') ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _focusStaffSearch,
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Search Staff'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FastBrand.primary,
                          side: BorderSide(
                            color: FastBrand.primary.withValues(alpha: 0.18),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ..._filteredPeople(
                    allPeople,
                    leadership,
                    keyContacts,
                    filteredStaff,
                  ).map(
                    (person) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PersonCard(
                        person: person,
                        onOpen: () => _showPersonSheet(person),
                      ),
                    ),
                  ),
                ] else ...[
                  if (leadership.isNotEmpty) ...[
                    const _SectionTitle(
                      title: 'Leadership',
                      subtitle: 'Dean and academic leaders across FAST.',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 304,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: leadership.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final person = leadership[index];
                          return SizedBox(
                            width: 280,
                            child: _LeadershipCard(
                              person: person,
                              onOpen: () => _showPersonSheet(person),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (keyContacts.isNotEmpty) ...[
                    const _SectionTitle(
                      title: 'Key Contacts',
                      subtitle:
                          'The people students most often need to reach quickly.',
                    ),
                    const SizedBox(height: 12),
                    ...keyContacts.map(
                      (person) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PersonCard(
                          person: person,
                          onOpen: () => _showPersonSheet(person),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (remainingStaff.isNotEmpty || allPeople.isNotEmpty) ...[
                    const _SectionTitle(
                      title: 'Directory',
                      subtitle: 'The wider FAST people directory.',
                    ),
                    const SizedBox(height: 12),
                    ...remainingStaff.map(
                      (person) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PersonCard(
                          person: person,
                          onOpen: () => _showPersonSheet(person),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required List<_DepartmentFilter> departmentFilters,
    required String selectedDepartment,
  }) {
    return Column(
      children: [
        _buildHeroBanner(),
        const SizedBox(height: 14),
        Container(
          decoration: FastBrand.surfaceDecoration(radius: 20),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search people, roles, departments, or emails',
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
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final selected = filter.value == _selectedFilter;

              return ChoiceChip(
                label: Text(filter.label),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = filter.value;
                    if (filter.value != 'staff') {
                      _selectedDepartment = _allDepartmentsValue;
                    }
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
        ),
        if (_selectedFilter == 'staff' && departmentFilters.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: departmentFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final department = departmentFilters[index];
                final selected = department.value == selectedDepartment;

                return ChoiceChip(
                  label: Text(
                    department.count > 0
                        ? '${department.shortLabel} (${department.count})'
                        : department.shortLabel,
                  ),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedDepartment = department.value;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: FastBrand.primary.withValues(alpha: 0.14),
                  labelStyle: TextStyle(
                    color: selected ? FastBrand.primary : FastBrand.headingText,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color:
                          selected
                              ? FastBrand.primary
                              : FastBrand.primary.withValues(alpha: 0.16),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      decoration: FastBrand.heroDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: SafeRemoteImage(
              imageUrl: 'assets/images/home/fast_building_hero.jpg',
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
          const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeroPill(label: 'People'),
                SizedBox(height: 16),
                Text(
                  'Dean, heads of department, staff, and key FAST contacts.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Explore the FAST people directory with leadership, support contacts, and staff profiles in one place.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: FastBrand.surfaceDecoration(radius: 24),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 14),
          const Text(
            'People could not load right now.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: FastBrand.headingText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your Firestore connection and try again.',
            style: TextStyle(color: FastBrand.mutedText, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: FastBrand.surfaceDecoration(radius: 24),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No people match this view yet.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: FastBrand.headingText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Published staff, leadership, and key contacts will appear here once available.',
            style: TextStyle(color: FastBrand.mutedText, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Staff> _filteredPeople(
    List<Staff> allPeople,
    List<Staff> leadership,
    List<Staff> keyContacts,
    List<Staff> staffDirectory,
  ) {
    switch (_selectedFilter) {
      case 'leadership':
        return leadership;
      case 'key_contact':
        return keyContacts;
      case 'staff':
        return staffDirectory;
      default:
        return allPeople;
    }
  }

  List<_DepartmentFilter> _departmentFiltersFor(List<Staff> people) {
    final counts = <String, int>{};
    final labels = <String, String>{};

    for (final person in people) {
      final label = person.displayDepartment;
      final key = _departmentKey(label);
      counts.update(key, (value) => value + 1, ifAbsent: () => 1);
      labels.putIfAbsent(key, () => label);
    }

    final filters = counts.entries
      .map(
        (entry) => _DepartmentFilter(
          label: labels[entry.key] ?? 'FAST',
          shortLabel: _departmentShortLabel(labels[entry.key] ?? 'FAST'),
          value: entry.key,
          count: entry.value,
        ),
      )
      .toList(growable: false)..sort((a, b) {
      final countCompare = b.count.compareTo(a.count);
      if (countCompare != 0) {
        return countCompare;
      }
      return a.label.compareTo(b.label);
    });

    return [
      const _DepartmentFilter(
        label: 'All Departments',
        shortLabel: 'All',
        value: _allDepartmentsValue,
      ),
      ...filters,
    ];
  }

  List<Staff> _filterStaffByDepartment(List<Staff> people, String department) {
    if (department == _allDepartmentsValue) {
      return people;
    }

    return people
        .where(
          (person) => _departmentKey(person.displayDepartment) == department,
        )
        .toList(growable: false);
  }

  String _departmentKey(String department) {
    return department
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  String _departmentShortLabel(String department) {
    final normalized = department.toLowerCase();

    if (normalized.contains('electrical') &&
        normalized.contains('electronics')) {
      return 'EEE';
    }
    if (normalized.contains('biomedical')) {
      return 'BME';
    }
    if (normalized.contains('civil')) {
      return 'CVE';
    }
    if (normalized.contains('mechanical') &&
        normalized.contains('industrial')) {
      return 'MIE';
    }
    if ((normalized.contains('petroleum') ||
            normalized.contains('petrolium')) &&
        (normalized.contains('environmental') ||
            normalized.contains('enviromental'))) {
      return 'PEEM';
    }

    final words = department
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) {
      return 'FAST';
    }

    final initials =
        words
            .where((word) => word.length > 2 || word == words.first)
            .map((word) => word[0].toUpperCase())
            .join();

    return initials.isEmpty
        ? department.substring(0, 1).toUpperCase()
        : initials;
  }

  Future<void> _focusStaffSearch() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted) {
      return;
    }

    _searchFocusNode.requestFocus();
  }

  bool _matchesSearch(Staff person) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final haystack =
        [
          person.displayName,
          person.displayPosition,
          person.displayDepartment,
          person.email ?? '',
          person.phone ?? '',
          person.displayRoleLabel,
        ].join(' ').toLowerCase();

    return haystack.contains(_searchQuery);
  }

  int _sortScore(Staff person) {
    if (person.isDean) {
      return 4;
    }
    if (person.isLeadership) {
      return 3;
    }
    if (person.isKeyContact) {
      return 2;
    }
    if (person.featured) {
      return 1;
    }
    return 0;
  }

  String _filterHeading(String filter) {
    switch (filter) {
      case 'leadership':
        return 'Leadership';
      case 'key_contact':
        return 'Key Contacts';
      case 'staff':
        return 'Staff';
      default:
        return 'People';
    }
  }

  void _showPersonSheet(Staff person) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          maxChildSize: 0.92,
          minChildSize: 0.48,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PersonPortrait(
                        person: person,
                        width: 92,
                        height: 116,
                        borderRadius: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: FastBrand.headingText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              person.displayPosition,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              person.displayDepartment,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _detailPill(person.displayRoleLabel, mustBlue),
                      if (person.isKeyContact)
                        _detailPill('Key Contact', mustGreen),
                      if (person.featured)
                        _detailPill('Featured', const Color(0xFFD97706)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (person.hasBio)
                    _detailBlock('About', person.bio!)
                  else
                    _detailBlock(
                      'About',
                      'This FAST profile is active and ready for a fuller biography.',
                    ),
                  const SizedBox(height: 18),
                  _infoRow(Icons.email_outlined, 'Email', person.email),
                  _infoRow(Icons.phone_outlined, 'Phone', person.phone),
                  _infoRow(Icons.place_outlined, 'Office', person.office),
                  _infoRow(Icons.link_rounded, 'LinkedIn', person.linkedinUrl),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (person.hasEmail)
                        ElevatedButton.icon(
                          onPressed:
                              () => _launchUri(
                                Uri(scheme: 'mailto', path: person.email),
                              ),
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mustBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      if (person.hasPhone)
                        OutlinedButton.icon(
                          onPressed:
                              () => _launchUri(
                                Uri(scheme: 'tel', path: person.phone),
                              ),
                          icon: const Icon(Icons.phone_outlined),
                          label: const Text('Call'),
                        ),
                      if (person.hasLinkedIn)
                        OutlinedButton.icon(
                          onPressed:
                              () => _launchUri(Uri.parse(person.linkedinUrl!)),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('LinkedIn'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _PeopleFilter {
  const _PeopleFilter({required this.label, required this.value});

  final String label;
  final String value;
}

class _DepartmentFilter {
  const _DepartmentFilter({
    required this.label,
    required this.shortLabel,
    required this.value,
    this.count = 0,
  });

  final String label;
  final String shortLabel;
  final String value;
  final int count;
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: FastBrand.glassPillDecoration(),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

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
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: FastBrand.mutedText, height: 1.5),
        ),
      ],
    );
  }
}

class _LeadershipCard extends StatelessWidget {
  const _LeadershipCard({required this.person, required this.onOpen});

  final Staff person;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [FastBrand.softShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PersonPortrait(
                person: person,
                width: double.infinity,
                height: 112,
                borderRadius: 20,
              ),
              const SizedBox(height: 12),
              _roleTag(person.displayRoleLabel, mustBlue),
              const SizedBox(height: 10),
              Text(
                person.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FastBrand.headingText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                person.displayPosition,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.3,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                person.displayDepartment,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FastBrand.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person, required this.onOpen});

  final Staff person;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [FastBrand.softShadow],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PersonPortrait(
                person: person,
                width: 86,
                height: 104,
                borderRadius: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.displayName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: FastBrand.headingText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      person.displayPosition,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      person.displayDepartment,
                      style: const TextStyle(color: FastBrand.mutedText),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _roleTag(person.displayRoleLabel, mustBlue),
                        if (person.isKeyContact)
                          _roleTag('Key Contact', mustGreen),
                      ],
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
    );
  }
}

class _PersonPortrait extends StatelessWidget {
  const _PersonPortrait({
    required this.person,
    required this.width,
    required this.height,
    this.borderRadius = 22,
  });

  final Staff person;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white,
        border: Border.all(color: FastBrand.border),
        boxShadow: [
          BoxShadow(
            color: FastBrand.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeRemoteImage(
              imageUrl: person.photoUrl,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.72),
              fallback: _PortraitFallback(name: person.displayName),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.02),
                      FastBrand.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortraitFallback extends StatelessWidget {
  const _PortraitFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            mustBlue.withValues(alpha: 0.92),
            FastBrand.primaryStrong.withValues(alpha: 0.82),
            mustGreen.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _initialsFromName(name),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

Widget _detailPill(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
    ),
  );
}

Widget _roleTag(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
    ),
  );
}

Widget _detailBlock(String title, String body) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: FastBrand.softSurface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: FastBrand.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: FastBrand.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(body, style: TextStyle(color: Colors.grey.shade700, height: 1.6)),
      ],
    ),
  );
}

Widget _infoRow(IconData icon, String label, String? value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        SizedBox(
          width: 84,
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
            value?.trim().isNotEmpty == true ? value!.trim() : 'Not provided',
            style: const TextStyle(
              color: FastBrand.headingText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

String _initialsFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) {
    return 'F';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
