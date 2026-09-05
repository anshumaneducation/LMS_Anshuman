import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stela_app/utils/role_guard.dart';
import 'package:stela_app/screens/admin_side_panel.dart';
import 'package:stela_app/screens/admin_dashboard.dart';
import 'package:stela_app/screens/admin_manage_users.dart';
import 'package:stela_app/screens/admin_manage_subjects.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  int totalStudents = 0;
  int totalFaculty = 0;
  int totalCourses = 0;
  int totalAssignments = 0;
  int totalQuizzes = 0;

  Map<String, int> assignmentsPerSubject = {};
  List<Map<String, dynamic>> quizData = [];

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    await fetchCounts();
    await fetchAssignments();
    await fetchQuizzes();
  }

  Future<void> fetchCounts() async {
    final students =
        await FirebaseFirestore.instance.collection('students').get();

    final faculty =
        await FirebaseFirestore.instance.collection('faculty').get();

    final courses =
        await FirebaseFirestore.instance.collection('subjects').get();

    setState(() {
      totalStudents = students.docs.length;
      totalFaculty = faculty.docs.length;
      totalCourses = courses.docs.length;
    });
  }

  Future<void> fetchAssignments() async {
    final subjectsSnapshot =
        await FirebaseFirestore.instance.collection('subjects').get();

    Map<String, int> subjectCount = {};

    int total = 0;

    for (var subjectDoc in subjectsSnapshot.docs) {
      final subjectData = subjectDoc.data();

      final subjectName = subjectData['label'] ?? 'Unknown Subject';

      // FETCH ASSESSMENTS SUBCOLLECTION
      final assessmentsSnapshot =
          await subjectDoc.reference.collection('assessments').get();

      final assessmentCount = assessmentsSnapshot.docs.length;

      subjectCount[subjectName] = assessmentCount;

      total += assessmentCount;
    }

    setState(() {
      assignmentsPerSubject = subjectCount;
      totalAssignments = total;
    });
  }

  Future<void> fetchQuizzes() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('quizzes').get();

    List<Map<String, dynamic>> quizzes = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      quizzes.add({
        "subject": data['subject'] ?? 'Unknown',
        "title": data['title'] ?? 'Quiz',
        "time": data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      });
    }

    setState(() {
      totalQuizzes = snapshot.docs.length;
      quizData = quizzes;
    });
  }

  // PROFESSIONAL SMALL CARD
  Widget analyticsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SUBJECT BAR CHART
  Widget buildBarChart() {
    if (assignmentsPerSubject.isEmpty) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            "No assignment data available",
          ),
        ),
      );
    }

    List<BarChartGroupData> bars = [];

    final subjects = assignmentsPerSubject.keys.toList();

    final counts = assignmentsPerSubject.values.toList();

    double maxY = counts.reduce((a, b) => a > b ? a : b).toDouble() + 2;

    for (int i = 0; i < subjects.length; i++) {
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: counts[i].toDouble(),
              width: 22,
              borderRadius: BorderRadius.circular(8),
              color: Colors.indigo,
            ),
          ],
        ),
      );
    }

    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index >= subjects.length) {
                    return const SizedBox();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: 70,
                      child: Text(
                        subjects[index],
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: bars,
        ),
      ),
    );
  }

  // QUIZ TILE
  Widget quizTile(Map<String, dynamic> quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.withOpacity(0.12),
          child: const Icon(
            Icons.quiz,
            color: Colors.deepPurple,
          ),
        ),
        title: Text(
          quiz['title'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            "Subject: ${quiz['subject']}\n"
            "Conducted: ${quiz['time']}",
          ),
        ),
      ),
    );
  }

  void _handleSidebarSelection(int index) {
    if (index == 3) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const AdminDashboard();
        break;
      case 1:
        destination = const AdminManageUsersPage();
        break;
      case 2:
        destination = const AdminManageSubjectsPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Future<void> _logout() async {
    await RoleGuard.logout();

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      body: Row(
        children: [
          // LEFT SIDEBAR
          AdminSidebar(
            selectedIndex: 3,
            onItemSelected: _handleSidebarSelection,
            onLogout: _logout,
          ),

          // MAIN CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Analytics Dashboard",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Monitor platform performance and activity",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // SMALL CARDS IN SINGLE ROW
                  Row(
                    children: [
                      analyticsCard(
                        title: "Students",
                        value: totalStudents.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      analyticsCard(
                        title: "Faculty",
                        value: totalFaculty.toString(),
                        icon: Icons.school,
                        color: Colors.green,
                      ),
                      analyticsCard(
                        title: "Courses",
                        value: totalCourses.toString(),
                        icon: Icons.book,
                        color: Colors.orange,
                      ),
                      analyticsCard(
                        title: "Assignments",
                        value: totalAssignments.toString(),
                        icon: Icons.assignment,
                        color: Colors.purple,
                      ),
                      analyticsCard(
                        title: "Quizzes",
                        value: totalQuizzes.toString(),
                        icon: Icons.quiz,
                        color: Colors.red,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // CHART + QUIZ SECTION
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BAR CHART
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Assignments Per Subject",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            buildBarChart(),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // QUIZ LIST
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Recent Quizzes",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 400,
                                child: ListView.builder(
                                  itemCount: quizData.length,
                                  itemBuilder: (context, index) {
                                    return quizTile(
                                      quizData[index],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
