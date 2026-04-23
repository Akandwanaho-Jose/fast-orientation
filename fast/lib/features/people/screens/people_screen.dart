import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/core/widgets/safe_network_avatar.dart';
import 'package:fast/features/Staff/models/staff.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance.collection('staff').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: mustBlue),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState();
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
                          !keyContacts.any(
                            (contact) => contact.id == person.id,
                          ),
                    )
                    .toList(growable: false);

                if (allPeople.isEmpty) {
                  return _buildEmptyState();
                }

                if (_selectedFilter != 'all') {
                  final filtered = _filteredPeople(
                    allPeople,
                    leadership,
                    keyContacts,
                    remainingStaff,
                  );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                    children: [
                      _SectionTitle(
                        title: _filterHeading(_selectedFilter),
                        subtitle:
                            'People and contacts published for this view.',
                      ),
                      const SizedBox(height: 12),
                      ...filtered.map(
                        (person) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PersonCard(
                            person: person,
                            onOpen: () => _showPersonSheet(person),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  children: [
                    if (leadership.isNotEmpty) ...[
                      const _SectionTitle(
                        title: 'Leadership',
                        subtitle: 'Dean and academic leaders across FAST.',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 198,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: leadership.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [mustBlue, Color(0xFF0B58B4), Color(0xFF1D8557)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'People',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Dean, heads of department, staff, and key FAST contacts.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This view is now driven from the unified people structure in Firestore.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search people, roles, departments, or emails',
                prefixIcon: const Icon(Icons.search_rounded, color: mustBlue),
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
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: mustBlue,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : mustBlue,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color:
                          selected
                              ? Colors.transparent
                              : mustBlue.withOpacity(0.18),
                    ),
                  ),
                );
              },
            ),
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
              'People could not load right now.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF152033),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your Firestore connection and try again.',
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                color: Color(0xFF152033),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Published staff, leadership, and key contacts will appear here once available.',
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Staff> _filteredPeople(
    List<Staff> allPeople,
    List<Staff> leadership,
    List<Staff> keyContacts,
    List<Staff> remainingStaff,
  ) {
    switch (_selectedFilter) {
      case 'leadership':
        return leadership;
      case 'key_contact':
        return keyContacts;
      case 'staff':
        return remainingStaff;
      default:
        return allPeople;
    }
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
                    children: [
                      _PersonAvatar(person: person, radius: 34),
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
                                color: Color(0xFF152033),
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
            color: mustBlue,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, height: 1.5),
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [mustBlue, Color(0xFF0B58B4), Color(0xFF1D8557)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PersonAvatar(
                person: person,
                radius: 30,
                borderColor: Colors.white,
              ),
              const Spacer(),
              Text(
                person.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                person.displayPosition,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  height: 1.4,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PersonAvatar(person: person, radius: 28),
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
                        color: Color(0xFF152033),
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
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _tag(person.displayRoleLabel, mustBlue),
                        if (person.isKeyContact) _tag('Key Contact', mustGreen),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: mustBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({
    required this.person,
    required this.radius,
    this.borderColor,
  });

  final Staff person;
  final double radius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            borderColor == null
                ? null
                : Border.all(color: borderColor!, width: 2),
        gradient: LinearGradient(
          colors: [mustBlue.withOpacity(0.92), mustGreen.withOpacity(0.84)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeNetworkAvatar(
        radius: radius,
        imageUrl: person.photoUrl,
        backgroundColor: Colors.white,
        fallbackIconColor: Colors.grey.shade500,
        fallbackIconSize: radius,
      ),
    );
  }
}

Widget _detailPill(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
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
      color: const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE2E8F2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: mustBlue, fontWeight: FontWeight.w800),
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
              color: Color(0xFF152033),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
