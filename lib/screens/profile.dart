import 'package:flutter/material.dart';
import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/constants/userDetails.dart';
import 'package:stela_app/screens/contactUs.dart';
import 'package:stela_app/screens/subjects.dart';
import 'package:stela_app/screens/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stela_app/utils/role_guard.dart';
import 'package:stela_app/screens/student_dashboard.dart';
import 'package:stela_app/screens/faculty_dashboard.dart'; //fixing the navigation issue by importing the correct dashboard screens- harshita

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isLoading = true;
  bool hasError = false;
  bool isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _enrollmentController;
  late TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    // initialize controllers to avoid null/dispose issues
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _enrollmentController = TextEditingController();
    _contactController = TextEditingController();
    fetchUserDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _enrollmentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> fetchUserDetails() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // Fetch user details from Firestore
      await getDetails();
      // populate controllers with fetched values
      _nameController.text = name;
      _emailController.text = email;
      _enrollmentController.text = enrollmentNo;
      _contactController.text = contactNum;
      print("✅ User details fetched successfully");
    } catch (e) {
      print("❌ Error fetching user details: $e");
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    final updates = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'contactNumber': _contactController.text.trim(),
    };
    if (userRole.toLowerCase() == 'student') {
      updates['enrollmentNumber'] = _enrollmentController.text.trim();
    }

    setState(() {
      isLoading = true;
    });
    try {
      await updateDetails(updates);
      // Refresh local values
      await fetchUserDetails();
      setState(() {
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _cancelEditing() {
    // Reset controllers to current values
    _nameController.text = name;
    _emailController.text = email;
    _enrollmentController.text = enrollmentNo;
    _contactController.text = contactNum;
    setState(() {
      isEditing = false;
    });
  }

  // Navigation methods
  void _navigateToHome(String role) async {
    // Always resolve current role from Firestore to avoid stale cached values.
    try {
      final current = await RoleGuard.getUserRole();
      final useRole = (current ?? role) ?? 'Student';
      if (useRole.toLowerCase() == 'faculty') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => FacultyDashboard()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => StudentDashboard()));
      }
    } catch (e) {
      // Fallback: use provided role parameter
      if (role.toLowerCase() == 'faculty') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => FacultyDashboard()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => StudentDashboard()));
      }
    }
  }

  void _navigateToSubjects() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Subjects()),
    );
  }

  void _navigateToProfile() {
    // Already on profile page
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
      title: const Text(
        'Profile',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'PTSerif-Bold',
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: primaryBar,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      actions: [
        // Show hamburger menu for small screens, top nav for large screens
        if (MediaQuery.of(context).size.width > 600) ...[
          // Top navigation for larger screens
          TextButton(
            onPressed: () => _navigateToHome(userRole),
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
                color: const Color.fromARGB(255, 194, 234, 247),
                fontFamily: 'PTSerif-Bold',
                fontWeight: FontWeight.w900,
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
              onTap: () => _navigateToSubjects(),
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: _navigateToProfile,
              isSelected: true,
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
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryButton),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading profile...',
                    style: TextStyle(
                      color: primaryBar,
                      fontSize: 16,
                      fontFamily: 'PTSerif',
                    ),
                  ),
                ],
              ),
            )
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load profile',
                        style: TextStyle(
                          color: primaryBar,
                          fontSize: 18,
                          fontFamily: 'PTSerif-Bold',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please try again later',
                        style: TextStyle(
                          color: primaryBar.withOpacity(0.7),
                          fontSize: 14,
                          fontFamily: 'PTSerif',
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: fetchUserDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryButton,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'PTSerif-Bold',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(
                          constraints.maxWidth > 600 ? 32.0 : 20.0,
                        ),
                        child: Column(
                          children: [
                            // Profile Header
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: primaryBar,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryBar.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: primaryButton,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryButton.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  // Editable name field when in edit mode
                                  isEditing
                                      ? TextField(
                                          controller: _nameController,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontFamily: 'PTSerif-Bold',
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: 'Student Name',
                                            hintStyle: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          name.isNotEmpty
                                              ? name
                                              : 'Student Name',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontFamily: 'PTSerif-Bold',
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                  SizedBox(height: 8),
                                  Text(
                                    userRole.isNotEmpty
                                        ? userRole.toUpperCase()
                                        : 'STUDENT',
                                    style: TextStyle(
                                      color: primaryButton,
                                      fontSize: 14,
                                      fontFamily: 'PTSerif-Bold',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),

                            // Student Details Card
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'User Information',
                                        style: TextStyle(
                                          color: primaryBar,
                                          fontSize: 20,
                                          fontFamily: 'PTSerif-Bold',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      isEditing
                                          ? Row(
                                              children: [
                                                TextButton(
                                                  onPressed: _cancelEditing,
                                                  child: Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: _saveChanges,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        primaryButton,
                                                  ),
                                                  child: Text('Save'),
                                                ),
                                              ],
                                            )
                                          : TextButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  isEditing = true;
                                                });
                                              },
                                              icon: Icon(Icons.edit, size: 18),
                                              label: Text('Edit'),
                                            ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  buildDetailRow('Name',
                                      name.isNotEmpty ? name : 'Not available'),
                                  buildDetailRow(
                                      'Email',
                                      email.isNotEmpty
                                          ? email
                                          : 'Not available'),
                                  // Only show enrollment number for students
                                  if (userRole.toLowerCase() == 'student')
                                    buildDetailRow(
                                        'Enrollment Number',
                                        enrollmentNo.isNotEmpty
                                            ? enrollmentNo
                                            : 'Not available'),
                                  buildDetailRow(
                                      'Contact Number',
                                      contactNum.isNotEmpty
                                          ? contactNum
                                          : 'Not available'),
                                  buildDetailRow(
                                      'Role',
                                      userRole.isNotEmpty
                                          ? userRole.toUpperCase()
                                          : 'STUDENT'),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),

                            // Contact Us Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ContactUs()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryButton,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.contact_support,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Contact Us',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'PTSerif-Bold',
                                        fontWeight: FontWeight.bold,
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
                  },
                ),
      // Only show bottom navigation for small screens when drawer is not available
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? BottomNavigationBar(
              backgroundColor: primaryBar,
              selectedItemColor: primaryWhite,
              unselectedItemColor: primaryWhite.withOpacity(0.7),
              currentIndex: 2, // Profile is selected
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

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: primaryBar.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'PTSerif',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: isEditing &&
                    (label == 'Name' ||
                        label == 'Email' ||
                        label == 'Enrollment Number' ||
                        label == 'Contact Number')
                ? TextField(
                    controller: label == 'Name'
                        ? _nameController
                        : label == 'Email'
                            ? _emailController
                            : label == 'Enrollment Number'
                                ? _enrollmentController
                                : _contactController,
                    style: TextStyle(
                      color: primaryBar,
                      fontSize: 14,
                      fontFamily: 'PTSerif',
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: primaryBar.withOpacity(0.2)),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      color: primaryBar,
                      fontSize: 14,
                      fontFamily: 'PTSerif',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
