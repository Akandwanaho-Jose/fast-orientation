import 'package:flutter/material.dart';
import 'package:fast/core/services/auth_service.dart';
import 'package:fast/core/services/lib/core/services/department_service.dart';
import 'package:fast/core/services/lib/core/services/program_service.dart';
import 'package:fast/core/services/lib/core/services/staff_service.dart';
import 'package:fast/core/services/lib/core/services/faculty_info_service.dart';
import 'package:fast/core/utils/constants.dart';
import 'package:fast/features/auth/screens/login_screen.dart';
import 'package:fast/features/annoucements/screens/announcements_screen.dart';
import 'package:fast/features/departments/screens/departments_screen.dart';
import 'package:fast/features/quick_links/widgets/quick_links_grid.dart';
import 'package:fast/features/staff/screens/staff_sreen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static final _logger = Logger('HomeScreen');
  
  int _selectedIndex = 0;
  bool _isLoggingOut = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  List<Widget> get _screens => [
        HomeTab(
          onExploreDepartments: _navigateToDepartments,
          fadeAnimation: _fadeAnimation,
          slideAnimation: _slideAnimation,
        ),
        const DepartmentsScreen(),
        const AnnouncementsScreen(),
        const StaffScreen(),
      ];

  void _navigateToDepartments() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _onItemTapped(int index) {
    if (index == _screens.length) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isLoggedIn) {
        _logout();
      } else {
        _openAdminLogin();
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _openAdminLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _logger.severe('Logout failed', e);
      
      if (mounted) {
        _showErrorSnackBar('Logout failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _isLoggingOut ? _buildLogoutScreen() : _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/MUST_LOGO.png', height: 32),
                const SizedBox(width: 8),
                const Text(
                  'FAST connect',
                  style: TextStyle(
                    color: mustBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildLogoutScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mustBlue.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: mustBlue,
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Signing out...',
              style: TextStyle(
                fontSize: 16,
                color: mustBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAuthenticated = authService.isLoggedIn;

    return Container(
      height: kBottomNavigationBarHeight + 15, // REDUCED height to match smaller content
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // REDUCED padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.account_balance_rounded, 'Dept', 1), // SHORTENED to prevent horizontal overflow
              _buildNavItem(Icons.campaign_rounded, 'News', 2),
              _buildNavItem(Icons.people_rounded, 'Staff', 3),
              _buildNavItem(
                isAuthenticated
                    ? Icons.logout_rounded
                    : Icons.admin_panel_settings_rounded,
                isAuthenticated ? 'Logout' : 'Admin',
                4,
                semanticsLabel:
                    isAuthenticated
                        ? 'Logout from app'
                        : 'Open admin sign in',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index, {
    String? semanticsLabel,
  }) {
    final isSelected = _selectedIndex == index;
    final isAction = index == _screens.length;
    final isLogout = label == 'Logout';
    final inactiveColor =
        isAction
            ? (isLogout ? Colors.red.shade600 : mustGreen)
            : Colors.grey.shade600;
    
    return Semantics(
      label: semanticsLabel ?? 'Navigate to $label',
      button: true,
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // REDUCED padding
          decoration: BoxDecoration(
            color: isSelected && !isAction ? mustBlue.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(3), // REDUCED padding
                decoration: BoxDecoration(
                  color: isSelected && !isAction ? mustBlue.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? mustBlue : inactiveColor,
                  size: 22, // REDUCED icon size
                ),
              ),
              const SizedBox(height: 2), // REDUCED spacing
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? mustBlue : inactiveColor,
                  fontSize: 10, // REDUCED font size
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final VoidCallback onExploreDepartments;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const HomeTab({
    super.key,
    required this.onExploreDepartments,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  static final _logger = Logger('HomeTab');
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchHomeData(
    FacultyInfoService facultyInfoService,
    DepartmentService departmentService,
    ProgramService programService,
    StaffService staffService,
  ) async {
    try {
      final facultyInfo = (await facultyInfoService.getFacultyInfo()) as Map<String, dynamic>? ?? {};
      final departments = await departmentService.getDepartments().first;
      
      final departmentCount = _safeParseInt(departments.length);

      int programCount = 0;
      for (var dept in departments) {
        try {
          final programs = await programService.getPrograms(dept.id).first;
          programCount += _safeParseInt(programs.length);
        } catch (e) {
          _logger.warning('Failed to get programs for department ${dept.id}', e);
        }
      }

      final staff = await staffService.getStaff().first;
      final staffCount = _safeParseInt(staff.length);

      return {
        'faculty_info': facultyInfo,
        'department_count': departmentCount,
        'program_count': programCount,
        'staff_count': staffCount,
      };
    } catch (e) {
      _logger.severe('Error fetching home data', e);
      return {
        'faculty_info': _getDefaultFacultyInfo(),
        'department_count': 0,
        'program_count': 0,
        'staff_count': 0,
      };
    }
  }

  int _safeParseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  Map<String, dynamic> _getDefaultFacultyInfo() {
    return {
      'dean_name': 'Dr. Dean Name',
      'dean_photo_url': '',
      'dean_message': 'Welcome to the Faculty of Applied Sciences & Technology...',
      'faculty_image_url': '',
      'faculty_vision': 'To be a leading faculty in applied sciences and technology...',
      'faculty_mission': 'To provide quality education, conduct innovative research...',
      'faculty_values': [
        'Excellence in education and research',
        'Innovation and creativity',
        'Integrity and transparency',
        'Collaboration and teamwork',
        'Sustainability and social responsibility'
      ]
    };
  }

  @override
  Widget build(BuildContext context) {
    final facultyInfoService = Provider.of<FacultyInfoService>(context, listen: false);
    final departmentService = Provider.of<DepartmentService>(context, listen: false);
    final programService = Provider.of<ProgramService>(context, listen: false);
    final staffService = Provider.of<StaffService>(context, listen: false);

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchHomeData(
        facultyInfoService,
        departmentService,
        programService,
        staffService,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final data = snapshot.data ?? _getDefaultData();
        final facultyInfo = data['faculty_info'] as Map<String, dynamic>;
        final departmentCount = data['department_count'] as int;
        final programCount = data['program_count'] as int;
        final staffCount = data['staff_count'] as int;
        const studentCount = 1500;

        return _buildHomeContent(facultyInfo, departmentCount, programCount, staffCount, studentCount);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mustBlue.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: mustBlue, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: mustBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mustBlue.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Unable to load data',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: mustBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getDefaultData() {
    return {
      'faculty_info': _getDefaultFacultyInfo(),
      'department_count': 0,
      'program_count': 0,
      'staff_count': 0,
    };
  }

  Widget _buildHomeContent(
    Map<String, dynamic> facultyInfo,
    int departmentCount,
    int programCount,
    int staffCount,
    int studentCount,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mustBlue.withOpacity(0.95),
            mustGreen.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              children: [
                _buildHeroSection(facultyInfo),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: widget.fadeAnimation,
                    child: SlideTransition(
                      position: widget.slideAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildStatsSection(departmentCount, programCount, staffCount, studentCount),
                          _buildDeanSection(facultyInfo),
                          _buildVisionMissionSection(facultyInfo),
                          _buildValuesSection(facultyInfo),
                          _buildMustPortalsSection(context),
                          SizedBox(height: MediaQuery.of(context).padding.bottom + 120), // REDUCED bottom padding to match smaller nav bar
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _readTextValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  String? _readImageUrl(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.contains('via.placeholder.com')) {
      return null;
    }

    return trimmed;
  }

  Widget _buildHeroSection(Map<String, dynamic> facultyInfo) {
    final heroImageUrl = _readImageUrl(facultyInfo, 'faculty_image_url');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        height: 390,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroBackground(heroImageUrl),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.10),
                    mustBlue.withOpacity(0.72),
                    Colors.black.withOpacity(0.88),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mustGreen.withOpacity(0.18),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -70,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.24),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Welcome to FAST',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: mustYellow.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Smart orientation hub',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Faculty of Applied Sciences\n& Technology',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mbarara University of Science and Technology',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _HeroPill(
                        icon: Icons.apartment_rounded,
                        label: 'Departments',
                      ),
                      _HeroPill(
                        icon: Icons.hub_rounded,
                        label: 'Innovation-led',
                      ),
                      _HeroPill(
                        icon: Icons.groups_rounded,
                        label: 'Student-ready',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBackground(String? imageUrl) {
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Image.asset(
              'assets/images/home/fast_building_hero.jpg',
              fit: BoxFit.cover,
            ),
      );
    }

    return Image.asset(
      'assets/images/home/fast_building_hero.jpg',
      fit: BoxFit.cover,
    );
  }

  Widget _buildStatsSection(int deptCount, int progCount, int staffCount, int studentCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mustBlue,
            mustBlue.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: mustBlue.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'FAST at a Glance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatItem('$deptCount', 'Departments', Icons.account_balance)),
                  _buildDivider(),
                  Expanded(child: _buildStatItem('$progCount', 'Programs', Icons.school)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildStatItem('$staffCount', 'Staff', Icons.people)),
                  _buildDivider(),
                  Expanded(child: _buildStatItem('$studentCount+', 'Students', Icons.groups)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label, IconData icon) {
    return Semantics(
      label: '$label: $number',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label: $number'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
              const SizedBox(height: 8),
              Text(
                number,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 60,
      color: Colors.white.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildDeanSection(Map<String, dynamic> facultyInfo) {
    final deanName = _readTextValue(
      facultyInfo,
      'dean_name',
      'Dean, FAST',
    );
    final deanMessage = _readTextValue(
      facultyInfo,
      'dean_message',
      'Welcome to our faculty. We are building a learning environment shaped by innovation, applied science, and student growth.',
    );
    final deanImageUrl = _readImageUrl(facultyInfo, 'dean_photo_url');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useRowLayout = constraints.maxWidth > 620;
            final photo = Container(
              width: useRowLayout ? 220 : double.infinity,
              height: useRowLayout ? 280 : 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: mustBlue.withOpacity(0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  deanImageUrl != null
                      ? Image.network(
                        deanImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => _DeanImageFallback(),
                      )
                      : _DeanImageFallback(),
            );

            final messagePanel = Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: mustBlue.withOpacity(0.12)),
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
                      color: mustGreen.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Dean Spotlight',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: mustGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    deanName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: mustBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dean, Faculty of Applied Sciences & Technology',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(Icons.format_quote, color: mustBlue, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Message from the Dean',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: mustBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    deanMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: mustBlue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_pin_rounded,
                        color: mustBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Leadership Welcome',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: mustBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (useRowLayout)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      photo,
                      const SizedBox(width: 20),
                      Expanded(child: messagePanel),
                    ],
                  )
                else ...[
                  photo,
                  const SizedBox(height: 18),
                  SizedBox(width: double.infinity, child: messagePanel),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVisionMissionSection(Map<String, dynamic> facultyInfo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.visibility_rounded,
                  title: 'Vision',
                  content: facultyInfo['faculty_vision'] ?? 'Faculty vision...',
                  color: mustBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.flag_rounded,
                  title: 'Mission',
                  content: facultyInfo['faculty_mission'] ?? 'Faculty mission...',
                  color: mustGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Semantics(
      label: 'Tap to read full $title',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(title),
                ],
              ),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to read more',
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValuesSection(Map<String, dynamic> facultyInfo) {
    final facultyValues = facultyInfo['faculty_values'] as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
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
                  color: const Color(0xFFFFB300).withOpacity(0.15), // University yellow
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFFFB300),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Our Values',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mustBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...facultyValues.asMap().entries.map((entry) {
            int index = entry.key;
            String value = entry.value.toString();
            final colors = [mustBlue, mustGreen, const Color(0xFFFFB300), mustBlue, mustGreen]; // Only university colors
            final color = colors[index % colors.length];
            
            return Semantics(
              label: 'Value: $value',
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Value: $value'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMustPortalsSection(BuildContext context) {
    return QuickLinksGrid(
      title: 'MUST Quick Links',
      subtitle: 'Verified student services with one shared source of truth',
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeanImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [mustBlue, mustGreen],
        ),
      ),
      child: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 52,
          ),
        ),
      ),
    );
  }
}
