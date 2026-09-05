// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class FacultyAssignmentSubmissionsManage extends StatefulWidget {
//   final Map<String, dynamic> subject;
//   const FacultyAssignmentSubmissionsManage({required this.subject, super.key});

//   @override
//   State<FacultyAssignmentSubmissionsManage> createState() => _FacultyAssignmentSubmissionsManageState();
// }

// class _FacultyAssignmentSubmissionsManageState extends State<FacultyAssignmentSubmissionsManage> {
//   final _firestore = FirebaseFirestore.instance;

//   final Map<String, Map<String, dynamic>> _studentCache = {};
//   final Set<String> _studentLoading = {};

//   @override
//   void initState() {
//     super.initState();
//   }

//   Future<void> _ensureStudentsLoaded(Iterable<String> uids) async {
//     final missing = uids.where((u) => u.isNotEmpty && !_studentCache.containsKey(u) && !_studentLoading.contains(u)).toList();
//     if (missing.isEmpty) return;

//     setState(() {
//       _studentLoading.addAll(missing);
//     });

//     for (final uid in missing) {
//       try {
//         final snap = await _firestore.collection('students').doc(uid).get().timeout(const Duration(seconds: 15));
//         if (!mounted) return;
//         setState(() {
//           _studentCache[uid] = snap.data() ?? const <String, dynamic>{};
//         });
//       } catch (_) {
//         if (!mounted) return;
//         setState(() {
//           _studentCache[uid] = const <String, dynamic>{};
//         });
//       } finally {
//         if (!mounted) return;
//         setState(() {
//           _studentLoading.remove(uid);
//         });
//       }
//     }
//   }

//   String _studentName(String studentUid, Map<String, dynamic> submission) {
//     final fromSubmission = (submission['studentName'] ?? '').toString().trim();
//     if (fromSubmission.isNotEmpty) return fromSubmission;

//     final data = _studentCache[studentUid];
//     final name = (data?['name'] ?? data?['fullName'] ?? '').toString().trim();
//     return name.isNotEmpty ? name : studentUid;
//   }

//   String _studentEnrollment(String studentUid, Map<String, dynamic> submission) {
//     final fromSubmission = (submission['enrollmentNumber'] ?? submission['enrollmentNo'] ?? '').toString().trim();
//     if (fromSubmission.isNotEmpty) return fromSubmission;

//     final data = _studentCache[studentUid];
//     final v = (data?['enrollmentNumber'] ?? data?['enrollmentNo'] ?? data?['rollNumber'] ?? data?['rollNo'] ?? '').toString().trim();
//     return v;
//   }

//   String _studentBatch(String studentUid, Map<String, dynamic> submission) {
//     final fromSubmission = (submission['batch'] ?? submission['year'] ?? submission['section'] ?? '').toString().trim();
//     if (fromSubmission.isNotEmpty) return fromSubmission;

//     final data = _studentCache[studentUid];
//     final v = (data?['batch'] ?? data?['year'] ?? data?['section'] ?? data?['department'] ?? '').toString().trim();
//     return v;
//   }

//   Future<void> _openFileUrl(String url) async {
//     final trimmed = url.trim();
//     if (trimmed.isEmpty) return;
//     final uri = Uri.tryParse(trimmed);
//     if (uri == null) return;

//     final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
//     if (!ok && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Could not open file URL')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final subjectLabel = (widget.subject['label'] ?? widget.subject['id'] ?? '').toString();
//     final subjectId = (widget.subject['id'] ?? widget.subject['value'] ?? '').toString();

//     final baseQuery = subjectId.isNotEmpty
//         ? _firestore.collection('assignment_Submissions').where('subjectId', isEqualTo: subjectId)
//         : _firestore.collection('assignment_Submissions').where('subjectLabel', isEqualTo: subjectLabel);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Assignment Submissions - $subjectLabel'),
//         backgroundColor: widget.subject['color'],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//           stream: baseQuery.snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(child: Text('Error loading submissions: ${snapshot.error}'));
//             }
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             final docs = snapshot.data?.docs ?? const [];
//             if (docs.isEmpty) {
//               return const Center(child: Text('No assignment submissions yet.'));
//             }

//             final items = docs.map((d) => {'id': d.id, ...d.data()}).toList();
//             items.sort((a, b) {
//               final at = a['submittedAt'];
//               final bt = b['submittedAt'];
//               final aMs = at is Timestamp ? at.millisecondsSinceEpoch : 0;
//               final bMs = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
//               return bMs.compareTo(aMs);
//             });

//             // Load student profiles (name/enrollment/batch) for display.
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               final uids = items
//                   .map((e) => (e['studentUID'] ?? '').toString())
//                   .where((u) => u.isNotEmpty)
//                   .toSet();
//               _ensureStudentsLoaded(uids);
//             });

//             // Group by assignment.
//             final Map<String, List<Map<String, dynamic>>> groups = {};
//             for (final s in items) {
//               final key = (s['assignmentTitle'] ?? s['assignmentId'] ?? 'Unknown Assignment').toString();
//               groups.putIfAbsent(key, () => []).add(s);
//             }

//             final entries = groups.entries.toList();

