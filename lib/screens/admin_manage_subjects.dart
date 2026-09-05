import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/screens/admin_dashboard.dart';
import 'package:stela_app/screens/admin_subject_resources_page.dart';

class AdminManageSubjectsPage extends StatefulWidget {
  const AdminManageSubjectsPage({super.key});

  @override
  State<AdminManageSubjectsPage> createState() =>
      _AdminManageSubjectsPageState();
}

class _AdminManageSubjectsPageState extends State<AdminManageSubjectsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  String? selectedFacultyUID;
  String? selectedFacultyName;

  final List<IconData> availableIcons = [
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

  Future<void> _showCreateSubjectDialog({
    DocumentSnapshot? doc,
  }) async {
    final isEdit = doc != null;

    final data = doc?.data() as Map<String, dynamic>?;

    selectedFacultyUID = data?['facultyUID'];

    selectedFacultyName = data?['facultyName'];

    final nameController = TextEditingController(
      text: data?['label'] ?? '',
    );

    final categoryController = TextEditingController(
      text: data?['category']?.toString() ?? '',
    );

    final codeController = TextEditingController(
      text: data?['code'] ?? '',
    );

    final descController = TextEditingController(
      text: data?['description'] ?? '',
    );

    int selectedIcon = data?['icon'] ?? 0;

    Color selectedColor = Color(
      data?['color'] ?? 0xFF2196F3,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit ? 'Edit Subject' : 'Create Subject',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Subject Name',
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: codeController,
                      decoration: InputDecoration(
                        labelText: 'Subject Code',
                      ),
                    ),
                    SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('faculty')
                          .where(
                            'userRole',
                            isEqualTo: 'Faculty',
                          )
                          .snapshots(),
                      builder: (
                        context,
                        snapshot,
                      ) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Text(
                            'No faculty found',
                          );
                        }

                        final facultyDocs = snapshot.data!.docs;

                        return DropdownButtonFormField<String>(
                          value: facultyDocs.any(
                            (doc) => doc.id == selectedFacultyUID,
                          )
                              ? selectedFacultyUID
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Select Faculty',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: facultyDocs.map((doc) {
                            final facultyData =
                                doc.data() as Map<String, dynamic>;

                            final facultyName =
                                facultyData['name'] ?? 'Unknown Faculty';

                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(facultyName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedFacultyUID = value;

                              final selectedDoc = facultyDocs.firstWhere(
                                (doc) => doc.id == value,
                              );

                              final selectedData =
                                  selectedDoc.data() as Map<String, dynamic>;

                              selectedFacultyName = selectedData['name'] ?? '';
                            });
                          },
                        );
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      decoration: InputDecoration(
                        labelText: 'Category',
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Icon',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: List.generate(
                        availableIcons.length,
                        (index) {
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedIcon = index;
                              });
                            },
                            child: CircleAvatar(
                              backgroundColor: selectedIcon == index
                                  ? Colors.blue
                                  : Colors.grey.shade200,
                              child: Icon(
                                availableIcons[index],
                                color: selectedIcon == index
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Color',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: [
                        Colors.blue,
                        Colors.green,
                        Colors.orange,
                        Colors.purple,
                        Colors.red,
                        Colors.teal,
                      ].map((color) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = color;
                            });
                          },
                          child: CircleAvatar(
                            backgroundColor: color,
                            child: selectedColor == color
                                ? Icon(
                                    Icons.check,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final payload = {
                      'category': categoryController.text.trim(),
                      'code': codeController.text.trim(),
                      'color': selectedColor.value,
                      'description': descController.text.trim(),
                      'label': nameController.text.trim(),
                      'status': 'active',
                      'icon': selectedIcon,
                      'facultyName': selectedFacultyName ?? '',
                      'facultyUID': selectedFacultyUID ?? '',
                    };

                    if (isEdit) {
                      await FirebaseFirestore.instance
                          .collection('subjects')
                          .doc(doc.id)
                          .update(payload);
                    } else {
                      await FirebaseFirestore.instance
                          .collection('subjects')
                          .add({
                        ...payload,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }

                    Navigator.pop(context);
                  },
                  child: Text(
                    isEdit ? 'Update' : 'Create',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Future<void> _deleteSubject(String id) async {
  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Delete Subject'),
  //         content: Text(
  //           'Are you sure you want to delete this subject?',
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context, false),
  //             child: Text('Cancel'),
  //           ),
  //           ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.red,
  //             ),
  //             onPressed: () => Navigator.pop(context, true),
  //             child: Text('Delete'),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   if (confirm == true) {
  //     await FirebaseFirestore.instance.collection('subjects').doc(id).delete();
  //   }
  // }

  Future<void> _deleteSubject(String subjectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Subject'),
          content: const Text(
            'Are you sure you want to delete this subject?\n\n'
            'This will also delete:\n'
            '• All resources\n'
            '• All assessments\n'
            '• All student submissions\n'
            '• All uploaded files from Firebase Storage',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      /// DELETE RESOURCES
      final resourcesSnap = await FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectId)
          .collection('resources')
          .get();

      for (final doc in resourcesSnap.docs) {
        final data = doc.data();

        final fileUrl = (data['fileUrl'] ?? data['fileURL'] ?? '').toString();

        /// Delete storage file
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

        /// Delete Firestore document
        try {
          await doc.reference.delete();
        } catch (e) {
          debugPrint('Resource doc delete failed: $e');
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

        for (final subDoc in submissionsSnap.docs) {
          final data = subDoc.data();

          final filePath = (data['filePath'] ?? '').toString();
          final fileUrl = (data['fileUrl'] ?? '').toString();

          /// Delete storage file
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
            await subDoc.reference.delete();
          } catch (e) {
            debugPrint('Submission doc delete failed: $e');
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
        const SnackBar(
          content: Text('Subject and all related data deleted'),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete subject: $e'),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminDashboard(),
            ),
          );
        },
      ),
      title: Text(
        'Manage Subjects',
        style: TextStyle(
          fontFamily: 'PTSerif-Bold',
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: primaryBar,
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();

    return Scaffold(
      backgroundColor: primaryWhite,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryButton,
        onPressed: () => _showCreateSubjectDialog(),
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryBar,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Subject Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'PTSerif-Bold',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create, edit, and delete subjects from the admin panel.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontFamily: 'PTSerif',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search subjects',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('subjects')
                  .orderBy(
                    'createdAt',
                    descending: true,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No subjects found'),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final label = (data['label'] ?? '').toString().toLowerCase();

                  final code = (data['code'] ?? '').toString().toLowerCase();

                  final faculty =
                      (data['facultyName'] ?? '').toString().toLowerCase();

                  return label.contains(query) ||
                      code.contains(query) ||
                      faculty.contains(query);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text('No matching subjects'),
                  );
                }

                return LayoutBuilder(
                  builder: (
                    context,
                    constraints,
                  ) {
                    int crossAxisCount;
                    double childAspectRatio;

                    if (constraints.maxWidth > 1200) {
                      crossAxisCount = 4;
                      childAspectRatio = 1.05;
                    } else if (constraints.maxWidth > 800) {
                      crossAxisCount = 3;
                      childAspectRatio = 1.05;
                    } else if (constraints.maxWidth > 600) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.05;
                    } else {
                      crossAxisCount = 1;
                      childAspectRatio = 1.3;
                    }

                    return Padding(
                      padding: EdgeInsets.all(16),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (
                          context,
                          index,
                        ) {
                          final doc = docs[index];

                          final data = doc.data() as Map<String, dynamic>;

                          final color = Color(
                            data['color'] ?? 0xFF2196F3,
                          );

                          final iconIndex = data['icon'] ?? 0;

                          final icon = availableIcons[iconIndex.clamp(
                            0,
                            availableIcons.length - 1,
                          )];

                          return _buildSubjectCard(
                            doc,
                            data,
                            color,
                            icon,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
    Color color,
    IconData icon,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminSubjectResourcesPage(
              subjectId: doc.id,
              subjectData: data,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 0),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data['code'] ?? 'Code',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontFamily: 'PTSerif',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showCreateSubjectDialog(
                          doc: doc,
                        );
                      } else if (value == 'delete') {
                        _deleteSubject(doc.id);
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['label'] ?? 'Unnamed Subject',
                      style: TextStyle(
                        color: primaryBar,
                        fontSize: 16,
                        fontFamily: 'PTSerif-Bold',
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      data['description'] ?? '',
                      style: TextStyle(
                        color: primaryBar.withOpacity(0.65),
                        fontSize: 12,
                        fontFamily: 'PTSerif',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Faculty: ${data['facultyName'] ?? 'N/A'}',
                      style: TextStyle(
                        color: primaryButton,
                        fontSize: 11,
                        fontFamily: 'PTSerif',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Category: ${data['category'] ?? 'N/A'}',
                      style: TextStyle(
                        color: primaryButton.withOpacity(0.85),
                        fontSize: 11,
                        fontFamily: 'PTSerif',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
