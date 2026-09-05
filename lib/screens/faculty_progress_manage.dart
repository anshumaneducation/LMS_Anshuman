import 'package:flutter/material.dart';

class FacultyProgressManage extends StatelessWidget {
  final Map<String, dynamic> subject;
  const FacultyProgressManage({required this.subject});

  @override
  Widget build(BuildContext context) {
    // Dummy student progress data
    final List<Map<String, dynamic>> studentProgress = [
      {"name": "Alice", "progress": 85},
      {"name": "Bob", "progress": 72},
      {"name": "Charlie", "progress": 90},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Student Progress - ${subject['label']}"),
        backgroundColor: subject['color'],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: studentProgress.isEmpty
            ? Text("No progress data available.")
            : ListView.builder(
                itemCount: studentProgress.length,
                itemBuilder: (context, index) {
                  final student = studentProgress[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: subject['color'],
                        child: Text(student['name'][0]),
                      ),
                      title: Text(student['name']),
                      subtitle: Text("Progress: ${student['progress']}%"),
                      trailing: LinearProgressIndicator(
                        value: (student['progress'] as int) / 100,
                        color: subject['color'],
                        backgroundColor: subject['color'].withOpacity(0.2),
                        minHeight: 8,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}