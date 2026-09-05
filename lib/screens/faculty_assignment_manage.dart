// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// import 'faculty_create_assignment.dart';

// class FacultyAssignmentManage extends StatefulWidget {
//   final Map<String, dynamic> subject;
//   const FacultyAssignmentManage({required this.subject});

//   @override
//   State<FacultyAssignmentManage> createState() => _FacultyAssignmentManageState();
// }

// class _FacultyAssignmentManageState extends State<FacultyAssignmentManage> {
//   String get _subjectId => (widget.subject['id'] ?? widget.subject['value'] ?? '').toString();

//   Query<Map<String, dynamic>> _baseQuery(String uid) {
//     return FirebaseFirestore.instance.collection('assignments').where('facultyUID', isEqualTo: uid);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Assignments - ${widget.subject['label']}"),
//         backgroundColor: widget.subject['color'],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ElevatedButton.icon(
//               icon: Icon(Icons.add),
//               label: Text("Create New Assignment"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: widget.subject['color'],
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => FacultyCreateAssignment(preselectedSubject: widget.subject)),
//                 );
//               },
//             ),
//             SizedBox(height: 24),
//             Text(
//               "Previous Assignments",
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//             ),
//             SizedBox(height: 12),
//             Expanded(
//               child: uid.isEmpty
//                   ? Text('Please sign in to view assignments.')
//                   : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                       stream: _baseQuery(uid).snapshots(),
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState == ConnectionState.waiting) {
//                           return Center(child: CircularProgressIndicator());
//                         }
//                         if (snapshot.hasError) {
//                           return Text('Failed to load assignments: ${snapshot.error}');
//                         }

//                         final docs = snapshot.data?.docs ?? const [];
//                         final items = docs
//                             .map((d) => {'id': d.id, ...d.data()})
//                             .where((a) => (a['subjectId'] ?? '').toString() == _subjectId)
//                             .toList();

//                         items.sort((a, b) {
//                           final at = a['createdAt'];
//                           final bt = b['createdAt'];
//                           final aMs = at is Timestamp ? at.millisecondsSinceEpoch : 0;
//                           final bMs = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
//                           return bMs.compareTo(aMs);
//                         });

//                         if (items.isEmpty) {
//                           return Text('No assignments created yet.');
//                         }

//                         return ListView.builder(
//                           itemCount: items.length,
//                           itemBuilder: (context, index) {
//                             final assignment = items[index];
//                             final title = (assignment['title'] ?? '').toString();
//                             final due = assignment['dueDate'];
//                             final dueText = due is Timestamp
//                                 ? due.toDate().toLocal().toString().split(' ')[0]
//                                 : 'No due date';

//                             return Card(
//                               child: ListTile(
//                                 leading: Icon(Icons.assignment, color: widget.subject['color']),
//                                 title: Text(title.isEmpty ? 'Untitled Assignment' : title),
//                                 subtitle: Text('Due: $dueText'),
//                               ),
//                             );
//                           },
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'faculty_create_assignment.dart';

class FacultyAssignmentManage extends StatefulWidget {
  final Map<String, dynamic> subject;
  const FacultyAssignmentManage({required this.subject});

  @override
  State<FacultyAssignmentManage> createState() =>
      _FacultyAssignmentManageState();
}

class _FacultyAssignmentManageState extends State<FacultyAssignmentManage> {
  String get _subjectId =>
      (widget.subject['id'] ?? widget.subject['value'] ?? '').toString();

  // Queries directly from the subcollection and handles sorting server-side
  Stream<QuerySnapshot<Map<String, dynamic>>> _assignmentsStream() {
    return FirebaseFirestore.instance
        .collection('subjects')
        .doc(_subjectId)
        .collection('assessments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  //METHOD TO SHOW ASSIGNMENT DETAILS ---
  void _showAssignmentDetails(
      BuildContext context, Map<String, dynamic> assignment) {
    final title = (assignment['title'] ?? 'Untitled Assignment').toString();
    final description =
        (assignment['description'] ?? 'No description provided.').toString();
    final due = assignment['dueDate'];
    final dueText = due is Timestamp
        ? due.toDate().toLocal().toString().split(' ')[0]
        : 'No due date';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.assignment,
                  color: widget.subject['color'] ?? Colors.blue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Due Date:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                Text(dueText, style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Text(
                  "Description:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close",
                  style: TextStyle(color: widget.subject['color'])),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text("Assignments - ${widget.subject['label']}"),
        backgroundColor: widget.subject['color'],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text("Create New Assignment"),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.subject['color'],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FacultyCreateAssignment(
                        preselectedSubject: widget.subject),
                  ),
                );
              },
            ),
            SizedBox(height: 24),
            Text(
              "Previous Assignments",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 12),
            Expanded(
              child: uid.isEmpty
                  ? Text('Please sign in to view assignments.')
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _assignmentsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text(
                              'Failed to load assignments: ${snapshot.error}');
                        }

                        final docs = snapshot.data?.docs ?? const [];

                        if (docs.isEmpty) {
                          return Text('No assignments created yet.');
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final docData = docs[index].data();
                            final assignment = {
                              'id': docs[index].id,
                              ...docData
                            };

                            final title =
                                (assignment['title'] ?? '').toString();
                            final due = assignment['dueDate'];
                            final dueText = due is Timestamp
                                ? due
                                    .toDate()
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0]
                                : 'No due date';

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: Icon(Icons.assignment,
                                    color: widget.subject['color']),
                                title: Text(title.isEmpty
                                    ? 'Untitled Assignment'
                                    : title),
                                subtitle: Text('Due: $dueText'),
                                trailing: Icon(Icons.chevron_right,
                                    color: Colors.grey),
                                // --- TAP TO OPEN DETAIL WINDOW ---
                                onTap: () =>
                                    _showAssignmentDetails(context, assignment),
                              ),
                            );
                          },
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
