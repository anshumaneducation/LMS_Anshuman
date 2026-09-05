import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import '../utils/download_helper.dart' as download_helper;
import 'faculty_quiz_submissions_list.dart';
import '../services/quiz_service.dart';

class FacultySubmissionsManage extends StatefulWidget {
  final Map<String, dynamic> subject;
  const FacultySubmissionsManage({required this.subject});

  @override
  State<FacultySubmissionsManage> createState() => _FacultySubmissionsManageState();
}

class _FacultySubmissionsManageState extends State<FacultySubmissionsManage> {
  String facultyId = '';

  bool _looksMaskedEnrollment(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    // Ignore placeholders like XXXXXXXX, XX XX XX, ******, ###, etc.
    // Some historical data includes separators or unicode multiply sign.
    final compact = v.replaceAll(RegExp(r'\s+'), '');
    if (compact.length < 4) return false;
    if (RegExp(r'^[Xx*#\-_.×]+$').hasMatch(compact)) return true;

    // Treat values that are mostly masking characters and have no digits as masked.
    final hasDigit = RegExp(r'\d').hasMatch(compact);
    final hasMaskChars = RegExp(r'[Xx*#×]').hasMatch(compact);
    final alphaNum = RegExp(r'[A-Za-z0-9]').allMatches(compact).length;
    final maskish = RegExp(r'[Xx*#\-_.×]').allMatches(compact).length;
    return !hasDigit && hasMaskChars && maskish >= alphaNum;
  }

  String _extractEnrollmentFromData(Map<String, dynamic> data) {
    final candidates = [
      data['enrollmentNumber'],
      data['enrollmentNo'],
      data['enrollment'],
      data['studentEnrollment'],
      data['studentEnrollmentNumber'],
      data['student_enrollment'],
      data['rollNo'],
      data['rollNumber'],
    ];
    for (final c in candidates) {
      final s = (c ?? '').toString().trim();
      if (s.isNotEmpty && !_looksMaskedEnrollment(s)) {
        return s;
      }
    }
    return '';
  }

  Future<Map<String, String>> _buildEnrollmentCache(Set<String> studentIds) async {
    final cache = <String, String>{};
    if (studentIds.isEmpty) return cache;

    try {
      final studentFutures = studentIds
          .map((id) => FirebaseFirestore.instance.collection('students').doc(id).get());
      final studentSnaps = await Future.wait(studentFutures);
      for (final s in studentSnaps) {
        if (!s.exists) continue;
        final sd = s.data();
        if (sd == null) continue;
        final enrollment = _extractEnrollmentFromData(sd);
        if (enrollment.isNotEmpty) {
          cache[s.id] = enrollment;
        }
      }
    } catch (e) {
      print('Error fetching student enrollments from students collection: $e');
    }

    // Legacy fallback for apps that keep profile fields in a generic users collection.
    final missingIds = studentIds.where((id) => !cache.containsKey(id)).toList();
    if (missingIds.isEmpty) return cache;

    try {
      final userFutures = missingIds
          .map((id) => FirebaseFirestore.instance.collection('users').doc(id).get());
      final userSnaps = await Future.wait(userFutures);
      for (final u in userSnaps) {
        if (!u.exists) continue;
        final ud = u.data();
        if (ud == null) continue;
        final enrollment = _extractEnrollmentFromData(ud);
        if (enrollment.isNotEmpty) {
          cache[u.id] = enrollment;
        }
      }
    } catch (e) {
      print('Error fetching student enrollments from users collection: $e');
    }

    return cache;
  }

