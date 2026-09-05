import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/screens/profile.dart';
import 'package:stela_app/screens/login.dart';
// import 'package:stela_app/screens/MyFiles.dart';
// File names are lowercase/case-sensitive on CI; use exact filenames present in lib/screens
//import 'package:stela_app/screens/pythontutorial.dart';
//import 'package:stela_app/screens/COAtutorials.dart';
//import 'package:stela_app/screens/CCtutorials.dart';
// import 'package:stela_app/screens/AIPT_page.dart';
// import 'package:stela_app/screens/CC_page.dart';
// import 'package:stela_app/screens/COA_page.dart';
import 'package:stela_app/screens/student_dashboard.dart';
// import 'package:stela_app/screens/machine_learning_page.dart';
// import 'package:stela_app/screens/compiler_design_page.dart';
// import 'package:stela_app/screens/computer_networks_page.dart';
// import 'package:stela_app/screens/internet_of_things_page.dart';
// import 'package:stela_app/screens/c_programming_page.dart';
import 'package:stela_app/screens/faculty_dashboard.dart';
import 'package:stela_app/screens/subject_resources_page.dart';

String usermanual1 =
    "https://docs.google.com/document/d/1-55-CJP_Be6KlZgdGFk6K_j7sFQeqGulqfCrZPD2bcA/edit?usp=sharing";
String feedback =
    "https://docs.google.com/spreadsheets/d/1SOxjjg91ezT3o8LFjrQ5F0GPOmRKqdrrGuBjVyYdo5A/edit?usp=sharing";

class Subjects extends StatefulWidget {
  @override
  _SubjectsState createState() => _SubjectsState();
}

class _SubjectsState extends State<Subjects> {
  late List<Map<String, dynamic>> allSubjects = [];
  late List<Map<String, dynamic>> firestoreSubjects = [];
  String _searchQuery = '';
  String userRole = '';

  final List<IconData> _availableIcons = [
    Icons.psychology,
    Icons.cloud,
    Icons.build,
    Icons.network_check,
    Icons.computer,
    Icons.memory,
    Icons.functions,
    Icons.wifi,
    Icons.science,
    Icons.code,
    Icons.storage,
    Icons.security,
    Icons.extension,
  ];

  final List<Map<String, dynamic>> defaultSubjects = [
    // Add default subjects here if needed
  ];

  String selectedCategory = "All";
  final List<String> categories = [
    "All",
    "Core Subjects",
    "Faculty Courses",
    // "Practice",
    "Resources"
  ];

  @override
  void initState() {
    super.initState();
    allSubjects = List.from(defaultSubjects);
    _loadUserRole();
    _loadFirestoreSubjects();
  }

