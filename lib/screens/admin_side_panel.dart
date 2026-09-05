import 'package:flutter/material.dart';
import 'package:stela_app/constants/colors.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xff111827),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.admin_panel_settings,
              size: 40,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "MSTELA ADMIN",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          sideMenuTile(
            index: 0,
            icon: Icons.dashboard,
            title: "Dashboard",
          ),
          sideMenuTile(
            index: 1,
            icon: Icons.people,
            title: "Manage Users",
          ),
          sideMenuTile(
            index: 2,
            icon: Icons.menu_book,
            title: "Manage Subjects",
          ),
          sideMenuTile(
            index: 3,
            icon: Icons.analytics,
            title: "Analytics",
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget sideMenuTile({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool selected = selectedIndex == index;

    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: Colors.white,
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
