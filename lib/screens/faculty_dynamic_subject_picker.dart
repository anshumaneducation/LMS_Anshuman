import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stela_app/constants/colors.dart';
// import 'package:stela_app/screens/faculty_subjects_data.dart';

class FacultyDynamicSubjectPicker extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubjectTap;
  final String title;

  const FacultyDynamicSubjectPicker({
    Key? key,
    required this.onSubjectTap,
    required this.title,
  }) : super(key: key);

  @override
  _FacultyDynamicSubjectPickerState createState() =>
      _FacultyDynamicSubjectPickerState();
}

class _FacultyDynamicSubjectPickerState
    extends State<FacultyDynamicSubjectPicker> with TickerProviderStateMixin {
  late String _facultyUID;
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
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

  @override
  void initState() {
    super.initState();
    _facultyUID = FirebaseAuth.instance.currentUser?.uid ?? '';
    // On web (and sometimes mobile), currentUser can be null briefly during app start.
    // Subscribe so the subject stream updates as soon as auth state is ready.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final uid = user?.uid ?? '';
      if (uid.isNotEmpty && uid != _facultyUID && mounted) {
        setState(() {
          _facultyUID = uid;
        });
      }
    });
    _headerController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeInOut),
    );
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    int crossAxisCount;
    double childAspectRatio;

    if (width < 480) {
      crossAxisCount = 1;
      childAspectRatio = 3.4;
    } else if (width < 800) {
      crossAxisCount = 2;
      childAspectRatio = 2.2;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 2.2;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: primaryButton,
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryButton,
                        primaryButton.withOpacity(0.8),
                        Color(0xFF1565C0),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.school,
                                      size: 16,
                                      color: Colors.white.withOpacity(0.95),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Subject Picker',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.95),
                                        fontFamily: 'PTSerif',
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildHeaderTitle(widget.title, width),
                              const SizedBox(height: 8),
                              Text(
                                'Choose a subject to continue',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withOpacity(0.92),
                                  fontFamily: 'PTSerif',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('subjects')
                  .where('facultyUID', isEqualTo: _facultyUID)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Text(
                        'Error loading subjects: ${snapshot.error}',
                        style: TextStyle(color: primaryBar),
                      ),
                    ),
                  );
                }

                // Build combined subjects list: hardcoded + Firestore
                List<Map<String, dynamic>> allSubjects = [];

                // Add hardcoded subjects first
                // allSubjects.addAll(facultySubjects);

                // Add Firestore subjects if available
                if (snapshot.hasData && snapshot.data != null) {
                  final docs =
                      List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
                  // Sort client-side to avoid requiring a Firestore composite index.
                  docs.sort((a, b) {
                    final ad = a.data() as Map<String, dynamic>;
                    final bd = b.data() as Map<String, dynamic>;
                    final at = ad['createdAt'];
                    final bt = bd['createdAt'];
                    final aMs = at is Timestamp ? at.millisecondsSinceEpoch : 0;
                    final bMs = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
                    return bMs.compareTo(aMs);
                  });

                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final iconIndex = data['icon'] as int? ?? 0;

                    final subjectMap = {
                      'label': data['label'] ?? 'Unnamed Subject',
                      'value': doc.id,
                      'description': data['description'] ?? '',
                      'category': data['category'] ?? 'Faculty Courses',
                      'icon': _availableIcons[
                          iconIndex < _availableIcons.length ? iconIndex : 0],
                      'color': Color(data['color'] as int? ?? 0xFF2196F3),
                      'facultyName': data['facultyName'] ?? 'Faculty',
                      'id': doc.id,
                    };
                    allSubjects.add(subjectMap);
                  }
                }

                final query = _searchQuery.trim().toLowerCase();
                final filteredSubjects = query.isEmpty
                    ? allSubjects
                    : allSubjects.where((s) {
                        final label = (s['label'] ?? s['title'] ?? '')
                            .toString()
                            .toLowerCase();
                        final category =
                            (s['category'] ?? '').toString().toLowerCase();
                        return label.contains(query) ||
                            category.contains(query);
                      }).toList();

                if (filteredSubjects.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: primaryBar.withOpacity(0.3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            query.isEmpty
                                ? 'No subjects available'
                                : 'No matching subjects',
                            style: TextStyle(
                              fontSize: 16,
                              color: primaryBar.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search subjects',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                          onChanged: (query) {
                            setState(() => _searchQuery = query);
                          },
                        ),
                      ),
                    ),
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final subject = filteredSubjects[index];
                          return _buildSubjectCard(context, subject);
                        },
                        childCount: filteredSubjects.length,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, Map<String, dynamic> subject) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        // Call the callback after popping to ensure proper navigation
        Future.microtask(() => widget.onSubjectTap(subject));
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (subject['color'] as Color).withOpacity(0.08),
                (subject['color'] as Color).withOpacity(0.02),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: subject['color'] as Color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    subject['icon'] as IconData,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject['label'] ?? 'Subject',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryBar,
                          fontFamily: 'PTSerif-Bold',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        subject['description'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: primaryBar.withOpacity(0.6),
                          fontFamily: 'PTSerif',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryButton.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Select',
                    style: TextStyle(
                      color: primaryButton,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'PTSerif',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTitle(String title, double width) {
    final parts = _splitTitle(title);
    final headlineSize = width < 480 ? 26.0 : 34.0;
    final subSize = width < 480 ? 18.0 : 22.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: width < 480 ? 54 : 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: width < 480 ? 40 : 44,
          height: width < 480 ? 40 : 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Icon(
            Icons.menu_book,
            color: Colors.white.withOpacity(0.95),
            size: width < 480 ? 20 : 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                parts.item1,
                style: TextStyle(
                  fontSize: headlineSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'PTSerif-Bold',
                  height: 1.05,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (parts.item2.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  parts.item2,
                  style: TextStyle(
                    fontSize: subSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.95),
                    fontFamily: 'PTSerif',
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  ({String item1, String item2}) _splitTitle(String title) {
    final trimmed = title.trim();
    final lower = trimmed.toLowerCase();
    const prefix = 'select subject to ';
    if (lower.startsWith(prefix)) {
      final rest = trimmed.substring(prefix.length).trim();
      if (rest.isEmpty) return (item1: 'Select Subject', item2: '');
      return (item1: 'Select Subject', item2: 'to $rest');
    }

    // Fallback: keep the title as a single line.
    return (item1: trimmed, item2: '');
  }
}
