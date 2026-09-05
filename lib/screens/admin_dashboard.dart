// import 'package:flutter/material.dart';
// import 'package:stela_app/constants/colors.dart';

// class AdminDashboard extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Admin Dashboard"),
//         backgroundColor: primaryBar,
//       ),
//       body: GridView.count(
//         crossAxisCount: 2,
//         padding: EdgeInsets.all(16),
//         crossAxisSpacing: 10,
//         mainAxisSpacing: 10,
//         children: [
//           _buildCard("👥 Manage Users"),
//           _buildCard("📚 Manage Subjects"),
//           _buildCard("📈 View Analytics"),
//         ],
//       ),
//     );
//   }

//   Widget _buildCard(String label) {
//     return Card(
//       elevation: 4,
//       child: InkWell(
//         onTap: () {},
//         child: Center(
//           child: Padding(
//             padding: EdgeInsets.all(12),
//             child: Text(label,
//                 textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/screens/admin_manage_users.dart';
import 'package:stela_app/screens/admin_manage_subjects.dart';
import 'package:stela_app/screens/admin_analytics_page.dart';
import 'package:stela_app/utils/role_guard.dart';
import 'package:stela_app/screens/admin_side_panel.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isAuthorized = false;
  bool _isLoading = true;

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _verifyAdmin();
  }

  Future<void> _verifyAdmin() async {
    final allowed = await RoleGuard.isAdmin();

    if (!allowed) {
      setState(() {
        _isAuthorized = false;
        _isLoading = false;
      });

      await RoleGuard.logout();
      return;
    }

    setState(() {
      _isAuthorized = true;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await RoleGuard.logout();

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _handleSidebarSelection(int index) {
    if (selectedIndex == index) return;

    switch (index) {
      case 0:
        setState(() => selectedIndex = 0);
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminManageUsersPage(),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminManageSubjectsPage(),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminAnalyticsPage(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthorized) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Unauthorized Access',
            style: TextStyle(
              color: Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: primaryWhite,
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: selectedIndex,
            onItemSelected: _handleSidebarSelection,
            onLogout: _logout,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome Back, Admin",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: primaryBar,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Manage your platform efficiently.",
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 16,
                    ),
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