  Future<void> _loadUserRole() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) return;

      // Check Faculty Collection
      final facultyDoc = await FirebaseFirestore.instance
          .collection('faculty')
          .doc(currentUser.uid)
          .get();

      if (facultyDoc.exists) {
        if (!mounted) return;

        setState(() {
          userRole = 'faculty';
        });

        return;
      }

      // Default = student
      if (!mounted) return;

      setState(() {
        userRole = 'student';
      });
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  Future<void> _loadFirestoreSubjects() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        firestoreSubjects = snapshot.docs.map((doc) {
          final data = doc.data();
          final iconIndex = data['icon'] as int? ?? 0;
          return {
            'subjectId': doc.id,
            'label': data['label'] ?? 'Unnamed Subject',
            'description': data['description'] ?? '',
            'category': 'Faculty Courses',
            'icon': _availableIcons[
                iconIndex < _availableIcons.length ? iconIndex : 0],
            'color': Color(data['color'] as int? ?? 0xFF2196F3),
            'facultyName': data['facultyName'] ?? 'Faculty',
          };
        }).toList();

        allSubjects = [...defaultSubjects, ...firestoreSubjects];
      });
    } catch (e) {
      print('Error loading Firestore subjects: $e');
    }
  }

  // Navigation methods
  void _navigateToHome(String role) {
    final normalizedRole = role.toLowerCase().trim();

    if (normalizedRole == 'faculty') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FacultyDashboard(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDashboard(),
        ),
      );
    }
  }

  void _navigateToSubjects() {
    // Already on subjects page
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Profile()),
    );
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
      title: Text(
        'Subjects',
        style: TextStyle(
          color: const Color.fromARGB(255, 244, 244, 244),
          fontFamily: 'PTSerif-Bold',
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: primaryBar,
      elevation: 0,
      actions: [
        // Show hamburger menu for small screens, top nav for large screens
        if (MediaQuery.of(context).size.width > 600) ...[
          // Top navigation for larger screens
          TextButton(
            onPressed: () => _navigateToHome(
                userRole), // Pass the user role to navigate to the correct dashboard
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
                color: const Color.fromARGB(255, 194, 234, 247),
                fontFamily: 'PTSerif-Bold',
                fontWeight: FontWeight.w900,
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
                    'Learning Platform',
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
              onTap: () => _navigateToHome(userRole),
            ),
            _buildDrawerItem(
              icon: Icons.school,
              title: 'Subjects',
              onTap: _navigateToSubjects,
              isSelected: true,
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
    final query = _searchQuery.trim().toLowerCase();
    final categoryFilteredSubjects = selectedCategory == "All"
        ? allSubjects
        : allSubjects
            .where((subject) => subject['category'] == selectedCategory)
            .toList();

    final filteredSubjects = query.isEmpty
        ? categoryFilteredSubjects
        : categoryFilteredSubjects.where((subject) {
            final label = (subject['label'] ?? '').toString().toLowerCase();
            final category =
                (subject['category'] ?? '').toString().toLowerCase();
            final description =
                (subject['description'] ?? '').toString().toLowerCase();
            return label.contains(query) ||
                category.contains(query) ||
                description.contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: primaryWhite,
      appBar: _buildAppBar(),
      drawer: MediaQuery.of(context).size.width <= 600 ? _buildDrawer() : null,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryBar,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to STELA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'PTSerif-Bold',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Explore your learning modules and resources',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontFamily: 'PTSerif',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : primaryBar,
                          fontFamily: 'PTSerif',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: primaryButton,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? primaryButton.withOpacity(0.3)
                            : primaryBar.withOpacity(0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                      elevation: isSelected ? 6 : 2,
                      shadowColor: isSelected
                          ? primaryButton.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search subjects',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (query) {
                setState(() => _searchQuery = query);
              },
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive grid configuration
                int crossAxisCount;
                double childAspectRatio;

                if (constraints.maxWidth > 1200) {
                  // Desktop
                  crossAxisCount = 4;
                  childAspectRatio = 1.1;
                } else if (constraints.maxWidth > 800) {
                  // Tablet
                  crossAxisCount = 3;
                  childAspectRatio = 1.05;
                } else if (constraints.maxWidth > 600) {
                  // Large mobile
                  crossAxisCount = 2;
                  childAspectRatio = 1.0;
                } else {
                  // Small mobile
                  crossAxisCount = 1;
                  childAspectRatio = 1.8;
                }

                return Padding(
                  padding: EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: filteredSubjects.length,
                    itemBuilder: (context, index) {
                      final item = filteredSubjects[index];
                      return _buildSubjectCard(context, item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Only show bottom navigation for small screens when drawer is not available
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? BottomNavigationBar(
              backgroundColor: primaryBar,
              selectedItemColor: primaryWhite,
              unselectedItemColor: primaryWhite.withOpacity(0.7),
              currentIndex: 0,
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
                    _navigateToHome(userRole);
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
    );
  }

  Widget _buildSubjectCard(BuildContext context, Map<String, dynamic> item) {
    return InkWell(
      onTap: () async {
        // if (item.containsKey('widget')) {
        //   Navigator.push(
        //       context, MaterialPageRoute(builder: (_) => item['widget']));
        // }
        if (item.containsKey('subjectId')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubjectResourcesPage(
                subjectId: item['subjectId'],
                subjectName: item['label'],
              ),
            ),
          );
        } else if (item.containsKey('widget')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => item['widget'],
            ),
          );
        } else if (item.containsKey('url')) {
          final Uri uri = Uri.parse(item['url']);
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Could not launch ${item['url']}'),
                backgroundColor: Colors.red,
              ));
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error launching link: $e'),
              backgroundColor: Colors.red,
            ));
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: item['color'].withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 0),
            ),
          ],
          border: Border.all(
            color: item['color'].withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item['color'].withOpacity(0.08),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: item['color'],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          item['icon'],
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item['category'],
                          style: TextStyle(
                            color: item['color'],
                            fontSize: 9,
                            fontFamily: 'PTSerif',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    item['label'],
                    style: TextStyle(
                      color: primaryBar,
                      fontSize: 13,
                      fontFamily: 'PTSerif-Bold',
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['description'],
                      style: TextStyle(
                        color: primaryBar.withOpacity(0.6),
                        fontSize: 11,
                        fontFamily: 'PTSerif',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.containsKey('facultyName'))
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'by ${item['facultyName']}',
                          style: TextStyle(
                            color: primaryButton,
                            fontSize: 10,
                            fontFamily: 'PTSerif',
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryButton.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.containsKey('url')
                                ? 'External Link'
                                : 'Open Module',
                            style: TextStyle(
                              color: primaryButton,
                              fontSize: 9,
                              fontFamily: 'PTSerif',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            item.containsKey('url')
                                ? Icons.open_in_new
                                : Icons.arrow_forward,
                            color: primaryButton,
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
