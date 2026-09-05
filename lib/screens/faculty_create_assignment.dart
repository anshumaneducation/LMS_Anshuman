// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:stela_app/constants/colors.dart';
// import 'package:stela_app/screens/faculty_subjects_data.dart';

// class FacultyCreateAssignment extends StatefulWidget {
//   final Map<String, dynamic>? preselectedSubject;
//   const FacultyCreateAssignment({Key? key, this.preselectedSubject})
//       : super(key: key);

//   @override
//   _FacultyCreateAssignmentState createState() =>
//       _FacultyCreateAssignmentState();
// }

// class _FacultyCreateAssignmentState extends State<FacultyCreateAssignment>
//     with SingleTickerProviderStateMixin {
//   late Map<String, dynamic>? _selectedSubject;
//   final _formKey = GlobalKey<FormState>();
//   String _title = '';
//   String _description = '';
//   DateTime? _dueDate;
//   bool _loading = false;
//   String _searchQuery = '';
//   late List<Map<String, dynamic>> _allSubjects;
//   late String _facultyUID;
//   StreamSubscription<User?>? _authSub;

//   final List<IconData> _availableIcons = [
//     Icons.psychology,
//     Icons.cloud,
//     Icons.build,
//     Icons.network_check,
//     Icons.computer,
//     Icons.memory,
//     Icons.functions,
//     Icons.wifi,
//     Icons.science,
//     Icons.code,
//     Icons.storage,
//     Icons.security,
//     Icons.extension,
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _selectedSubject = widget.preselectedSubject;
//     _facultyUID = FirebaseAuth.instance.currentUser?.uid ?? '';
//     // Initialize with hardcoded subjects first
//     _allSubjects = List<Map<String, dynamic>>.from(facultySubjects);
//     // Then load Firestore subjects
//     _loadSubjects();

//     // In case auth isn't ready at init (common on web), reload once it is.
//     _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
//       final uid = user?.uid ?? '';
//       if (uid.isNotEmpty && uid != _facultyUID && mounted) {
//         setState(() {
//           _facultyUID = uid;
//         });
//         _loadSubjects();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _authSub?.cancel();
//     super.dispose();
//   }

//   Future<void> _loadSubjects() async {
//     try {
//       print('DEBUG: Loading subjects for facultyUID: $_facultyUID');

//       // Fetch Firestore subjects
//       final snapshot = await FirebaseFirestore.instance
//           .collection('subjects')
//           .where('facultyUID', isEqualTo: _facultyUID)
//           .get();

//       print(
//           'DEBUG: Firestore query returned ${snapshot.docs.length} custom subjects');

//       List<Map<String, dynamic>> updatedSubjects =
//           List<Map<String, dynamic>>.from(facultySubjects);
//       print(
//           'DEBUG: Starting with ${updatedSubjects.length} hardcoded subjects');

//       // Sort client-side by createdAt (descending) to avoid composite index requirements.
//       final docs =
//           List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(snapshot.docs);
//       docs.sort((a, b) {
//         final at = a.data()['createdAt'];
//         final bt = b.data()['createdAt'];
//         final aMs = at is Timestamp ? at.millisecondsSinceEpoch : 0;
//         final bMs = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
//         return bMs.compareTo(aMs);
//       });

//       for (var doc in docs) {
//         final data = doc.data();
//         final iconIndex = data['icon'] as int? ?? 0;

//         print('DEBUG: Adding custom subject: ${data['label']}');

//         final subjectMap = {
//           'label': data['label'] ?? 'Unnamed Subject',
//           'value': doc.id,
//           'description': data['description'] ?? '',
//           'category': data['category'] ?? 'Faculty Courses',
//           'icon': _availableIcons[
//               iconIndex < _availableIcons.length ? iconIndex : 0],
//           'color': Color(data['color'] as int? ?? 0xFF2196F3),
//           'id': doc.id,
//         };
//         updatedSubjects.add(subjectMap);
//       }

//       print('DEBUG: Total subjects after update: ${updatedSubjects.length}');

