import 'package:flutter/material.dart';
import 'package:stela_app/constants/colors.dart';

/// Clean quizzes screen (new file). Use this instead of the corrupted `quizzes.dart`.
class QuizzesClean extends StatelessWidget {
  static const String routeName = '/quizzes_clean';

  final List<Map<String, dynamic>> subjects = const [
    {'id': 'dsa', 'title': 'Data Structures & Algorithms', 'icon': Icons.code},
    {'id': 'iot', 'title': 'Internet of Things (IoT)', 'icon': Icons.wifi_tethering},
    {'id': 'ml', 'title': 'Machine Learning', 'icon': Icons.auto_graph},
    {'id': 'cloud', 'title': 'Cloud Computing', 'icon': Icons.cloud},
    {'id': 'ai', 'title': 'Artificial Intelligence', 'icon': Icons.memory},
    {'id': 'cprog', 'title': 'C Programming', 'icon': Icons.computer},
    {'id': 'theory_of_computation', 'title': 'Theory of Computation', 'icon': Icons.functions},
  ];

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = MediaQuery.of(context).size.width > 900 ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1);

    return Scaffold(
      backgroundColor: primaryBar,
      appBar: AppBar(
        title: Text('Quizzes', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBar,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            itemCount: subjects.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.4,
            ),
            itemBuilder: (context, index) {
              final s = subjects[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open ${s['title']}'))),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: primaryBar, borderRadius: BorderRadius.circular(10)),
                          child: Icon(s['icon'], color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 12),
                        Expanded(child: Text(s['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBar))),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
