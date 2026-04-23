import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/admin/widgets/admin_shared.dart';
import 'package:flutter/material.dart';

class AdminOverviewSection extends StatelessWidget {
  const AdminOverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OverviewStats>(
      future: _loadStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoadingState();
        }

        if (snapshot.hasError) {
          return const AdminErrorState(
            message: 'The admin overview could not load Firestore counts.',
          );
        }

        final stats = snapshot.data ?? const _OverviewStats();

        return AdminSectionFrame(
          title: 'Overview',
          subtitle:
              'A quick snapshot of the FAST content platform and what your team can manage from here.',
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width >= 1100 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.45,
                    children: [
                      AdminStatCard(
                        label: 'Departments',
                        value: '${stats.departments}',
                        icon: Icons.account_balance_rounded,
                        color: mustBlue,
                      ),
                      AdminStatCard(
                        label: 'Published People',
                        value: '${stats.people}',
                        icon: Icons.people_alt_rounded,
                        color: mustGreen,
                      ),
                      AdminStatCard(
                        label: 'Updates',
                        value: '${stats.announcements}',
                        icon: Icons.campaign_rounded,
                        color: const Color(0xFFEF6C00),
                      ),
                      AdminStatCard(
                        label: 'Stories',
                        value: '${stats.stories}',
                        icon: Icons.auto_stories_rounded,
                        color: const Color(0xFF7B61FF),
                      ),
                      AdminStatCard(
                        label: 'Orientation Items',
                        value: '${stats.orientationItems}',
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF00897B),
                      ),
                      AdminStatCard(
                        label: 'Support Resources',
                        value: '${stats.supportResources}',
                        icon: Icons.support_agent_rounded,
                        color: const Color(0xFFD97706),
                      ),
                      AdminStatCard(
                        label: 'Quick Links',
                        value: '${stats.quickLinks}',
                        icon: Icons.link_rounded,
                        color: const Color(0xFF3949AB),
                      ),
                      AdminStatCard(
                        label: 'Pinned Updates',
                        value: '${stats.pinnedAnnouncements}',
                        icon: Icons.push_pin_rounded,
                        color: const Color(0xFFE53935),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              const AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Flow',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF152033),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Update the faculty profile so the Home and More tabs reflect current branding.',
                      style: TextStyle(height: 1.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '2. Use Updates and People to keep announcements and contacts current.',
                      style: TextStyle(height: 1.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '3. Use Content Hub for featured stories, orientation resources, support links, and quick links overrides.',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_OverviewStats> _loadStats() async {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore.collection('departments').count().get(),
      firestore
          .collection('staff')
          .where('status', isEqualTo: 'published')
          .count()
          .get(),
      firestore.collection('announcements').count().get(),
      firestore.collection('featured_stories').count().get(),
      firestore.collection('orientation_content').count().get(),
      firestore.collection('support_resources').count().get(),
      firestore.collection('quick_links').count().get(),
      firestore
          .collection('announcements')
          .where('isPinned', isEqualTo: true)
          .count()
          .get(),
    ]);

    return _OverviewStats(
      departments: results[0].count ?? 0,
      people: results[1].count ?? 0,
      announcements: results[2].count ?? 0,
      stories: results[3].count ?? 0,
      orientationItems: results[4].count ?? 0,
      supportResources: results[5].count ?? 0,
      quickLinks: results[6].count ?? 0,
      pinnedAnnouncements: results[7].count ?? 0,
    );
  }
}

class _OverviewStats {
  const _OverviewStats({
    this.departments = 0,
    this.people = 0,
    this.announcements = 0,
    this.stories = 0,
    this.orientationItems = 0,
    this.supportResources = 0,
    this.quickLinks = 0,
    this.pinnedAnnouncements = 0,
  });

  final int departments;
  final int people;
  final int announcements;
  final int stories;
  final int orientationItems;
  final int supportResources;
  final int quickLinks;
  final int pinnedAnnouncements;
}
