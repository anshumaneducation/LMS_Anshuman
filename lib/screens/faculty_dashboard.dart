import 'package:flutter/material.dart';
import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/screens/faculty_dynamic_subject_picker.dart';
import 'package:stela_app/screens/faculty_upload_resource.dart';
import 'package:stela_app/screens/faculty_delete_resources.dart';
import 'package:stela_app/screens/faculty_subject_manage.dart';
import 'package:stela_app/screens/faculty_quiz_portal.dart';
import 'package:stela_app/screens/faculty_assignment_manage.dart';
import 'package:stela_app/screens/faculty_submissions_manage.dart';
import 'faculty_assignments_list_page.dart';
import 'package:stela_app/screens/faculty_assignment_submissions_manage.dart';
import 'package:stela_app/screens/faculty_announcements_manage.dart';
// import 'package:stela_app/screens/faculty_progress_manage.dart';
import 'package:stela_app/screens/faculty_feedback_manage.dart';
// import 'package:stela_app/screens/faculty_lab_practicals_manage.dart';
import 'package:stela_app/screens/faculty_manage_subjects.dart';
import 'package:stela_app/screens/subjects.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stela_app/screens/home.dart';
import 'package:stela_app/screens/profile.dart';
import 'package:url_launcher/url_launcher.dart';

// Import your upload, assignment, quiz, etc. pages here

class FacultyDashboard extends StatefulWidget {
  @override
  _FacultyDashboardState createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  final List<Map<String, dynamic>> features = [
    {
      "title": "Manage Subjects",
      "icon": Icons.add_box,
      "route": FacultyManageSubjects(),
      "desc": "Create, add, or remove subjects"
    },
    {
      "title": "View Subjects",
      "icon": Icons.book_outlined,
      "route": Subjects(),
      "desc": "Browse all your subjects"
    },
    {
      "title": "Upload Resource",
      "icon": Icons.upload_file,
      "route": Builder(
        builder: (context) => FacultyDynamicSubjectPicker(
          onSubjectTap: (subject) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FacultyUploadResource(subject: subject),
              ),
            );
          },
          title: "Select Subject to Upload Resource",
        ),
      ),
      "desc": "Upload PDFs, links, or videos"
    },
    {
      "title": "Delete Resource",
      "icon": Icons.delete,
      "route": Builder(
        builder: (context) => FacultyDynamicSubjectPicker(
          onSubjectTap: (subject) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FacultyDeleteResourcesPage(subject: subject),
              ),
            );
          },
          title: "Select Subject to Delete Resource",
        ),
      ),
      "desc": "Delete subject resources and assessments"
    },
    {
      "title": "Create Assignment",
      "icon": Icons.assignment,
      "route": Builder(
        builder: (context) => FacultyDynamicSubjectPicker(
          onSubjectTap: (subject) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FacultyAssignmentManage(subject: subject),
              ),
            );
          },
          title: "Select Subject to Create Assignment",
        ),
      ),
      "desc": "Add new assignments"
    },
    {
      "title": "Create Quiz",
      "icon": Icons.quiz,
      "route": Builder(
        builder: (context) => FacultyDynamicSubjectPicker(
          onSubjectTap: (subject) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FacultyQuizPortal(subject: subject),
              ),
            );
          },
          title: "Select Subject to Create Quiz",
        ),
      ),
      "desc": "Add quizzes for students"
    },
    {
      "title": "View Submissions",
      "icon": Icons.assignment_turned_in,
      "route": Builder(
        builder: (context) => FacultyDynamicSubjectPicker(
          onSubjectTap: (subject) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FacultySubmissionsManage(subject: subject),
              ),
            );
          },
          title: "Select Subject to View Submissions",
        ),
      ),
      "desc": "See student submissions"
    },
    {
      "title": "Assignment Submissions",
      "icon": Icons.assignment_return,
      "route": Builder(
        builder: (context) => FacultyDynamicSubjectPicker(
          onSubjectTap: (subject) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FacultyAssignmentsListPage(
                  subject: subject,
                ),
              ),
            );
          },
          title: "Select Subject to View Assignment Submissions",
        ),
      ),
      "desc": "See submitted assignments"
    },
    {
      "title": "Announcements",
      "icon": Icons.announcement,
      "route": FacultyAnnouncementsManage(),
      "desc": "Post updates for students"
    },
    {
      "title": "View Students Feedback",
      "icon": Icons.feedback,
      "route": FacultyFeedbackManage(),
      "desc": "View student feedback and queries"
    },
    {
      "title": "User Guide",
      "icon": Icons.menu_book_outlined,
      "desc": "Learn how to use the application",
      "onTap": () async {
        final url =
            'https://firebasestorage.googleapis.com/v0/b/mstela-infoanshumantech.firebasestorage.app/o/manuals%2Ffaculty%20manual.pdf?alt=media&token=1eb2d25b-a345-4918-b5a2-ec2aea96b3a6';
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      },
    },
  ];

  // Example color palette for cards
  final List<Color> cardColors = [
    Color(0xFFe3f2fd),
    Color(0xFFfce4ec),
    Color(0xFFe8f5e9),
    Color(0xFFfff3e0),
    Color(0xFFede7f6),
    Color(0xFFf3e5f5),
    Color(0xFFf9fbe7),
    Color(0xFFe0f2f1),
    Color(0xFFfbe9e7),
  ];

  void _navigateToProfile() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Profile()),
    );
  }

  void _logout() {
    // Sign out and navigate to landing page
    FirebaseAuth.instance.signOut().then((_) async {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('userRole');
      } catch (e) {
        // ignore prefs errors
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => Home()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.school, color: primaryBar),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "Faculty Dashboard",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primaryBar,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'PTSerif-Bold',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.person, color: primaryBar),
            label: Text(
              "Profile",
              style: TextStyle(color: primaryBar, fontWeight: FontWeight.w600),
            ),
            onPressed: _navigateToProfile,
            style: TextButton.styleFrom(
              foregroundColor: primaryBar,
            ),
          ),
          SizedBox(width: 8),
          TextButton.icon(
            icon: Icon(Icons.logout, color: primaryBar),
            label: Text(
              "Logout",
              style: TextStyle(color: primaryBar, fontWeight: FontWeight.w600),
            ),
            onPressed: _logout,
            style: TextButton.styleFrom(
              foregroundColor: primaryBar,
            ),
          ),
          SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBar.withOpacity(0.93),
                    Colors.blueAccent.withOpacity(0.85)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text(
                    "Welcome, Faculty!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Manage your subjects and resources easily.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  double aspectRatio = 2.5;
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 4;
                    aspectRatio = 3.2;
                  } else if (constraints.maxWidth > 800) {
                    crossAxisCount = 3;
                    aspectRatio = 3.0;
                  } else if (constraints.maxWidth > 600) {
                    crossAxisCount = 2;
                    aspectRatio = 2.8;
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth > 600 ? 16 : 12,
                      vertical: 12,
                    ),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: features.length,
                      itemBuilder: (context, index) {
                        final feature = features[index];
                        final cardColor = cardColors[index % cardColors.length];
                        return _FeatureCard(
                            feature: feature, cardColor: cardColor);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final Map<String, dynamic> feature;
  final Color cardColor;
  const _FeatureCard({required this.feature, required this.cardColor});

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
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          border:
              Border.all(color: Colors.blueAccent.withOpacity(0.13), width: 1),
        ),
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryBar.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(feature['icon'], color: primaryBar, size: 28),
            ),
            SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
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
            Icon(Icons.arrow_forward_ios, size: 16, color: primaryBar),
          ],
        ),
      ),
    );
  }
}
