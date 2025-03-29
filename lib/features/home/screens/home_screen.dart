import 'package:flutter/material.dart';
import 'package:fast/features/departments/screens/departments_screen.dart';
import 'package:fast/features/courses/screens/courses_screen.dart';
import 'package:fast/features/faculty/screens/faculty_screen.dart';
import 'package:fast/features/annoucements/screens/announcements_screen.dart';
import 'package:fast/features/faq/screens/faq_screen.dart';
import 'package:fast/features/chatbot/screens/chatbot_screen.dart';
import 'package:fast/core/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // List of screens for bottom navigation
  static const List<Widget> _screens = [
    HomeContent(),
    DepartmentsScreen(),
    CoursesScreen(),
    FacultyScreen(),
    AnnouncementsScreen(),
    FaqScreen(),
    ChatbotScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/MUST_LOGO.png', height: 40),
            const SizedBox(width: 10),
            const Text(
              'MUST FAST Orientation',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: mustBlue,
        centerTitle: true,
      ),
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: mustBlue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Departments',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Lecturers'),
          BottomNavigationBarItem(
            icon: Icon(Icons.announcement),
            label: 'Announcements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_answer),
            label: 'FAQ',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE3F2FD), // Light Blue gradient
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message
              const Text(
                'Welcome to FAST at MUST!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: mustBlue,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We are excited to welcome you to the Faculty of Applied Sciences and Technology (FAST). This app is your guide to navigating your academic journey and discovering opportunities at MUST.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 24),

              // Dean's Welcome Message
              const Text(
                'Message from the Dean',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: mustGreen,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/johnes.jpg', // Replace with your dean's image
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'I am delighted to welcome you to the Faculty of Applied Sciences and Technology (FAST) at Mbarara University of Science and Technology (MUST). FAST is a hub of innovation, research, and academic excellence. With a dedicated team of faculty and state-of-the-art facilities, we are committed to providing you with a transformative educational experience. Explore our programs, engage with our community, and embark on a journey of discovery with us.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Faculty Overview
              const Text(
                'About the Faculty',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: mustGreen,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFacultyImage('assets/images/kih.jpg'),
                    _buildFacultyImage('assets/images/st.jpg'),
                    _buildFacultyImage('assets/images/st2.jpg'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The Faculty of Applied Sciences and Technology (FAST) is committed to providing high-quality education and research in various fields of applied sciences and technology. We offer a range of undergraduate programs designed to equip students with the knowledge and skills needed to succeed in their chosen careers.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 24),

              // Explore Departments Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DepartmentsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mustBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Explore Departments',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build faculty images with error handling
  Widget _buildFacultyImage(String imagePath) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: SizedBox(
        width: 150,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
          ),
        ),
      ),
    );
  }
}
