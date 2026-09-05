import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/screens/faculty_subject_manage.dart';

class FacultySubjects extends StatefulWidget {
  @override
  _FacultySubjectsState createState() => _FacultySubjectsState();
}

class _FacultySubjectsState extends State<FacultySubjects> {
  late String _facultyUID;
  StreamSubscription<User?>? _authSub;
  String _searchQuery = '';

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

  // Default subjects for reference
  final List<Map<String, dynamic>> _defaultSubjects = [
    {
      "label": "Artificial Intelligence - Programming Tools",
      "icon": Icons.psychology,
      "description": "Learn AI programming tools and techniques",
      "color": Colors.orange,
    },
    {
      "label": "Cloud Computing",
      "icon": Icons.cloud,
      "description": "Explore cloud computing concepts and practices",
      "color": Colors.blue,
    },
    {
      "label": "Compiler Design",
      "icon": Icons.build,
      "description": "Learn about compiler construction and design",
      "color": Colors.redAccent,
    },
    {
      "label": "Computer Networks",
      "icon": Icons.network_check,
      "description": "Study computer networking concepts and protocols",
      "color": Colors.lightBlue,
    },
    {
      "label": "Computer Organization and Architecture",
      "icon": Icons.computer,
      "description": "Understand computer architecture and organization",
      "color": Colors.green,
    },
    {
      "label": "Machine Learning",
      "icon": Icons.memory,
      "description": "Introduction to machine learning concepts and algorithms",
      "color": Colors.deepPurple,
    },
    {
      "label": "Theory of Computation",
      "icon": Icons.functions,
      "description": "Study automata, formal languages, computability, and complexity",
      "color": Colors.indigo,
    },
    {
      "label": "Wireless Networks",
      "icon": Icons.wifi,
      "description": "Study wireless communication and networking",
      "color": Colors.cyan,
    },
  ];

  @override
  void initState() {
    super.initState();
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
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subjects'),
        backgroundColor: primaryBar,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search subjects',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (query) {
                setState(() => _searchQuery = query);
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('subjects')
                  .where('facultyUID', isEqualTo: _facultyUID)
                  .snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> subjects = [];

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            // Load custom subjects from Firestore
            final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
            // Sort client-side by createdAt desc to avoid composite index requirements.
            docs.sort((a, b) {
              final ad = a.data() as Map<String, dynamic>;
              final bd = b.data() as Map<String, dynamic>;
              final at = ad['createdAt'];
              final bt = bd['createdAt'];
              final aMs = at is Timestamp ? at.millisecondsSinceEpoch : 0;
              final bMs = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
              return bMs.compareTo(aMs);
            });

            subjects = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final iconIndex = data['icon'] as int? ?? 0;
              return {
                'label': data['label'] ?? 'Unnamed',
                'description': data['description'] ?? '',
                'icon': _availableIcons[
                    iconIndex < _availableIcons.length ? iconIndex : 0],
                'color': Color(data['color'] as int? ?? 0xFF2196F3),
                'facultyName': data['facultyName'] ?? 'Faculty',
              };
            }).toList();
                } else if (snapshot.hasError) {
            // Show error message
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text('Error loading subjects'),
                  ],
                ),
              ),
            );
          }

          // If no custom subjects, fall back to default subjects
                if (subjects.isEmpty && snapshot.connectionState !=
                    ConnectionState.waiting) {
                  subjects = _defaultSubjects;
                }

                final query = _searchQuery.trim().toLowerCase();
                final visibleSubjects = query.isEmpty
                    ? subjects
                    : subjects.where((subject) {
                        final label = (subject['label'] ?? '').toString().toLowerCase();
                        final description =
                            (subject['description'] ?? '').toString().toLowerCase();
                        return label.contains(query) || description.contains(query);
                      }).toList();

                if (snapshot.connectionState == ConnectionState.waiting &&
                    visibleSubjects.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryButton),
                    ),
                  );
                }

                if (visibleSubjects.isEmpty) {
                  return Center(
                    child: Text(
                      query.isEmpty ? 'No subjects found' : 'No matching subjects',
                      style: TextStyle(color: primaryBar.withOpacity(0.7)),
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.all(16),
                  child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 600 ? 3 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.8,
              ),
              itemCount: visibleSubjects.length,
              itemBuilder: (context, index) {
                final subject = visibleSubjects[index];
                return Card(
                  color: subject['color'].withOpacity(0.12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: Icon(subject['icon'],
                        color: subject['color'], size: 32),
                    title: Text(
                      subject['label'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryBar,
                      ),
                    ),
                    subtitle: Text(
                      subject['description'],
                      style: TextStyle(
                          color: primaryBar.withOpacity(0.7)),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FacultySubjectManage(subject: subject),
                        ),
                      );
                    },
                  ),
                );
              },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}