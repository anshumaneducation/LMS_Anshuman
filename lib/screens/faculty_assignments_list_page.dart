import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'faculty_assignment_submissions_manage.dart';

class FacultyAssignmentsListPage extends StatelessWidget {
  final Map<String, dynamic> subject;

  const FacultyAssignmentsListPage({
    super.key,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final String subjectId = (subject['id'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${subject['label']} Assignments',
        ),
        backgroundColor: subject['color'],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subjects')
            .doc(subjectId)
            .collection('assessments')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No assignments found.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];

              final data = doc.data() as Map<String, dynamic>;

              final assignmentTitle = (data['title'] ??
                      data['assignmentTitle'] ??
                      'Untitled Assignment')
                  .toString();

              final dueDate = (data['dueDate'] as Timestamp?)?.toDate();

              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.assignment,
                  ),
                  title: Text(
                    assignmentTitle,
                  ),
                  subtitle: dueDate != null
                      ? Text(
                          'Due: ${dueDate.toLocal()}',
                        )
                      : null,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FacultyAssignmentSubmissionsManage(
                          subject: subject,
                          assignmentId: doc.id,
                          assignmentTitle: assignmentTitle,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