//       if (mounted) {
//         setState(() {
//           _allSubjects = updatedSubjects;
//         });
//       }
//     } catch (e) {
//       print('ERROR loading subjects: $e');
//       // Keep hardcoded subjects on error
//       if (mounted) {
//         setState(() {
//           _allSubjects = List<Map<String, dynamic>>.from(facultySubjects);
//         });
//       }
//     }
//   }

//   Future<void> _pickDueDate() async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _dueDate ?? now,
//       firstDate: now.subtract(Duration(days: 365)),
//       lastDate: now.add(Duration(days: 365 * 5)),
//     );
//     if (picked != null) setState(() => _dueDate = picked);
//   }

//   void _submit() {
//     if (!_formKey.currentState!.validate()) return;
//     if (_selectedSubject == null) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Please select a subject')));
//       return;
//     }

//     final uid = FirebaseAuth.instance.currentUser?.uid ?? _facultyUID;
//     if (uid.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content: Text('Please wait for login to finish, then try again.')),
//       );
//       return;
//     }

//     setState(() => _loading = true);

//     () async {
//       try {
//         final subjectId =
//             (_selectedSubject!['id'] ?? _selectedSubject!['value'] ?? '')
//                 .toString();
//         final subjectLabel =
//             (_selectedSubject!['label'] ?? subjectId).toString();
//         final subjectCategory =
//             (_selectedSubject!['category'] ?? '').toString();

//         final subjectColorRaw = _selectedSubject!['color'];
//         final int? subjectColorValue = subjectColorRaw is Color
//             ? subjectColorRaw.value
//             : subjectColorRaw is int
//                 ? subjectColorRaw
//                 : null;

//         await FirebaseFirestore.instance
//             .collection('subjects')
//             .doc(subjectId)
//             .collection('assessments')
//             .add({
//           'title': _title.trim(),
//           'description': _description.trim(),
//           'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
//           'createdAt': FieldValue.serverTimestamp(),
//           'updatedAt': FieldValue.serverTimestamp(), // Optional metadata
//           'status': 'active', // Optional metadata
//           'facultyUID': uid, // Optional metadata
//           'attachmentUrl': null, // Matches your schema layout
//           'subjectLabel': subjectLabel,
//           'subjectCategory': subjectCategory,
//           if (subjectColorValue != null) 'subjectColor': subjectColorValue,
//         });

//         if (!mounted) return;
//         setState(() => _loading = false);
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text('Assignment Created'),
//             content: Text('"${_title.trim()}" created for $subjectLabel.'),
//             actions: [
//               TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: Text('OK'))
//             ],
//           ),
//         );
//       } catch (e) {
//         if (!mounted) return;
//         setState(() => _loading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to create assignment: $e')),
//         );
//       }
//     }();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final query = _searchQuery.trim().toLowerCase();
//     final visibleSubjects = query.isEmpty
//         ? _allSubjects
//         : _allSubjects.where((subject) {
//             final label = (subject['label'] ?? '').toString().toLowerCase();
//             final category =
//                 (subject['category'] ?? '').toString().toLowerCase();
//             return label.contains(query) || category.contains(query);
//           }).toList();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_selectedSubject != null
//             ? 'Create Assignment - ${(_selectedSubject!['label'] ?? _selectedSubject!['value'])}'
//             : 'Create Assignment'),
//         backgroundColor: _selectedSubject != null
//             ? (_selectedSubject!['color'] ?? primaryBar)
//             : primaryBar,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Subject selector (grid-like compact list)
//               Text('Select Subject',
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: primaryBar)),
//               SizedBox(height: 12),
//               TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Search subjects',
//                   prefixIcon: Icon(Icons.search),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 onChanged: (query) {
//                   setState(() => _searchQuery = query);
//                 },
//               ),
//               SizedBox(height: 12),
//               Wrap(
//                 spacing: 12,
//                 runSpacing: 12,
//                 children: visibleSubjects.map((subject) {
//                   final bool isSelected = _selectedSubject != null &&
//                       _selectedSubject!['value'] == subject['value'];
//                   return ChoiceChip(
//                     label: Text(subject['label']),
//                     selected: isSelected,
//                     onSelected: (_) =>
//                         setState(() => _selectedSubject = subject),
//                     selectedColor: subject['color'],
//                     backgroundColor: Colors.grey[100],
//                     labelStyle: TextStyle(
//                         color: isSelected ? Colors.white : primaryBar),
//                   );
//                 }).toList(),
//               ),

