import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/features/departments/models/program.dart';
import 'package:fast/features/departments/models/course.dart';
import 'package:fast/features/departments/screens/course_details_screen.dart';
import 'package:fast/core/utils/constants.dart';

class ProgramDetailsScreen extends StatefulWidget {
  final String departmentId;
  final Program program;
  final String programDocId;

  const ProgramDetailsScreen({
    super.key,
    required this.departmentId,
    required this.program,
    required this.programDocId,
  });

  @override
  State<ProgramDetailsScreen> createState() => _ProgramDetailsScreenState();
}

class _ProgramDetailsScreenState extends State<ProgramDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _searchQuery = '';
  int _selectedYear = 0; // 0 means all years
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildProgramHeader(),
            _buildSearchAndFilter(),
            Expanded(child: _buildCoursesSection()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.program.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: mustBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildProgramHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: mustGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school,
              color: mustGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.program.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: mustGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.program.durationYears} years',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
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

  Widget _buildSearchAndFilter() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isSearching ? 120 : 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (_isSearching) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  prefixIcon: Icon(Icons.search, color: mustBlue),
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Year filter chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5, // All + 4 years
              itemBuilder: (context, index) {
                final isSelected = _selectedYear == index;
                final label = index == 0 ? 'All Years' : 'Year $index';
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : mustBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: mustBlue,
                    onSelected: (selected) {
                      setState(() {
                        _selectedYear = selected ? index : 0;
                      });
                    },
                    elevation: 2,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('departments')
          .doc(widget.departmentId)
          .collection('programs')
          .doc(widget.programDocId)
          .collection('yearCourses')
          .orderBy('year')
          .snapshots(),
      builder: (context, yearSnapshot) {
        if (yearSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }
        if (yearSnapshot.hasError) {
          return _buildErrorWidget();
        }
        if (!yearSnapshot.hasData || yearSnapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final yearCoursesList = yearSnapshot.data!.docs.map((doc) {
          return YearCourses.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();

        final yearCoursesMap = {
          for (var yc in yearCoursesList) yc.year: yc,
        };

        final filteredYears = <Widget>[];
        for (int year = 1; year <= 4; year++) {
          if (_selectedYear != 0 && _selectedYear != year) continue;
          
          final yearCourses = yearCoursesMap[year] ?? YearCourses(year: year, courses: []);
          final uniqueCourses = <String, Course>{};
          for (var course in yearCourses.courses) {
            uniqueCourses[course.code] = course;
          }
          
          var courses = uniqueCourses.values.toList();
          if (_searchQuery.isNotEmpty) {
            courses = courses.where((course) {
              return course.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                     course.code.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
          }
          
          filteredYears.add(_buildYearSection(year, courses));
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: filteredYears,
        );
      },
    );
  }

  Widget _buildYearSection(int year, List<Course> courses) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          initiallyExpanded: _selectedYear == year,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mustBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: mustBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Year $year',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: mustBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: mustGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${courses.length} courses',
                  style: TextStyle(
                    color: mustGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          children: courses.isEmpty
              ? [_buildEmptyCoursesWidget()]
              : courses.map((course) => _buildCourseCard(course)).toList(),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mustGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.book,
              color: mustGreen,
              size: 24,
            ),
          ),
          title: Text(
            course.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Course Code: ${course.code}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${course.credits} credits',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: mustBlue,
            size: 18,
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailsScreen(course: course),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCoursesWidget() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'No courses match your search'
                : 'No courses available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No courses available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Courses will appear here once added',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(mustBlue),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading courses...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading courses',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// YearCourses model class
class YearCourses {
  final int year;
  final List<Course> courses;

  YearCourses({
    required this.year,
    required this.courses,
  });

  factory YearCourses.fromJson(Map<String, dynamic> json) {
    return YearCourses(
      year: json['year'] ?? 0,
      courses: (json['courses'] as List<dynamic>?)
          ?.map((courseJson) => Course.fromJson(courseJson as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}