import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/admin/widgets/content_hub_section.dart';
import 'package:fast/features/admin/widgets/departments_section.dart';
import 'package:fast/features/admin/widgets/faculty_profile_section.dart';
import 'package:fast/features/admin/widgets/overview_section.dart';
import 'package:fast/features/admin/widgets/people_section.dart';
import 'package:fast/features/admin/widgets/programs_section.dart';
import 'package:fast/features/admin/widgets/updates_section.dart';
import 'package:fast/features/auth/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final _destinations = const <_AdminDestination>[
    _AdminDestination(
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      screen: AdminOverviewSection(),
    ),
    _AdminDestination(
      label: 'Faculty',
      icon: Icons.account_balance_outlined,
      selectedIcon: Icons.account_balance_rounded,
      screen: FacultyProfileSection(),
    ),
    _AdminDestination(
      label: 'Departments',
      icon: Icons.apartment_outlined,
      selectedIcon: Icons.apartment_rounded,
      screen: DepartmentsAdminSection(),
    ),
    _AdminDestination(
      label: 'Programs',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school_rounded,
      screen: ProgramsAdminSection(),
    ),
    _AdminDestination(
      label: 'Updates',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign_rounded,
      screen: UpdatesAdminSection(),
    ),
    _AdminDestination(
      label: 'People',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      screen: PeopleAdminSection(),
    ),
    _AdminDestination(
      label: 'Content Hub',
      icon: Icons.widgets_outlined,
      selectedIcon: Icons.widgets_rounded,
      screen: ContentHubSection(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FB),
          appBar: _buildAppBar(),
          drawer: wide ? null : _buildDrawer(),
          body:
              wide
                  ? Row(
                    children: [
                      _buildRail(),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: _destinations
                              .map((d) => d.screen)
                              .toList(growable: false),
                        ),
                      ),
                    ],
                  )
                  : IndexedStack(
                    index: _selectedIndex,
                    children: _destinations
                        .map((d) => d.screen)
                        .toList(growable: false),
                  ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
              color: const Color(0xFFF0F5FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: mustBlue,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FAST Admin',
                style: TextStyle(
                  color: mustBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _destinations[_selectedIndex].label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: const [],
    );
  }

  Widget _buildRail() {
    return Container(
      width: 270,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [mustBlue, Color(0xFF0B58B4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage the wider FAST platform from one place.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              extended: true,
              labelType: NavigationRailLabelType.none,
              backgroundColor: Colors.white,
              destinations: _destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      color: mustBlue,
                      size: 30,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'FAST Admin',
                      style: TextStyle(
                        color: mustBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Choose a workspace section.',
                      style: TextStyle(color: Color(0xFF617089)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final destination = _destinations[index];
                  final selected = _selectedIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      selected: selected,
                      selectedColor: mustBlue,
                      selectedTileColor: const Color(0xFFEAF1FB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: Icon(
                        selected ? destination.selectedIcon : destination.icon,
                      ),
                      title: Text(
                        destination.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      // FIX: removed `const` — HomeScreen cannot be a compile-time constant
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(adminOnly: true),
      ),
      (route) => false,
    );
  }
}

class _AdminDestination {
  const _AdminDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}