//               SizedBox(height: 20),
//               Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     TextFormField(
//                       decoration: InputDecoration(
//                           hintText: 'Assignment Title',
//                           prefixIcon: Icon(Icons.title)),
//                       onChanged: (v) => _title = v,
//                       validator: (v) => v == null || v.trim().isEmpty
//                           ? 'Enter a title'
//                           : null,
//                     ),
//                     SizedBox(height: 12),
//                     TextFormField(
//                       decoration: InputDecoration(
//                           hintText: 'Description',
//                           prefixIcon: Icon(Icons.description)),
//                       maxLines: 4,
//                       onChanged: (v) => _description = v,
//                       validator: (v) => v == null || v.trim().isEmpty
//                           ? 'Enter a description'
//                           : null,
//                     ),
//                     SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(_dueDate == null
//                               ? 'No due date chosen'
//                               : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}'),
//                         ),
//                         TextButton.icon(
//                             onPressed: _pickDueDate,
//                             icon: Icon(Icons.calendar_today),
//                             label: Text('Pick Date')),
//                       ],
//                     ),
//                     SizedBox(height: 20),
//                     SizedBox(
//                       height: 48,
//                       child: ElevatedButton(
//                         onPressed: _loading ? null : _submit,
//                         style: ElevatedButton.styleFrom(
//                             backgroundColor: _selectedSubject != null
//                                 ? _selectedSubject!['color']
//                                 : primaryButton),
//                         child: _loading
//                             ? CircularProgressIndicator()
//                             : Text('Create Assignment',
//                                 style: TextStyle(fontWeight: FontWeight.bold)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stela_app/constants/colors.dart';
// REMOVED: Hardcoded faculty subjects data import

class FacultyCreateAssignment extends StatefulWidget {
  final Map<String, dynamic>? preselectedSubject;
  const FacultyCreateAssignment({Key? key, this.preselectedSubject})
      : super(key: key);

  @override
  _FacultyCreateAssignmentState createState() =>
      _FacultyCreateAssignmentState();
}

