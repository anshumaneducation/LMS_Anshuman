import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stela_app/constants/colors.dart';

class FacultyManageSubjects extends StatefulWidget {
  @override
  _FacultyManageSubjectsState createState() => _FacultyManageSubjectsState();
}

class _FacultyManageSubjectsState extends State<FacultyManageSubjects> {
  late String _facultyUID;
  StreamSubscription<User?>? _authSub;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form fields
  late TextEditingController _subjectNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  int _selectedIconIndex = 0;

  final List<IconData> _availableIcons = [
    Icons.psychology,
    Icons.cloud,
    Icons.build,
    Icons.network_check,
    Icons.computer,
    Icons.memory,
    Icons.functions,
    Icons.wifi,
    Icons.science,
    Icons.code,
    Icons.storage,
    Icons.security,
    Icons.extension,
  ];

  final List<Color> _availableColors = [
    Colors.orange,
    Colors.blue,
    Colors.redAccent,
    Colors.lightBlue,
    Colors.green,
    Colors.deepPurple,
    Colors.indigo,
    Colors.cyan,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _subjectNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _categoryController = TextEditingController();
    _facultyUID = FirebaseAuth.instance.currentUser?.uid ?? '';
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final uid = user?.uid ?? '';
      if (uid.isNotEmpty && uid != _facultyUID && mounted) {
        setState(() {
          _facultyUID = uid;
        });
      }
    });
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _addSubject() async {
    if (!_formKey.currentState!.validate()) return;

    final facultyUID = FirebaseAuth.instance.currentUser?.uid ?? _facultyUID;
    if (facultyUID.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait—sign-in is still initializing.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get faculty name
      final facultyDoc = await FirebaseFirestore.instance
          .collection('faculty')
          .doc(facultyUID)
          .get();
      final facultyName = facultyDoc.data()?['name'] ?? 'Unknown Faculty';

      // Store in global subjects collection
      await FirebaseFirestore.instance.collection('subjects').add({
        'label': _subjectNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'icon': _selectedIconIndex,
        'color': _availableColors[0].value,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'facultyUID': facultyUID,
        'facultyName': facultyName,
      });

      _subjectNameController.clear();
      _descriptionController.clear();
      _categoryController.clear();
      _selectedIconIndex = 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subject created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating subject: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Future<void> _deleteSubject(String subjectId) async {
  //   try {
  //     await FirebaseFirestore.instance
  //         .collection('subjects')
  //         .doc(subjectId)
  //         .delete();

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Subject deleted successfully!'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error deleting subject: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }
  Future<void> _deleteSubject(String subjectId) async {
    setState(() => _isLoading = true);

    try {
      /// =========================
      /// DELETE RESOURCES
      /// =========================
      final resourcesSnap = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectId)
          .collection('resources')
          .get();

      for (final doc in resourcesSnap.docs) {
        final data = doc.data();

        final fileUrl = (data['fileUrl'] ?? data['fileURL'] ?? '').toString();

        /// Delete resource storage file
        if (fileUrl.isNotEmpty &&
            (fileUrl.contains('firebasestorage.googleapis.com') ||
                fileUrl.startsWith('gs://') ||
                fileUrl.contains('storage.googleapis.com'))) {
          try {
            await FirebaseStorage.instance.refFromURL(fileUrl).delete();
          } catch (e) {
            debugPrint('Resource storage delete failed: $e');
          }
        }

        /// Delete resource document
        try {
          await doc.reference.delete();
        } catch (e) {
          debugPrint('Resource document delete failed: $e');
        }
      }

      /// DELETE ASSESSMENTS
      final assessmentsSnap = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectId)
          .collection('assessments')
          .get();

      for (final assessmentDoc in assessmentsSnap.docs) {
        final assessmentId = assessmentDoc.id;

        /// DELETE STUDENT SUBMISSIONS
        final submissionsSnap = await FirebaseFirestore.instance
            .collection('assignmentSubmissions')
            .where('assignmentId', isEqualTo: assessmentId)
            .get();

        for (final submissionDoc in submissionsSnap.docs) {
          final data = submissionDoc.data();

          final filePath = (data['filePath'] ?? '').toString();
          final fileUrl = (data['fileUrl'] ?? '').toString();

          /// Delete submission storage file
          if (filePath.isNotEmpty) {
            try {
              await FirebaseStorage.instance.ref().child(filePath).delete();
            } catch (e) {
              debugPrint('Submission file delete failed: $e');
            }
          } else if (fileUrl.isNotEmpty &&
              (fileUrl.contains('firebasestorage.googleapis.com') ||
                  fileUrl.startsWith('gs://') ||
                  fileUrl.contains('storage.googleapis.com'))) {
            try {
              await FirebaseStorage.instance.refFromURL(fileUrl).delete();
            } catch (e) {
              debugPrint('Submission URL delete failed: $e');
            }
          }

          /// Delete submission document
          try {
            await submissionDoc.reference.delete();
          } catch (e) {
            debugPrint('Submission document delete failed: $e');
          }
        }

        /// Delete assessment document
        try {
          await assessmentDoc.reference.delete();
        } catch (e) {
          debugPrint('Assessment delete failed: $e');
        }
      }

      /// DELETE SUBJECT DOCUMENT
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subject deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting subject: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteConfirmation(String subjectId, String subjectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Are you sure you want to delete "$subjectName"?\n\n'
          'This will permanently delete:\n'
          '• All subject resources\n'
          '• All assessments\n'
          '• All student submissions\n'
          '• All uploaded files from Firebase Storage',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: primaryBar),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteSubject(subjectId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  // void _showDeleteConfirmation(String subjectId, String subjectName) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Delete Subject'),
  //       content: Text('Are you sure you want to delete "$subjectName"?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text('Cancel', style: TextStyle(color: primaryBar)),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             _deleteSubject(subjectId);
  //           },
  //           child: Text('Delete', style: TextStyle(color: Colors.red)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryWhite,
      appBar: AppBar(
        title: Text('Manage Subjects'),
        backgroundColor: primaryBar,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Add Subject Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_circle,
                              color: primaryButton, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Add New Subject',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryBar,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Subject Name
                            TextFormField(
                              controller: _subjectNameController,
                              decoration: InputDecoration(
                                labelText: 'Subject Name',
                                hintText: 'e.g., Advanced Algorithms',
                                prefixIcon:
                                    Icon(Icons.subject, color: primaryBar),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: primaryButton, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter subject name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Description (Optional)
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description (Optional)',
                                hintText: 'Brief description of the subject',
                                prefixIcon:
                                    Icon(Icons.description, color: primaryBar),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: primaryButton, width: 2),
                                ),
                              ),
                              maxLines: 3,
                            ),
                            SizedBox(height: 16),

                            // Category
                            TextFormField(
                              controller: _categoryController,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                hintText: 'e.g., Core, Elective',
                                prefixIcon:
                                    Icon(Icons.category, color: primaryBar),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: primaryButton, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter category';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Icon Selection
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Subject Icon',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: primaryBar,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(
                                    _availableIcons.length,
                                    (index) => GestureDetector(
                                      onTap: () {
                                        setState(
                                            () => _selectedIconIndex = index);
                                      },
                                      child: Container(
                                        height: 60,
                                        width: 60,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _selectedIconIndex == index
                                                ? primaryButton
                                                : primaryBar.withOpacity(0.3),
                                            width: _selectedIconIndex == index
                                                ? 3
                                                : 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: _selectedIconIndex == index
                                              ? primaryButton.withOpacity(0.1)
                                              : Colors.transparent,
                                        ),
                                        child: Icon(
                                          _availableIcons[index],
                                          color: _selectedIconIndex == index
                                              ? primaryButton
                                              : primaryBar.withOpacity(0.6),
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),

                            // Submit Button
                            _isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        primaryButton,
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _addSubject,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryButton,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Create Subject',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32),

              // My Subjects Section
              Text(
                'Your Subjects',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryBar,
                ),
              ),
              SizedBox(height: 16),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('subjects')
                    .where('facultyUID', isEqualTo: _facultyUID)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(primaryButton),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading subjects'),
                    );
                  }

                  final subjects = List<QueryDocumentSnapshot>.from(
                      snapshot.data?.docs ?? const []);
                  // Sort client-side by createdAt desc to avoid requiring a composite index.
                  subjects.sort((a, b) {
                    final ad = a.data() as Map<String, dynamic>;
                    final bd = b.data() as Map<String, dynamic>;
                    final at = ad['createdAt'];
                    final bt = bd['createdAt'];
                    final aMs = at is Timestamp ? at.millisecondsSinceEpoch : 0;
                    final bMs = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
                    return bMs.compareTo(aMs);
                  });

                  if (subjects.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.no_encryption_outlined,
                            size: 64,
                            color: primaryBar.withOpacity(0.3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No subjects yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: primaryBar.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final data = subject.data() as Map<String, dynamic>;
                      final iconIndex = data['icon'] as int? ?? 0;

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryButton.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _availableIcons[iconIndex],
                              color: primaryButton,
                            ),
                          ),
                          title: Text(
                            data['label'] ?? 'Unnamed Subject',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryBar,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                data['description'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryBar.withOpacity(0.6),
                                ),
                              ),
                              SizedBox(height: 4),
                              Chip(
                                label: Text(
                                  data['category'] ?? 'N/A',
                                  style: TextStyle(fontSize: 12),
                                ),
                                backgroundColor: primaryButton.withOpacity(0.2),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteConfirmation(
                                subject.id,
                                data['label'] ?? 'Subject',
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
