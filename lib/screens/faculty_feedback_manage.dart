import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stela_app/constants/colors.dart';

class FacultyFeedbackManage extends StatefulWidget {
  const FacultyFeedbackManage({Key? key}) : super(key: key);

  @override
  State<FacultyFeedbackManage> createState() => _FacultyFeedbackManageState();
}

class _FacultyFeedbackManageState extends State<FacultyFeedbackManage> {
  Future<void> _confirmDelete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete feedback?'),
        content: Text('This will permanently delete the feedback.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await FirebaseFirestore.instance.collection('student_feedback').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting feedback: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collection('student_feedback').orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Feedback'),
        backgroundColor: primaryBar,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error loading feedback'));
            if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return Center(child: Text('No feedback submitted yet'));

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final d = docs[index];
                final data = d.data() as Map<String, dynamic>? ?? {};
                final title = data['title'] ?? '';
                final message = data['message'] ?? '';
                final student = data['studentName'] ?? '';
                final ts = data['timestamp'];
                DateTime? date;
                if (ts is Timestamp) date = ts.toDate();
                if (ts is DateTime) date = ts;

                return Card(
                  child: ListTile(
                    title: Text(title.isNotEmpty ? title : 'Feedback from $student'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6),
                        Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 6),
                        Text(student, style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (date != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text('${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}'),
                          ),
                        PopupMenuButton<String>(
                          onSelected: (val) async {
                            if (val == 'delete') await _confirmDelete(d.id);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(title.isNotEmpty ? title : 'Feedback'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message),
                            SizedBox(height: 12),
                            Text('From: $student', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Close'))],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