class _FacultyCreateAssignmentState extends State<FacultyCreateAssignment>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic>? _selectedSubject;
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  DateTime? _dueDate;
  bool _loading = false;
  String _searchQuery = '';
  late List<Map<String, dynamic>>
      _allSubjects; // Populated dynamically from Firestore
  late String _facultyUID;
  StreamSubscription<User?>? _authSub;

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
    _selectedSubject = widget.preselectedSubject;
    _facultyUID = FirebaseAuth.instance.currentUser?.uid ?? '';

    // CHANGED: Initialized with an empty list instead of hardcoded entries
    _allSubjects = [];
    _loadSubjects();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final uid = user?.uid ?? '';
      if (uid.isNotEmpty && uid != _facultyUID && mounted) {
        setState(() {
          _facultyUID = uid;
        });
        _loadSubjects();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      print('DEBUG: Loading subjects for facultyUID: $_facultyUID');

      final snapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .where('facultyUID', isEqualTo: _facultyUID)
          .get();

      print(
          'DEBUG: Firestore query returned ${snapshot.docs.length} custom subjects');

      // CHANGED: Clean initialization without hardcoded arrays
      List<Map<String, dynamic>> updatedSubjects = [];

      final docs =
          List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(snapshot.docs);
      docs.sort((a, b) {
        final at = a.data()['createdAt'];
        final bt = b.data()['createdAt'];
        final aMs = at is Timestamp ? at.millisecondsSinceEpoch : 0;
        final bMs = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
        return bMs.compareTo(aMs);
      });

      for (var doc in docs) {
        final data = doc.data();
        final iconIndex = data['icon'] as int? ?? 0;

        print('DEBUG: Adding custom subject: ${data['label']}');

        final subjectMap = {
          'label': data['label'] ?? 'Unnamed Subject',
          'value': doc.id,
          'description': data['description'] ?? '',
          'category': data['category'] ?? 'Faculty Courses',
          'icon': _availableIcons[
              iconIndex < _availableIcons.length ? iconIndex : 0],
          'color': Color(data['color'] as int? ?? 0xFF2196F3),
          'id': doc.id,
        };
        updatedSubjects.add(subjectMap);
      }

      if (mounted) {
        setState(() {
          _allSubjects = updatedSubjects;
        });
      }
    } catch (e) {
      print('ERROR loading subjects: $e');
      if (mounted) {
        setState(() {
          _allSubjects =
              []; // CHANGED: Graceful fallback to empty list on error
        });
      }
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(Duration(days: 365)),
      lastDate: now.add(Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select a subject')));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? _facultyUID;
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please wait for login to finish, then try again.')),
      );
      return;
    }

    setState(() => _loading = true);

    () async {
      try {
        final subjectId =
            (_selectedSubject!['id'] ?? _selectedSubject!['value'] ?? '')
                .toString();
        final subjectLabel =
            (_selectedSubject!['label'] ?? subjectId).toString();
        final subjectCategory =
            (_selectedSubject!['category'] ?? '').toString();

        final subjectColorRaw = _selectedSubject!['color'];
        final int? subjectColorValue = subjectColorRaw is Color
            ? subjectColorRaw.value
            : subjectColorRaw is int
                ? subjectColorRaw
                : null;

        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(subjectId)
            .collection('assessments')
            .add({
          'title': _title.trim(),
          'description': _description.trim(),
          'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'facultyUID': uid,
          'attachmentUrl': null,
          'subjectLabel': subjectLabel,
          'subjectCategory': subjectCategory,
          if (subjectColorValue != null) 'subjectColor': subjectColorValue,
        });

        if (!mounted) return;
        setState(() => _loading = false);

        showDialog(
          context: context,
          barrierDismissible:
              false, // Prevents closing by accidental side-tapping
          builder: (_) => AlertDialog(
            title: Text('Assignment Created'),
            content: Text('"${_title.trim()}" created for $subjectLabel.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(); // CHANGED: Closes the confirmation Alert Dialog
                  Navigator.of(context)
                      .pop(); // CHANGED: Pops the Creation View Page entirely
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create assignment: $e')),
        );
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final visibleSubjects = query.isEmpty
        ? _allSubjects
        : _allSubjects.where((subject) {
            final label = (subject['label'] ?? '').toString().toLowerCase();
            final category =
                (subject['category'] ?? '').toString().toLowerCase();
            return label.contains(query) || category.contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedSubject != null
            ? 'Create Assignment - ${(_selectedSubject!['label'] ?? _selectedSubject!['value'])}'
            : 'Create Assignment'),
        backgroundColor: _selectedSubject != null
            ? (_selectedSubject!['color'] ?? primaryBar)
            : primaryBar,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Select Subject',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBar)),
              SizedBox(height: 12),
              TextField(
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
              SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: visibleSubjects.map((subject) {
                  final bool isSelected = _selectedSubject != null &&
                      _selectedSubject!['value'] == subject['value'];
                  return ChoiceChip(
                    label: Text(subject['label']),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedSubject = subject),
                    selectedColor: subject['color'],
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : primaryBar),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                          hintText: 'Assignment Title',
                          prefixIcon: Icon(Icons.title)),
                      onChanged: (v) => _title = v,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a title'
                          : null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                          hintText: 'Description',
                          prefixIcon: Icon(Icons.description)),
                      maxLines: 4,
                      onChanged: (v) => _description = v,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a description'
                          : null,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(_dueDate == null
                              ? 'No due date chosen'
                              : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}'),
                        ),
                        TextButton.icon(
                            onPressed: _pickDueDate,
                            icon: Icon(Icons.calendar_today),
                            label: Text('Pick Date')),
                      ],
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedSubject != null
                                ? _selectedSubject!['color']
                                : primaryButton),
                        child: _loading
                            ? CircularProgressIndicator()
                            : Text('Create Assignment',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