//             return ListView.builder(
//               itemCount: entries.length,
//               itemBuilder: (context, index) {
//                 final entry = entries[index];
//                 final assignmentTitle = entry.key;
//                 final submissions = entry.value;

//                 return Card(
//                   child: ExpansionTile(
//                     title: Text(
//                       assignmentTitle,
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text('${submissions.length} submissions'),
//                     children: submissions.map((s) {
//                       final studentUid = (s['studentUID'] ?? '').toString();
//                       final name = _studentName(studentUid, s);
//                       final enrollment = _studentEnrollment(studentUid, s);
//                       final batch = _studentBatch(studentUid, s);
//                       final fileName = (s['fileName'] ?? '').toString();
//                       final fileUrl = (s['fileUrl'] ?? '').toString();
//                       final submittedAt = s['submittedAt'];
//                       final submittedText = submittedAt is Timestamp
//                           ? submittedAt.toDate().toLocal().toString()
//                           : '';

//                       final subtitleBits = <String>[];
//                       if (enrollment.isNotEmpty) subtitleBits.add('Roll: $enrollment');
//                       if (batch.isNotEmpty) subtitleBits.add('Batch: $batch');
//                       if (fileName.trim().isNotEmpty) subtitleBits.add('File: $fileName');
//                       if (submittedText.isNotEmpty) subtitleBits.add('Submitted: $submittedText');

//                       return ListTile(
//                         title: Text(name),
//                         subtitle: Text(subtitleBits.join(' • ')),
//                         trailing: TextButton(
//                           onPressed: fileUrl.trim().isEmpty ? null : () => _openFileUrl(fileUrl),
//                           child: const Text('Open file'),
//                         ),
//                         onTap: fileUrl.trim().isEmpty ? null : () => _openFileUrl(fileUrl),
//                       );
//                     }).toList(),
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FacultyAssignmentSubmissionsManage extends StatefulWidget {
  final Map<String, dynamic> subject;
  final String assignmentId;
  final String assignmentTitle;

  const FacultyAssignmentSubmissionsManage({
    required this.subject,
    required this.assignmentId,
    required this.assignmentTitle,
    super.key,
  });

  @override
  State<FacultyAssignmentSubmissionsManage> createState() =>
      _FacultyAssignmentSubmissionsManageState();
}

class _FacultyAssignmentSubmissionsManageState
    extends State<FacultyAssignmentSubmissionsManage> {
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true;

  List<Map<String, dynamic>> submissions = [];

  final Map<String, Map<String, dynamic>> _studentCache = {};

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final snapshot = await _firestore
          .collection('assignmentSubmissions')
          .where(
            'assignmentId',
            isEqualTo: widget.assignmentId,
          )
          .get();

      List<Map<String, dynamic>> loaded = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final studentUid = (data['studentUID'] ?? '').toString();

// Load student details
        if (!_studentCache.containsKey(studentUid)) {
          try {
            final studentDoc =
                await _firestore.collection('students').doc(studentUid).get();

            _studentCache[studentUid] = studentDoc.data() ?? {};
          } catch (_) {
            _studentCache[studentUid] = {};
          }
        }

        final studentData = _studentCache[studentUid] ?? {};

        loaded.add({
          'studentUID': studentUid,
          'studentName': studentData['name'] ??
              studentData['fullName'] ??
              'Unknown Student',
          'enrollment': studentData['enrollmentNumber'] ??
              studentData['rollNumber'] ??
              '',
          'batch': studentData['batch'] ?? studentData['year'] ?? '',
          'fileName': data['fileName'] ?? '',
          'fileUrl': data['fileUrl'] ?? '',
          'submittedAt': (data['submittedAt'] as Timestamp?)?.toDate(),
        });
      }

      loaded.sort((a, b) {
        final aTime = a['submittedAt'] as DateTime?;
        final bTime = b['submittedAt'] as DateTime?;

        if (aTime == null || bTime == null) return 0;

        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          submissions = loaded;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading submissions: $e');

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open file'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final subjectLabel =
    //     (widget.subject['label'] ?? widget.subject['id'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.assignmentTitle} Submissions',
        ),
        backgroundColor: widget.subject['color'],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : submissions.isEmpty
              ? const Center(
                  child: Text(
                    'No submissions yet.',
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: ListView.builder(
                    itemCount: submissions.length,
                    itemBuilder: (context, index) {
                      final s = submissions[index];

                      final studentName = (s['studentName'] ?? '').toString();

                      final enrollment = (s['enrollment'] ?? '').toString();

                      final batch = (s['batch'] ?? '').toString();

                      final fileName = (s['fileName'] ?? '').toString();

                      final fileUrl = (s['fileUrl'] ?? '').toString();

                      final submittedAt = s['submittedAt'] as DateTime?;

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.assignment_turned_in),
                          title: Text(studentName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (enrollment.isNotEmpty)
                                Text('Roll No: $enrollment'),
                              if (batch.isNotEmpty) Text('Batch: $batch'),
                              Text('File: $fileName'),
                              if (submittedAt != null)
                                Text(
                                  'Submitted: ${submittedAt.toLocal()}',
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => _openFile(fileUrl),
                          ),
                          onTap: () => _openFile(fileUrl),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
