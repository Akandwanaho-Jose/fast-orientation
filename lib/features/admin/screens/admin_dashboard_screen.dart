import 'dart:io';

import 'package:fast/core/models/quick_link.dart';
import 'package:fast/core/services/lib/core/services/announcement_service.dart';
import 'package:fast/core/services/lib/core/services/department_service.dart';
import 'package:fast/core/services/lib/core/services/staff_service.dart';
import 'package:fast/core/services/quick_links_service.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/annoucements/models/announcement.dart';
import 'package:fast/features/departments/models/department.dart';
import 'package:fast/features/home/screens/home_screen.dart';
import 'package:fast/features/staff/models/staff.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AnnouncementService _announcementService = AnnouncementService();
  final QuickLinksService _quickLinksService = QuickLinksService();
  final DepartmentService _departmentService = DepartmentService();
  final StaffService _staffService = StaffService();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[400]),
            const SizedBox(width: 12),
            const Text('Confirm Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout from the admin dashboard?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<List<Announcement>>(
          stream: _announcementService.getAnnouncements(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error);
            }

            final announcements = snapshot.data ?? const <Announcement>[];
            return _buildDashboardContent(announcements);
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: mustBlue,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings, size: 24),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Manage Announcements',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(List<Announcement> announcements) {
    final filteredAnnouncements = _getFilteredAnnouncements(announcements);

    return Column(
      children: [
        _buildHeader(
          announcements: announcements,
          filteredCount: filteredAnnouncements.length,
        ),
        _buildManagementModules(),
        _buildFilterBar(
          totalCount: announcements.length,
          filteredCount: filteredAnnouncements.length,
        ),
        Expanded(
          child:
              announcements.isEmpty
                  ? _buildEmptyState()
                  : filteredAnnouncements.isEmpty
                  ? _buildNoResultsState()
                  : _buildAnnouncementsList(filteredAnnouncements),
        ),
      ],
    );
  }

  Widget _buildHeader({
    required List<Announcement> announcements,
    required int filteredCount,
  }) {
    final totalCount = announcements.length;
    final pinnedCount = announcements.where((a) => a.isPinned).length;
    final urgentCount = announcements.where((a) => a.isUrgent).length;
    final totalViews = announcements.fold<int>(
      0,
      (sum, announcement) => sum + announcement.views,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [mustBlue, mustBlue.withOpacity(0.92)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: mustBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search announcements, categories, or tags...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: mustBlue),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            totalCount == 0
                ? 'Ready for your first announcement'
                : 'Showing $filteredCount of $totalCount announcements',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Search, sort, pin, and update priority without leaving this screen.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = constraints.maxWidth >= 880 ? 4 : 2;
              final cardWidth =
                  (constraints.maxWidth - ((columnCount - 1) * 12)) /
                  columnCount;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      title: 'Announcements',
                      value: totalCount.toString(),
                      helper: 'Total published posts',
                      icon: Icons.campaign_rounded,
                      accent: Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      title: 'Pinned',
                      value: pinnedCount.toString(),
                      helper: 'Featured at the top',
                      icon: Icons.push_pin_rounded,
                      accent: const Color(0xFFFFB74D),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      title: 'Urgent',
                      value: urgentCount.toString(),
                      helper: 'High-attention posts',
                      icon: Icons.priority_high_rounded,
                      accent: const Color(0xFFEF5350),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      title: 'Views',
                      value: totalViews.toString(),
                      helper: 'Combined engagement',
                      icon: Icons.visibility_rounded,
                      accent: const Color(0xFF80CBC4),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManagementModules() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Areas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Open dedicated managers for quick links, departments, and staff.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 152,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildManagerTile(
                  title: 'Quick Links',
                  subtitle: 'Edit MUST portal links and Firestore overrides',
                  icon: Icons.link_rounded,
                  accent: mustBlue,
                  countBuilder:
                      () => StreamBuilder<List<QuickLink>>(
                        stream: _quickLinksService.watchAdminQuickLinks(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? 0;
                          return Text(
                            '$count links',
                            style: TextStyle(
                              color: mustBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                  onTap: _showQuickLinksManager,
                ),
                _buildManagerTile(
                  title: 'Departments',
                  subtitle: 'Create, edit, and remove academic departments',
                  icon: Icons.account_balance_rounded,
                  accent: mustGreen,
                  countBuilder:
                      () => StreamBuilder<List<Department>>(
                        stream: _departmentService.getDepartments(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? 0;
                          return Text(
                            '$count departments',
                            style: TextStyle(
                              color: mustGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                  onTap: _showDepartmentsManager,
                ),
                _buildManagerTile(
                  title: 'Staff',
                  subtitle: 'Manage staff profiles, contacts, and photos',
                  icon: Icons.groups_rounded,
                  accent: const Color(0xFFEF6C00),
                  countBuilder:
                      () => StreamBuilder<List<Staff>>(
                        stream: _staffService.getStaff(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? 0;
                          return Text(
                            '$count profiles',
                            style: const TextStyle(
                              color: Color(0xFFEF6C00),
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                  onTap: _showStaffManager,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Widget Function() countBuilder,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 232,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent.withOpacity(0.16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    countBuilder(),
                    const Spacer(),
                    Icon(Icons.arrow_forward_rounded, color: accent, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String helper,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar({
    required int totalCount,
    required int filteredCount,
  }) {
    const filters = ['All', 'Pinned', 'Urgent', 'Important', 'Normal'];
    const sortOptions = [
      'Newest',
      'Oldest',
      'Most Viewed',
      'Title A-Z',
      'Priority',
    ];
    final hasActiveControls =
        _searchQuery.isNotEmpty ||
        _selectedFilter != 'All' ||
        _selectedSort != 'Newest';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  totalCount == 0
                      ? 'No announcements yet'
                      : '$filteredCount result${filteredCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (hasActiveControls)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = _selectedFilter == filter;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : mustBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: mustBlue,
                    checkmarkColor: Colors.white,
                    elevation: isSelected ? 2 : 0,
                    pressElevation: 4,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = selected ? filter : 'All';
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? mustBlue : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 560;
              final sortField = Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    isExpanded: true,
                    icon: const Icon(Icons.unfold_more_rounded),
                    items:
                        sortOptions
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedSort = value;
                      });
                    },
                  ),
                ),
              );
              final createButton = OutlinedButton.icon(
                onPressed: () => _showAnnouncementDialog(),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('New Announcement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: mustBlue,
                  side: BorderSide(color: mustBlue.withOpacity(0.35)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sortField,
                    const SizedBox(height: 12),
                    createButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: sortField),
                  const SizedBox(width: 12),
                  createButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: mustBlue),
          SizedBox(height: 16),
          Text(
            'Loading announcements...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $error',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: mustBlue,
                foregroundColor: Colors.white,
              ),
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
            Icon(Icons.campaign_outlined, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 18),
            const Text(
              'No announcements yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Publish your first update to start managing campus communications.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _showAnnouncementDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Announcement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: mustBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No announcements match your filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search, filter, or sort combination.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: mustBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedFilter = 'All';
      _selectedSort = 'Newest';
    });
  }

  List<Announcement> _getFilteredAnnouncements(
    List<Announcement> announcements,
  ) {
    final query = _searchQuery.trim();

    final filtered =
        announcements.where((announcement) {
          final matchesSearch =
              query.isEmpty ||
              announcement.title.toLowerCase().contains(query) ||
              announcement.description.toLowerCase().contains(query) ||
              (announcement.category?.toLowerCase().contains(query) ?? false) ||
              announcement.tags.any(
                (tag) => tag.toLowerCase().contains(query),
              );

          bool matchesFilter = true;
          switch (_selectedFilter) {
            case 'Pinned':
              matchesFilter = announcement.isPinned;
              break;
            case 'Urgent':
              matchesFilter = announcement.isUrgent;
              break;
            case 'Important':
              matchesFilter = announcement.isImportant;
              break;
            case 'Normal':
              matchesFilter = announcement.priority == 'normal';
              break;
            default:
              matchesFilter = true;
          }

          return matchesSearch && matchesFilter;
        }).toList();

    switch (_selectedSort) {
      case 'Oldest':
        filtered.sort((a, b) => a.postedAt.compareTo(b.postedAt));
        break;
      case 'Most Viewed':
        filtered.sort((a, b) {
          final viewComparison = b.views.compareTo(a.views);
          if (viewComparison != 0) {
            return viewComparison;
          }
          return b.postedAt.compareTo(a.postedAt);
        });
        break;
      case 'Title A-Z':
        filtered.sort(
          (a, b) =>
              a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case 'Priority':
        filtered.sort((a, b) {
          final priorityComparison = _priorityRank(
            a.priority,
          ).compareTo(_priorityRank(b.priority));
          if (priorityComparison != 0) {
            return priorityComparison;
          }
          return b.postedAt.compareTo(a.postedAt);
        });
        break;
      case 'Newest':
      default:
        filtered.sort((a, b) => b.postedAt.compareTo(a.postedAt));
        break;
    }

    return filtered;
  }

  Widget _buildAnnouncementsList(List<Announcement> announcements) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final announcement = announcements[index];
        return _buildAnnouncementCard(announcement);
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final priorityColor = _priorityColor(announcement.priority);
    final hasCategory =
        announcement.category != null && announcement.category!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: priorityColor.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showAnnouncementDetails(announcement),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            priorityColor.withOpacity(0.18),
                            priorityColor.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child:
                          announcement.hasImages
                              ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      announcement.mainImageUrl,
                                      width: 68,
                                      height: 68,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.grey[400],
                                          ),
                                    ),
                                  ),
                                  if (announcement.imageUrls.length > 1)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '+${announcement.imageUrls.length - 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              )
                              : Icon(
                                _priorityIcon(announcement.priority),
                                color: priorityColor,
                                size: 32,
                              ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildBadge(
                                _priorityLabel(
                                  announcement.priority,
                                ).toUpperCase(),
                                priorityColor,
                                _priorityIcon(announcement.priority),
                              ),
                              if (announcement.isPinned)
                                _buildBadge(
                                  'PINNED',
                                  const Color(0xFFFF9800),
                                  Icons.push_pin_rounded,
                                ),
                              if (hasCategory)
                                _buildBadge(
                                  announcement.category!,
                                  mustBlue,
                                  Icons.category_rounded,
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            announcement.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showAnnouncementDialog(announcement: announcement);
                            break;
                          case 'delete':
                            _confirmDelete(announcement);
                            break;
                          case 'pin':
                            _togglePin(announcement);
                            break;
                          case 'priority_normal':
                            _updatePriority(announcement, 'normal');
                            break;
                          case 'priority_important':
                            _updatePriority(announcement, 'important');
                            break;
                          case 'priority_urgent':
                            _updatePriority(announcement, 'urgent');
                            break;
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'pin',
                              child: Row(
                                children: [
                                  Icon(
                                    announcement.isPinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    size: 20,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(announcement.isPinned ? 'Unpin' : 'Pin'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'priority_normal',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 20,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Set Normal'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'priority_important',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 20,
                                    color: mustBlue,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Set Important'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'priority_urgent',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.priority_high_rounded,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Set Urgent'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.more_vert, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMetaPill(
                      icon: Icons.schedule_rounded,
                      label: _formatDate(announcement.postedAt),
                    ),
                    _buildMetaPill(
                      icon: Icons.visibility_outlined,
                      label: '${announcement.views} views',
                    ),
                    if (announcement.hasImages)
                      _buildMetaPill(
                        icon: Icons.photo_library_outlined,
                        label:
                            '${announcement.imageUrls.length} image${announcement.imageUrls.length == 1 ? '' : 's'}',
                      ),
                    if (announcement.tags.isNotEmpty)
                      _buildMetaPill(
                        icon: Icons.sell_outlined,
                        label:
                            '${announcement.tags.length} tag${announcement.tags.length == 1 ? '' : 's'}',
                      ),
                  ],
                ),
                if (announcement.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...announcement.tags
                          .take(4)
                          .map((tag) => _buildTagChip(tag))
                          .toList(),
                      if (announcement.tags.length > 4)
                        _buildTagChip(
                          '+${announcement.tags.length - 4} more',
                          muted: true,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            () => _showAnnouncementDialog(
                              announcement: announcement,
                            ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: mustBlue,
                          side: BorderSide(color: mustBlue.withOpacity(0.25)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _togglePin(announcement),
                        icon: Icon(
                          announcement.isPinned
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                        ),
                        label: Text(announcement.isPinned ? 'Unpin' : 'Pin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              announcement.isPinned
                                  ? const Color(0xFFFFF3E0)
                                  : priorityColor.withOpacity(0.12),
                          foregroundColor:
                              announcement.isPinned
                                  ? const Color(0xFFEF6C00)
                                  : priorityColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label, {bool muted = false}) {
    final background =
        muted ? Colors.grey.withOpacity(0.12) : mustBlue.withOpacity(0.08);
    final foreground = muted ? Colors.grey[700]! : mustBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInlineLoading(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: mustBlue),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineError(String title, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red[400]),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineEmpty(
    String title,
    String subtitle, {
    required VoidCallback onPressed,
    required String buttonLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: mustBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview({
    required String? imageUrl,
    required IconData fallbackIcon,
    required Color accent,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          width: 68,
          height: 68,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(fallbackIcon, color: accent),
              ),
        ),
      );
    }

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(fallbackIcon, color: accent),
    );
  }

  Widget _buildPickerRow({
    required String label,
    required String? currentUrl,
    required XFile? file,
    required Future<void> Function() onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                onPick();
              },
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Choose Image'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file != null
                    ? file.name
                    : ((currentUrl ?? '').isNotEmpty ? 'Current image kept' : 'No image selected'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showActionSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showActionError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _normalizeUrl(String value) {
    if (value.contains('://')) {
      return value;
    }
    return 'https://$value';
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showAnnouncementDialog(),
      backgroundColor: mustBlue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('New Announcement'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  void _showManagerSheet({
    required String title,
    required String subtitle,
    required Widget child,
    VoidCallback? onAdd,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.92;
        return Container(
          height: maxHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onAdd != null)
                      ElevatedButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mustBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  void _showQuickLinksManager() {
    _showManagerSheet(
      title: 'Quick Links',
      subtitle: 'Manage the key MUST links shown across the app.',
      child: StreamBuilder<List<QuickLink>>(
        stream: _quickLinksService.watchAdminQuickLinks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildInlineLoading('Loading quick links...');
          }

          if (snapshot.hasError) {
            return _buildInlineError(
              'Unable to load quick links.',
              snapshot.error,
            );
          }

          final links = snapshot.data ?? const <QuickLink>[];
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: links.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final link = links[index];
              final defaultLink = QuickLinksService.defaultLinkById(link.id);
              final isModified =
                  defaultLink != null &&
                  (defaultLink.title != link.title ||
                      defaultLink.subtitle != link.subtitle ||
                      defaultLink.url != link.url ||
                      defaultLink.order != link.order ||
                      defaultLink.enabled != link.enabled);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: mustBlue.withOpacity(0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: link.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(link.icon, color: link.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                link.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                link.subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: link.enabled,
                          onChanged:
                              (value) => _updateQuickLinkVisibility(link, value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMetaPill(
                          icon: Icons.link_rounded,
                          label: 'Order ${link.order}',
                        ),
                        _buildMetaPill(
                          icon: link.enabled
                              ? Icons.check_circle_outline
                              : Icons.hide_source_outlined,
                          label: link.enabled ? 'Visible' : 'Hidden',
                        ),
                        if (isModified)
                          _buildMetaPill(
                            icon: Icons.tune_rounded,
                            label: 'Override active',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      link.url,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showQuickLinkDialog(link),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(width: 10),
                        TextButton.icon(
                          onPressed:
                              isModified
                                  ? () => _resetQuickLinkOverride(
                                    link.id,
                                    closeDialog: false,
                                  )
                                  : null,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateQuickLinkVisibility(QuickLink link, bool enabled) async {
    try {
      await _quickLinksService.saveQuickLinkOverride(
        link.copyWith(enabled: enabled),
      );
      _showActionSuccess(
        enabled ? '${link.title} is now visible' : '${link.title} is now hidden',
      );
    } catch (e) {
      _showActionError('Failed to update quick link visibility: $e');
    }
  }

  void _showQuickLinkDialog(QuickLink link) {
    final titleController = TextEditingController(text: link.title);
    final subtitleController = TextEditingController(text: link.subtitle);
    final urlController = TextEditingController(text: link.url);
    final orderController = TextEditingController(text: link.order.toString());
    var enabled = link.enabled;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Quick Link'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: subtitleController,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlController,
                        decoration: const InputDecoration(labelText: 'URL'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: orderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Order'),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: enabled,
                        onChanged: (value) {
                          setState(() {
                            enabled = value;
                          });
                        },
                        title: const Text('Visible in app'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await _resetQuickLinkOverride(link.id, closeDialog: false);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final order = int.tryParse(orderController.text.trim());
                    if (titleController.text.trim().isEmpty ||
                        subtitleController.text.trim().isEmpty ||
                        urlController.text.trim().isEmpty ||
                        order == null) {
                      _showActionError(
                        'Please enter a title, subtitle, valid URL, and numeric order.',
                      );
                      return;
                    }

                    try {
                      await _quickLinksService.saveQuickLinkOverride(
                        link.copyWith(
                          title: titleController.text.trim(),
                          subtitle: subtitleController.text.trim(),
                          url: _normalizeUrl(urlController.text.trim()),
                          order: order,
                          enabled: enabled,
                        ),
                      );
                      if (mounted) {
                        Navigator.pop(context);
                      }
                      _showActionSuccess('Quick link updated');
                    } catch (e) {
                      _showActionError('Failed to update quick link: $e');
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _resetQuickLinkOverride(
    String id, {
    bool closeDialog = false,
  }) async {
    try {
      await _quickLinksService.deleteQuickLinkOverride(id);
      if (closeDialog && mounted) {
        Navigator.pop(context);
      }
      _showActionSuccess('Quick link reset to default');
    } catch (e) {
      _showActionError('Failed to reset quick link: $e');
    }
  }

  void _showDepartmentsManager() {
    _showManagerSheet(
      title: 'Departments',
      subtitle: 'Create, update, and remove department profiles.',
      onAdd: () => _showDepartmentDialog(),
      child: StreamBuilder<List<Department>>(
        stream: _departmentService.getDepartments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildInlineLoading('Loading departments...');
          }

          if (snapshot.hasError) {
            return _buildInlineError(
              'Unable to load departments.',
              snapshot.error,
            );
          }

          final departments = snapshot.data ?? const <Department>[];
          if (departments.isEmpty) {
            return _buildInlineEmpty(
              'No departments yet',
              'Add the first department to start building the faculty structure.',
              onPressed: _showDepartmentDialog,
              buttonLabel: 'Add Department',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: departments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final department = departments[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: mustGreen.withOpacity(0.14)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePreview(
                      imageUrl: department.imageUrl,
                      fallbackIcon: Icons.account_balance_rounded,
                      accent: mustGreen,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            department.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            department.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (department.hasImage)
                                _buildMetaPill(
                                  icon: Icons.image_outlined,
                                  label: 'Department image',
                                ),
                              if (department.hasHeadInfo)
                                _buildMetaPill(
                                  icon: Icons.record_voice_over_outlined,
                                  label: 'Head message',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          onPressed: () => _showDepartmentDialog(department: department),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => _confirmDepartmentDelete(department),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDepartmentDialog({Department? department}) {
    final isEditing = department != null;
    final nameController = TextEditingController(text: department?.name ?? '');
    final descriptionController = TextEditingController(
      text: department?.description ?? '',
    );
    final headMessageController = TextEditingController(
      text: department?.headMessage ?? '',
    );
    XFile? imageFile;
    XFile? headImageFile;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Department' : 'New Department'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Department name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: headMessageController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Head message',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPickerRow(
                        label: 'Department image',
                        currentUrl: department?.imageUrl,
                        file: imageFile,
                        onPick: () async {
                          final file = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (file != null) {
                            setState(() {
                              imageFile = file;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildPickerRow(
                        label: 'Head image',
                        currentUrl: department?.headImageUrl,
                        file: headImageFile,
                        onPick: () async {
                          final file = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (file != null) {
                            setState(() {
                              headImageFile = file;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        descriptionController.text.trim().isEmpty) {
                      _showActionError(
                        'Department name and description are required.',
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                              const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      if (isEditing) {
                        await _departmentService.updateDepartment(
                          id: department.id,
                          name: nameController.text.trim(),
                          description: descriptionController.text.trim(),
                          currentImageUrl: department.imageUrl,
                          currentHeadImageUrl: department.headImageUrl,
                          headMessage: headMessageController.text.trim(),
                          newImageFile: imageFile,
                          newHeadImageFile: headImageFile,
                        );
                      } else {
                        await _departmentService.createDepartment(
                          name: nameController.text.trim(),
                          description: descriptionController.text.trim(),
                          imageFile: imageFile,
                          headImageFile: headImageFile,
                          headMessage: headMessageController.text.trim(),
                        );
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                      _showActionSuccess(
                        isEditing
                            ? 'Department updated successfully'
                            : 'Department created successfully',
                      );
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context);
                      }
                      _showActionError('Failed to save department: $e');
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDepartmentDelete(Department department) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Department'),
          content: Text(
            'Delete "${department.name}" and its uploaded images? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _departmentService.deleteDepartment(
                    department.id,
                    department.imageUrl,
                    department.headImageUrl,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                  }
                  _showActionSuccess('Department deleted');
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                  _showActionError('Failed to delete department: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showStaffManager() {
    _showManagerSheet(
      title: 'Staff Profiles',
      subtitle: 'Create, update, and remove staff directory entries.',
      onAdd: () => _showStaffDialog(),
      child: StreamBuilder<List<Staff>>(
        stream: _staffService.getStaff(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildInlineLoading('Loading staff...');
          }

          if (snapshot.hasError) {
            return _buildInlineError('Unable to load staff.', snapshot.error);
          }

          final staffMembers = snapshot.data ?? const <Staff>[];
          if (staffMembers.isEmpty) {
            return _buildInlineEmpty(
              'No staff profiles yet',
              'Add staff records so the directory appears complete to visitors.',
              onPressed: _showStaffDialog,
              buttonLabel: 'Add Staff',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: staffMembers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final staff = staffMembers[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEF6C00).withOpacity(0.16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePreview(
                      imageUrl: staff.photoUrl,
                      fallbackIcon: Icons.person_outline_rounded,
                      accent: const Color(0xFFEF6C00),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.name ?? 'Unnamed Staff',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            staff.position ?? 'No position set',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if ((staff.department ?? '').isNotEmpty)
                                _buildMetaPill(
                                  icon: Icons.apartment_rounded,
                                  label: staff.department!,
                                ),
                              if ((staff.email ?? '').isNotEmpty)
                                _buildMetaPill(
                                  icon: Icons.email_outlined,
                                  label: 'Email set',
                                ),
                              if ((staff.linkedinUrl ?? '').isNotEmpty)
                                _buildMetaPill(
                                  icon: Icons.link_outlined,
                                  label: 'LinkedIn set',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          onPressed: () => _showStaffDialog(staff: staff),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => _confirmStaffDelete(staff),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showStaffDialog({Staff? staff}) {
    final isEditing = staff != null;
    final nameController = TextEditingController(text: staff?.name ?? '');
    final positionController = TextEditingController(text: staff?.position ?? '');
    final emailController = TextEditingController(text: staff?.email ?? '');
    final linkedinController = TextEditingController(
      text: staff?.linkedinUrl ?? '',
    );
    final departmentController = TextEditingController(
      text: staff?.department ?? '',
    );
    XFile? imageFile;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Staff Profile' : 'New Staff Profile'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: positionController,
                        decoration: const InputDecoration(labelText: 'Position'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: departmentController,
                        decoration: const InputDecoration(labelText: 'Department'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: linkedinController,
                        decoration: const InputDecoration(
                          labelText: 'LinkedIn URL',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPickerRow(
                        label: 'Profile photo',
                        currentUrl: staff?.photoUrl,
                        file: imageFile,
                        onPick: () async {
                          final file = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (file != null) {
                            setState(() {
                              imageFile = file;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        positionController.text.trim().isEmpty) {
                      _showActionError('Name and position are required.');
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                              const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      if (isEditing) {
                        await _staffService.updateStaff(
                          id: staff.id,
                          name: nameController.text.trim(),
                          position: positionController.text.trim(),
                          email: emailController.text.trim(),
                          linkedinUrl: linkedinController.text.trim(),
                          department: departmentController.text.trim(),
                          currentPhotoUrl: staff.photoUrl,
                          newImageFile: imageFile,
                        );
                      } else {
                        await _staffService.createStaff(
                          name: nameController.text.trim(),
                          position: positionController.text.trim(),
                          email: emailController.text.trim(),
                          linkedinUrl: linkedinController.text.trim(),
                          department: departmentController.text.trim(),
                          imageFile: imageFile,
                        );
                      }

                      if (mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                      _showActionSuccess(
                        isEditing
                            ? 'Staff profile updated successfully'
                            : 'Staff profile created successfully',
                      );
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context);
                      }
                      _showActionError('Failed to save staff profile: $e');
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmStaffDelete(Staff staff) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Staff Profile'),
          content: Text(
            'Delete "${staff.name ?? 'this staff member'}" from the directory?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _staffService.deleteStaff(staff.id, staff.photoUrl);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                  _showActionSuccess('Staff profile deleted');
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                  _showActionError('Failed to delete staff profile: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAnnouncementDetails(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(announcement.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (announcement.hasImages) ...[
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: announcement.imageUrls.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          announcement.imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                announcement.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (announcement.tags.isNotEmpty) ...[
                const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: announcement.tags.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.grey[200],
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAnnouncementDialog(announcement: announcement);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog({Announcement? announcement}) {
    final isEditing = announcement != null;
    final titleController = TextEditingController(text: announcement?.title ?? '');
    final descriptionController = TextEditingController(text: announcement?.description ?? '');
    final categoryController = TextEditingController(text: announcement?.category ?? '');
    
    List<XFile> selectedImages = [];
    String selectedPriority = announcement?.priority ?? 'normal';
    bool isPinned = announcement?.isPinned ?? false;
    List<String> tags = List.from(announcement?.tags ?? []);
    final tagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add,
                    color: mustBlue,
                  ),
                  const SizedBox(width: 12),
                  Text(isEditing ? 'Edit Announcement' : 'New Announcement'),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Field
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description Field
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Category Field
                      DropdownButtonFormField<String>(
                        value: categoryController.text.isEmpty ? null : categoryController.text,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                          DropdownMenuItem(value: 'Events', child: Text('Events')),
                          DropdownMenuItem(value: 'Deadlines', child: Text('Deadlines')),
                          DropdownMenuItem(value: 'General', child: Text('General')),
                        ],
                        onChanged: (value) {
                          categoryController.text = value ?? '';
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Priority and Pin Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.priority_high, size: 20),
                                const SizedBox(width: 8),
                                const Text('Priority:'),
                                const SizedBox(width: 12),
                                DropdownButton<String>(
                                  value: selectedPriority,
                                  items: const [
                                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                                    DropdownMenuItem(value: 'important', child: Text('Important')),
                                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedPriority = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: isPinned,
                                  onChanged: (value) {
                                    setState(() {
                                      isPinned = value!;
                                    });
                                  },
                                ),
                                const Icon(Icons.push_pin, size: 20),
                                const SizedBox(width: 8),
                                const Text('Pin to top'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Image Selection
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Images', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            
                            // Current Images (for editing)
                            if (isEditing && announcement!.imageUrls.isNotEmpty) ...[
                              const Text('Current Images:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: announcement.imageUrls.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          announcement.imageUrls[index],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.error),
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // New Image Selection
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final images = await picker.pickMultiImage();
                                    if (images.isNotEmpty) {
                                      setState(() {
                                        selectedImages = images;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.add_photo_alternate),
                                  label: Text(isEditing ? 'Replace Images' : 'Add Images'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: mustBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${selectedImages.length} selected'),
                              ],
                            ),
                            
                            // Preview Selected Images
                            if (selectedImages.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text('New Images:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              File(selectedImages[index].path),
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedImages.removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tags Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: tagController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter a tag',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    onFieldSubmitted: (value) {
                                      if (value.isNotEmpty && !tags.contains(value)) {
                                        setState(() {
                                          tags.add(value);
                                          tagController.clear();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    if (tagController.text.isNotEmpty && !tags.contains(tagController.text)) {
                                      setState(() {
                                        tags.add(tagController.text);
                                        tagController.clear();
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (tags.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: tags.map((tag) {
                                  return Chip(
                                    label: Text(tag),
                                    backgroundColor: mustBlue.withOpacity(0.1),
                                    labelStyle: TextStyle(color: mustBlue),
                                    onDeleted: () {
                                      setState(() {
                                        tags.remove(tag);
                                      });
                                    },
                                    deleteIcon: Icon(Icons.close, size: 16, color: mustBlue),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                    
                    try {
                      if (isEditing) {
                        await _announcementService.updateAnnouncement(
                          id: announcement.id,
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          category: categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
                          currentImageUrls: announcement.imageUrls,
                          newImageFiles: selectedImages.isNotEmpty ? selectedImages : null,
                          priority: selectedPriority,
                          isPinned: isPinned,
                          tags: tags,
                        );
                      } else {
                        await _announcementService.createAnnouncement(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          category: categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
                          imageFiles: selectedImages.isNotEmpty ? selectedImages : null,
                          priority: selectedPriority,
                          isPinned: isPinned,
                          tags: tags,
                        );
                      }
                      
                      // Close loading dialog
                      Navigator.pop(context);
                      // Close form dialog
                      Navigator.pop(context);
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Announcement updated successfully!' : 'Announcement created successfully!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      
                      // Add haptic feedback
                      HapticFeedback.lightImpact();
                      
                    } catch (e) {
                      // Close loading dialog
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mustBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[400]),
            const SizedBox(width: 12),
            const Text('Delete Announcement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this announcement?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                announcement.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _announcementService.deleteAnnouncement(
                  announcement.id,
                  announcement.imageUrls,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Announcement deleted successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                HapticFeedback.heavyImpact();
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting announcement: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePin(Announcement announcement) async {
    try {
      await _announcementService.togglePinStatus(announcement.id, !announcement.isPinned);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(announcement.isPinned ? 'Announcement unpinned' : 'Announcement pinned'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      HapticFeedback.lightImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _updatePriority(
    Announcement announcement,
    String priority,
  ) async {
    if (announcement.priority == priority) {
      return;
    }

    try {
      await _announcementService.updatePriority(announcement.id, priority);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Priority updated to ${_priorityLabel(priority).toLowerCase()}',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      HapticFeedback.selectionClick();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating priority: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int _priorityRank(String priority) {
    switch (priority) {
      case 'urgent':
        return 0;
      case 'important':
        return 1;
      case 'normal':
      default:
        return 2;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFE53935);
      case 'important':
        return mustBlue;
      case 'normal':
      default:
        return mustGreen;
    }
  }

  IconData _priorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.priority_high_rounded;
      case 'important':
        return Icons.star_rounded;
      case 'normal':
      default:
        return Icons.check_circle_rounded;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'urgent':
        return 'Urgent';
      case 'important':
        return 'Important';
      case 'normal':
      default:
        return 'Normal';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
