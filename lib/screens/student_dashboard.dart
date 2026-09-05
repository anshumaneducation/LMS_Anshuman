import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/constants/userDetails.dart';
import 'package:stela_app/screens/login.dart';
import 'package:stela_app/screens/subjects.dart';
import 'package:stela_app/screens/profile.dart';
import 'package:stela_app/screens/SubmitAssignmentPage.dart';
import 'package:stela_app/screens/quizzes.dart';
import 'package:stela_app/screens/announcements_page.dart';
import 'package:stela_app/screens/feedback_page.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final List<Map<String, dynamic>> features = [
    {
      "title": "View Subjects",
      "icon": Icons.book_outlined,
      "route": Subjects(),
      "desc": "Browse all your subjects"
    },
    {
      "title": "Assignments",
      "icon": Icons.assignment,
      "route": SubmitAssignmentPage(),
      "desc": "View and submit assignments"
    },
    {
      "title": "Quizzes",
      "icon": Icons.quiz,
      "route": QuizzesScreen(),
      "desc": "Test your knowledge"
    },
    {
      "title": "Announcements",
      "icon": Icons.announcement,
      "route": AnnouncementsPage(),
      "desc": "Latest updates"
    },
    {
      "title": "Submit Feedback to faculty",
      "icon": Icons.feedback,
      "route": FeedbackPage(),
      "desc": "Share your thoughts"
    },
    {
      "title": "User Guide",
      "icon": Icons.menu_book_outlined,
      "desc": "Learn how to use the application",
      "onTap": () async {
        final url =
            'https://firebasestorage.googleapis.com/v0/b/mstela-infoanshumantech.firebasestorage.app/o/manuals%2Fstudent%20manual.pdf?alt=media&token=2c6cd747-41b0-41a6-ad2b-1e16e702409e';
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      },
    },
  ];

  // Navigation methods
  void _navigateToHome() {
    // Already on StudentDashboard, do nothing
  }

  void _navigateToSubjects() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Subjects()),
    );
  }

  void _navigateToProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Profile()),
    );
  }

  Future<void> _openGoogleForm() async {
    const String formUrl =
        'https://docs.google.com/forms/d/e/1FAIpQLSe4S0tVb06rrhOYuMaBdAfJaH0UtUslYvfTQcWw67feXAOeLw/viewform';

    final Uri url = Uri.parse(formUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the form'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Login()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build responsive app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.school, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "STELA",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'PTSerif-Bold',
            ),
          ),
        ],
      ),
      backgroundColor: primaryBar,
      elevation: 0,
      actions: [
        // Show hamburger menu for small screens, top nav for large screens
        if (MediaQuery.of(context).size.width > 600) ...[
          // Top navigation for larger screens
          TextButton(
            onPressed: _navigateToHome,
            child: Text(
              'Home',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'PTSerif',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _navigateToSubjects,
            child: Text(
              'Subjects',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'PTSerif',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _navigateToProfile,
            child: Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'PTSerif',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ] else ...[
          // Hamburger menu for small screens
          IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ],
      ],
    );
  }

  // Build drawer for small screens
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: primaryWhite,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: primaryBar,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryBar, primaryButton],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'STELA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'PTSerif-Bold',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Student Dashboard',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontFamily: 'PTSerif',
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: _navigateToHome,
            ),
            _buildDrawerItem(
              icon: Icons.school,
              title: 'Subjects',
              onTap: _navigateToSubjects,
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: _navigateToProfile,
            ),
            Divider(color: primaryBar.withOpacity(0.2)),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryButton : primaryBar,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryButton : primaryBar,
          fontFamily: 'PTSerif',
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      onTap: onTap,
      tileColor: isSelected ? primaryButton.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryWhite,
      appBar: _buildAppBar(),
      drawer: MediaQuery.of(context).size.width <= 600 ? _buildDrawer() : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryButton.withOpacity(0.18), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBar.withOpacity(0.08),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: primaryButton,
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome, $name!",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: primaryBar,
                              fontFamily: 'PTSerif-Bold',
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Explore your dashboard and get started!",
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryBar.withOpacity(0.7),
                              fontFamily: 'PTSerif',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Feature grid with background image
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Background image with low opacity
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.07,
                          child: Image.asset(
                            "assets/images/book_background.jpg",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Scrollable feature grid
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth > 600 ? 16 : 12,
                          vertical: 6,
                        ),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                _getCrossAxisCount(constraints.maxWidth),
                            crossAxisSpacing:
                                constraints.maxWidth > 600 ? 20 : 18,
                            mainAxisSpacing:
                                constraints.maxWidth > 600 ? 20 : 18,
                            childAspectRatio:
                                _getChildAspectRatio(constraints.maxWidth),
                          ),
                          itemCount: features.length,
                          itemBuilder: (context, index) {
                            final feature = features[index];
                            return _FeatureCard(feature: feature);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Only show bottom navigation for small screens when drawer is not available
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? BottomNavigationBar(
              backgroundColor: primaryBar,
              selectedItemColor: primaryWhite,
              unselectedItemColor: primaryWhite.withOpacity(0.7),
              currentIndex: 1, // Dashboard is selected
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.school),
                  label: 'Subjects',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle),
                  label: 'Profile',
                ),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    _navigateToHome();
                    break;
                  case 1:
                    _navigateToSubjects();
                    break;
                  case 2:
                    _navigateToProfile();
                    break;
                }
              },
            )
          : null,
      floatingActionButton: FloatingActionButton.small(
        onPressed: _openGoogleForm,
        backgroundColor: primaryButton,
        tooltip: 'Send feedback about application',
        child: const Icon(
          Icons.feedback_outlined,
          color: Colors.white,
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Responsive grid configuration methods
  int _getCrossAxisCount(double width) {
    if (width > 1200) return 4; // Desktop
    if (width > 800) return 3; // Tablet
    if (width > 600) return 2; // Large mobile
    return 1; // Small mobile
  }

  double _getChildAspectRatio(double width) {
    if (width > 1200) return 3.2; // Desktop
    if (width > 800) return 3.0; // Tablet
    if (width > 600) return 2.8; // Large mobile
    return 2.5; // Small mobile
  }
}

class _FeatureCard extends StatelessWidget {
  final Map<String, dynamic> feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (feature['onTap'] != null) {
          feature['onTap']();
        } else if (feature['route'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => feature['route'] as Widget,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryButton.withOpacity(0.13), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryBar.withOpacity(0.07),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(color: primaryButton.withOpacity(0.18), width: 1),
        ),
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryButton,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(feature['icon'], color: Colors.white, size: 28),
            ),
            SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBar,
                      fontFamily: 'PTSerif-Bold',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    feature['desc'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: primaryBar.withOpacity(0.7),
                      fontFamily: 'PTSerif',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: primaryButton),
          ],
        ),
      ),
    );
  }
}
