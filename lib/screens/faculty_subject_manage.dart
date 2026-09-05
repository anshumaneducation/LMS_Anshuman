import 'package:flutter/material.dart';

class FacultySubjectManage extends StatelessWidget {
  final Map<String, dynamic> subject;
  const FacultySubjectManage({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subject['label']),
        backgroundColor: subject['color'],
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          ListTile(
            leading: Icon(Icons.menu_book, color: subject['color']),
            title: Text("All Resources"),
            subtitle: Text("View and manage all resources for this subject"),
            onTap: () {
              // TODO: Implement resource management
            },
          ),
          ListTile(
            leading: Icon(Icons.assignment, color: subject['color']),
            title: Text("All Assignments"),
            subtitle: Text("View and manage all assignments for this subject"),
            onTap: () {
              // TODO: Implement assignment management
            },
          ),
          ListTile(
            leading: Icon(Icons.quiz, color: subject['color']),
            title: Text("All Quizzes"),
            subtitle: Text("View and manage all quizzes for this subject"),
            onTap: () {
              // TODO: Implement quiz management
            },
          ),
          // Add more management options as needed
        ],
      ),
    );
  }
}