  double _questionMaxMarks(Map<String, dynamic> question) {
    final type = (question['type'] ?? '').toString();
    if (type == 'coding') {
      final v = question['marks'];
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is String) return double.tryParse(v) ?? 1.0;
    }
    return 1.0;
  }

  double _computeTotalMarksFromSubmission(Map<String, dynamic> data) {
    final stored = data['totalMarks'];
    if (stored is num && stored.toDouble() > 0) return stored.toDouble();
    try {
      final quizData = data['quizData'] as Map<String, dynamic>?;
      if (quizData != null) {
        final questions = (quizData['facultyQuestions'] != null)
            ? List<Map<String, dynamic>>.from(quizData['facultyQuestions'])
            : (quizData['questions'] != null)
                ? List<Map<String, dynamic>>.from(quizData['questions'])
                : <Map<String, dynamic>>[];
        if (questions.isNotEmpty) {
          return questions.fold<double>(0, (sum, q) => sum + _questionMaxMarks(q));
        }
      }
    } catch (_) {}
    return 0.0;
  }

  // Normalize human-readable subject labels into the snake_case id used in submissions
  String _normalizeSubjectIdFromLabel(String label) {
    if (label.isEmpty) return '';
    // lower-case, replace any non-alphanumeric with underscore, collapse multiple underscores
    final s = label
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
        .replaceAll(RegExp(r"_+"), '_')
        .trim();
    // trim leading/trailing underscores
    return s.replaceAll(RegExp(r"^_+|_+$"), '');
  }

  @override
  void initState() {
    super.initState();
    facultyId = FirebaseAuth.instance.currentUser?.uid ?? '';
    print('FacultySubmissionsManage init: facultyId=$facultyId subject=${widget.subject['label'] ?? widget.subject['id']}');
  }

  

  @override
  Widget build(BuildContext context) {
    final subjectLabel = widget.subject['label'] ?? widget.subject['id'] ?? '';
    
    // Use the shared QuizService mapping to resolve the subject ID to the Realtime DB key
    final rawId = (widget.subject['id'] ?? widget.subject['value'] ?? widget.subject['label'] ?? '').toString().toLowerCase();
    final subjectKey = QuizService.mapSubjectIdToFacultyKey(rawId);

    return Scaffold(
      appBar: AppBar(
        title: Text("Submissions - $subjectLabel"),
        backgroundColor: widget.subject['color'],
        actions: [
          IconButton(
            tooltip: 'Export XLSX',
            icon: Icon(Icons.download),
            onPressed: () => _exportXlsx(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Query by subject on server, filter facultyId client-side to avoid whereIn/index issues
      // NOTE: removed server-side orderBy to avoid composite index requirement; we'll sort client-side.
      stream: FirebaseFirestore.instance
        .collection('quiz_submissions')
        .where(subjectKey.isNotEmpty ? 'subjectKey' : 'subjectLabel', isEqualTo: subjectKey.isNotEmpty ? subjectKey : subjectLabel)
        .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('Firestore submissions stream error: ${snapshot.error}');
              return Center(child: Text('Error loading submissions: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No submissions yet.'));
            }

            // Filter client-side: include submissions for this faculty or unassigned
            final allDocs = snapshot.data!.docs;
            final visibleDocs = allDocs.where((d) {
              final data = d.data();
              final fid = data['facultyId'] ?? '';
              return fid == facultyId || fid == '';
            }).toList();

            if (visibleDocs.isEmpty) {
              return Center(child: Text('No submissions for you yet.'));
            }

            // Group submissions by quizTitle (fallback to quizId)
            final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> groups = {};
            for (var d in visibleDocs) {
              final data = d.data();
              final key = (data['quizTitle'] ?? data['quizId'] ?? 'Unknown Quiz').toString();
              groups.putIfAbsent(key, () => []).add(d);
            }

            final groupEntries = groups.entries.toList();

            return ListView.builder(
              itemCount: groupEntries.length,
              itemBuilder: (context, index) {
                final entry = groupEntries[index];
                final quizTitle = entry.key;
                final list = entry.value;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(quizTitle, style: TextStyle(fontWeight: FontWeight.bold))),
                            Text('${list.length} submissions'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // Open list page filtered by this quiz id (use quizId from first doc)
                                final quizId = (list.first.data()['quizId'] ?? '').toString();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FacultyQuizSubmissionsList(
                                      subjectKey: subjectKey,
                                      subjectLabel: subjectLabel,
                                      quizId: quizId.isNotEmpty ? quizId : null,
                                      quizTitle: quizTitle,
                                    ),
                                  ),
                                );
                              },
                              child: Text('View submissions'),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                // Export only these docs
                                await _exportDocsToXlsx(list, quizTitle.replaceAll(' ', '_'));
                              },
                              child: Text('Export XLSX'),
                            ),
                          ],
                        ),
                      ],
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

  Future<void> _exportDocsToXlsx(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String filenameBase) async {
    try {
      if (docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No submissions to export')));
        return;
      }

      List<List<dynamic>> rows = [];
      // Header per user's request
      rows.add([
        'Timestamp',
        'Enrollment Number',
        'Name',
        'Marks Gained',
        'Total Marks',
        'Time Taken (s)',
        'Subject',
        'Unit',
      ]);

      // Build a cache of student enrollment numbers to avoid repeated reads.
      final Set<String> studentIds = {};
      for (var doc in docs) {
        final sid = (doc.data()['studentId'] ?? '').toString();
        if (sid.isNotEmpty) studentIds.add(sid);
      }
      final enrollmentCache = await _buildEnrollmentCache(studentIds);

      for (var doc in docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate().toIso8601String() ?? '';
      final studentId = data['studentId'] ?? '';
      final inlineEnrollment = _extractEnrollmentFromData(data);
      final cachedEnrollment =
        (studentId != '' ? (enrollmentCache[studentId] ?? '') : '');
      final enrollmentNumber = inlineEnrollment.isNotEmpty
        ? inlineEnrollment
        : cachedEnrollment;
        final studentName = data['studentName'] ?? '';
        final marksGained = data['correctAnswers'] ?? data['correct'] ?? 0;
        final totalMarks = _computeTotalMarksFromSubmission(data);
        final timeTaken = data['timeTakenSeconds']?.toString() ?? data['timeTaken']?.toString() ?? '';
        final subject = data['subjectLabel'] ?? '';
        final unit = data['unit'] ?? '';

        rows.add([
          timestamp,
          enrollmentNumber.isNotEmpty ? enrollmentNumber : studentId,
          studentName,
          marksGained.toString(),
          totalMarks,
          timeTaken,
          subject,
          unit,
        ]);
      }

      // Build XLSX workbook
      final excel = Excel.createExcel();
      final sheetName = 'Submissions';
      Sheet sheet = excel[sheetName];
      // Remove default sheet (e.g. Sheet1) if present so workbook only contains our 'Submissions' sheet
      try {
        final names = excel.sheets.keys.toList();
        for (final n in names) {
          if (n != sheetName) {
            excel.delete(n);
          }
        }
      } catch (_) {}
      CellValue? _toCellValue(dynamic v) {
        if (v == null) return null;
        final s = v.toString();
        final i = int.tryParse(s);
        if (i != null) return IntCellValue(i);
        final d = double.tryParse(s);
        if (d != null) return DoubleCellValue(d);
        return TextCellValue(s);
      }

      for (var r = 0; r < rows.length; r++) {
        final row = rows[r];
        sheet.appendRow(row.map((e) => _toCellValue(e)).toList());
      }
      final bytes = excel.encode();
      // Sanitize filename: remove problematic chars and collapse whitespace
      String _sanitize(String s) {
        return s
            .replaceAll(RegExp(r"[^A-Za-z0-9._ -]"), '')
            .replaceAll(RegExp(r"\s+"), '_')
            .replaceAll(RegExp(r"_+"), '_');
      }
      final safeName = _sanitize(filenameBase);
      final filename = '${safeName}.xlsx';
      // bytes may be null in some cases; guard
      final fileBytes = bytes ?? <int>[];
      final pathOrResult = await download_helper.downloadXlsxFile(filename, fileBytes);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('XLSX exported: $pathOrResult')));
    } catch (e) {
      print('Error exporting docs CSV: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _exportXlsx() async {
  final subjectLabel = widget.subject['label'] ?? widget.subject['id'] ?? '';
  // Prefer explicit subject id if present, otherwise normalize the human-readable label
  final rawSubjectId = (widget.subject['id'] ?? _normalizeSubjectIdFromLabel(widget.subject['label'] ?? '') ?? widget.subject['label'] ?? '').toString();
    String _mapSubjectIdToFacultyKey(String subjectId) {
      final Map<String, String> mappings = {
        'aipt': 'Artificial_Intelligence_-_Programming_Tools',
        'artificial_intelligence_programming_tools': 'Artificial_Intelligence_-_Programming_Tools',
        'cloud': 'Cloud_Computing',
        'cloud_computing': 'Cloud_Computing',
        'compiler': 'Compiler_Design',
        'compiler_design': 'Compiler_Design',
        'networks': 'Computer_Networks',
        'computer_networks': 'Computer_Networks',
        'coa': 'Computer_Organization_and_Architecture',
        'computer_organization_and_architecture': 'Computer_Organization_and_Architecture',
        'ml': 'Machine_Learning',
        'machine_learning': 'Machine_Learning',
        'wireless': 'Wireless_Networks',
        'wireless_networks': 'Wireless_Networks',
        'iot': 'Internet_of_Things',
        'internet_of_things': 'Internet_of_Things',
        'c_programming': 'C_Programming',
      };
      return mappings[subjectId] ?? subjectId.replaceAll('_', '_');
    }
  final subjectKey = _mapSubjectIdToFacultyKey(rawSubjectId.isNotEmpty ? rawSubjectId : _normalizeSubjectIdFromLabel(widget.subject['label'] ?? ''));
    try {
  Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('quiz_submissions');
      if (subjectKey.isNotEmpty) {
        query = query.where('subjectKey', isEqualTo: subjectKey);
      } else {
        query = query.where('subjectLabel', isEqualTo: subjectLabel);
      }

      final snap = await query.get();
      // Sort client-side by timestamp (newest first) to avoid requiring a composite Firestore index
      final docs = snap.docs.toList();
      docs.sort((a, b) {
        final ta = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      
      // Filter client-side to match the UI: include submissions owned by this faculty or unassigned
      final filteredDocs = docs.where((d) {
        final fid = d.data()['facultyId'] ?? '';
        return fid == facultyId || fid == '';
      }).toList();

  // Debug: how many docs fetched vs how many match the client-side filter
  print('Export CSV: subjectLabel="$subjectLabel" rawSubjectId="$rawSubjectId" subjectKey="$subjectKey" fetched=${docs.length} filtered=${filteredDocs.length} facultyId=$facultyId');

      if (filteredDocs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No submissions to export')));
        return;
      }

      List<List<dynamic>> rows = [];
      // Header per user's requested columns
      rows.add([
        'Timestamp',
        'Enrollment Number',
        'Name',
        'Marks Gained',
        'Total Marks',
        'Time Taken (s)',
        'Subject',
        'Unit',
      ]);

      // Build cache for student enrollment numbers.
      final Set<String> studentIds = {};
      for (var doc in filteredDocs) {
        final sid = (doc.data()['studentId'] ?? '').toString();
        if (sid.isNotEmpty) studentIds.add(sid);
      }
      final enrollmentCache = await _buildEnrollmentCache(studentIds);

      for (var doc in filteredDocs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate().toIso8601String() ?? '';
        final studentId = data['studentId'] ?? '';
        final studentName = data['studentName'] ?? '';
        final inlineEnrollment = _extractEnrollmentFromData(data);
        final cachedEnrollment =
          (studentId != '' ? (enrollmentCache[studentId] ?? '') : '');
        final enrollmentNumber = inlineEnrollment.isNotEmpty
          ? inlineEnrollment
          : cachedEnrollment;
        final marksGained = data['correctAnswers'] ?? data['correct'] ?? 0;
        final totalMarks = _computeTotalMarksFromSubmission(data);
        final timeTaken = data['timeTakenSeconds']?.toString() ?? data['timeTaken']?.toString() ?? '';
        final subject = data['subjectLabel'] ?? '';
        final unit = data['unit'] ?? '';

        rows.add([
          timestamp,
          enrollmentNumber.isNotEmpty ? enrollmentNumber : studentId,
          studentName,
          marksGained.toString(),
          totalMarks,
          timeTaken,
          subject,
          unit,
        ]);
      }

      // Create XLSX workbook
      final excel = Excel.createExcel();
      final sheetName = 'Submissions';
      Sheet sheet = excel[sheetName];
      // Remove default sheet (e.g. Sheet1) if present so workbook only contains our 'Submissions' sheet
      try {
        final names = excel.sheets.keys.toList();
        for (final n in names) {
          if (n != sheetName) {
            excel.delete(n);
          }
        }
      } catch (_) {}
      CellValue? _toCellValue2(dynamic v) {
        if (v == null) return null;
        final s = v.toString();
        final i = int.tryParse(s);
        if (i != null) return IntCellValue(i);
        final d = double.tryParse(s);
        if (d != null) return DoubleCellValue(d);
        return TextCellValue(s);
      }

      for (var r = 0; r < rows.length; r++) {
        final row = rows[r];
        sheet.appendRow(row.map((e) => _toCellValue2(e)).toList());
      }
      final bytes = excel.encode();

      try {
    // Use helper which handles web vs IO platforms
    final filename = 'submissions_${subjectLabel.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
  final pathOrResult = await download_helper.downloadXlsxFile(filename, bytes ?? <int>[]);
    // On IO platforms pathOrResult is a filesystem path, on web it's a download marker
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('XLSX exported: $pathOrResult')));
        // If we got a file path, offer to copy it
        if (!pathOrResult.startsWith('downloaded:')) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('XLSX Exported'),
              content: SelectableText(pathOrResult),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: pathOrResult));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Path copied to clipboard')));
                  },
                  child: Text('Copy Path'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        print('Error exporting XLSX (write/download): $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } catch (e) {
        print('Error exporting XLSX: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  

  void _showSubmissionDetails(String docId, Map<String, dynamic> data) {
    final quizData = data['quizData'] as Map<String, dynamic>?;
    final questions = (quizData != null && quizData['facultyQuestions'] != null)
        ? List<Map<String, dynamic>>.from(quizData['facultyQuestions'])
        : (quizData != null && quizData['questions'] != null)
            ? List<Map<String, dynamic>>.from(quizData['questions'])
            : <Map<String, dynamic>>[];

    final answers = List<dynamic>.from(data['answers'] ?? []);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${data['studentName'] ?? 'Student'} — ${data['quizTitle'] ?? 'Quiz'}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(questions.length, (index) {
                final q = questions[index];
                final userAnswer = answers.length > index ? answers[index] : null;
                final correct = q['correct'];
                final options = List<String>.from(q['options'] ?? []);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${index + 1}. ${q['question'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      ...List.generate(options.length, (optIdx) {
                        final opt = options[optIdx];
                        final isUser = userAnswer == optIdx;
                        final isCorrect = correct == optIdx;
                        Color bg = Colors.transparent;
                        if (isCorrect) bg = Colors.green.withOpacity(0.15);
                        else if (isUser && !isCorrect) bg = Colors.red.withOpacity(0.12);

                        return Container(
                          margin: EdgeInsets.only(bottom: 6),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Text('${String.fromCharCode(65 + optIdx)}. ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(opt)),
                              if (isCorrect)
                                Icon(Icons.check_circle, color: Colors.green, size: 18)
                              else if (isUser && !isCorrect)
                                Icon(Icons.cancel, color: Colors.red, size: 18),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }
}