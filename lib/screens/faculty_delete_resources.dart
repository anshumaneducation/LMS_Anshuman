import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FacultyDeleteResourcesPage extends StatefulWidget {
  final Map<String, dynamic> subject;

  const FacultyDeleteResourcesPage({
    super.key,
    required this.subject,
  });

  @override
  State<FacultyDeleteResourcesPage> createState() =>
      _FacultyDeleteResourcesPageState();
}

class _FacultyDeleteResourcesPageState
    extends State<FacultyDeleteResourcesPage> {
  final _firestore = FirebaseFirestore.instance;

  bool _processing = false;

  Future<void> _deleteResource(
    String subjectId,
    String resourceId,
    String? fileUrl,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text(
          'Delete this resource? This will remove the Firestore document and storage file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);

    Exception? storageError;

    final isStorageUrl = fileUrl != null &&
        fileUrl.isNotEmpty &&
        (fileUrl.contains('firebasestorage.googleapis.com') ||
            fileUrl.startsWith('gs://') ||
            fileUrl.contains('storage.googleapis.com'));

    if (isStorageUrl) {
      try {
        await FirebaseStorage.instance.refFromURL(fileUrl).delete();
      } catch (e) {
        storageError = Exception('Storage delete failed: $e');
      }
    }

    try {
      await _firestore
          .collection('subjects')
          .doc(subjectId)
          .collection('resources')
          .doc(resourceId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            storageError == null
                ? 'Resource deleted'
                : 'Resource deleted (storage cleanup failed)',
          ),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete resource: $e'),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _deleteAssessment(
    String subjectId,
    String assessmentId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text(
          'Delete this assessment and all student submissions?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);

    try {
      final subsSnap = await _firestore
          .collection('assignmentSubmissions')
          .where('assignmentId', isEqualTo: assessmentId)
          .get();

      for (final doc in subsSnap.docs) {
        final data = doc.data();

        final filePath = (data['filePath'] ?? '').toString();
        final fileUrl = (data['fileUrl'] ?? '').toString();

        if (filePath.isNotEmpty) {
          try {
            await FirebaseStorage.instance.ref().child(filePath).delete();
          } catch (_) {}
        } else if (fileUrl.isNotEmpty &&
            (fileUrl.contains('firebasestorage.googleapis.com') ||
                fileUrl.startsWith('gs://') ||
                fileUrl.contains('storage.googleapis.com'))) {
          try {
            await FirebaseStorage.instance.refFromURL(fileUrl).delete();
          } catch (_) {}
        }

        try {
          await doc.reference.delete();
        } catch (_) {}
      }

      await _firestore
          .collection('subjects')
          .doc(subjectId)
          .collection('assessments')
          .doc(assessmentId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment and submissions deleted'),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete assessment: $e'),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectId = widget.subject['id'];
    final subjectLabel = widget.subject['label'] ?? 'Subject';

    return Scaffold(
      appBar: AppBar(
        title: Text('Delete: $subjectLabel'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(12),
            children: [
              /// RESOURCES
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Resources',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('subjects')
                    .doc(subjectId)
                    .collection('resources')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final docs = snap.data!.docs;

                  if (docs.isEmpty) {
                    return const Card(
                      child: ListTile(
                        title: Text('No resources found'),
                      ),
                    );
                  }

                  return Column(
                    children: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;

                      final fileUrl =
                          (data['fileUrl'] ?? data['fileURL'] ?? '').toString();

                      return Card(
                        child: ListTile(
                          title: Text(data['title'] ?? ''),
                          subtitle: Text(
                            (data['description'] ?? '').toString(),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: _processing
                                ? null
                                : () => _deleteResource(
                                      subjectId,
                                      d.id,
                                      fileUrl,
                                    ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              /// ASSESSMENTS
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Assessments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('subjects')
                    .doc(subjectId)
                    .collection('assessments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final docs = snap.data!.docs;

                  if (docs.isEmpty) {
                    return const Card(
                      child: ListTile(
                        title: Text('No assessments found'),
                      ),
                    );
                  }

                  return Column(
                    children: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          title: Text(data['title'] ?? ''),
                          subtitle: Text(
                            (data['description'] ?? '').toString(),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            onPressed: _processing
                                ? null
                                : () => _deleteAssessment(
                                      subjectId,
                                      d.id,
                                    ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
          if (_processing)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
