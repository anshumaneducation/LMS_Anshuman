import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stela_app/constants/colors.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:stela_app/screens/faculty_subjects_data.dart';

class SubmitAssignmentPage extends StatefulWidget {
  @override
  _SubmitAssignmentPageState createState() => _SubmitAssignmentPageState();
}

class _SubmitAssignmentPageState extends State<SubmitAssignmentPage> {
  bool _loadingSubjects = true;
  List<Map<String, dynamic>> _allSubjects = [];
  Map<String, dynamic>? _selectedSubject;
  String _subjectSearchQuery = '';
  Map<String, dynamic>? _selectedAssignment;
  final ScrollController _assignmentsListController = ScrollController();
  String? _fileName;
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;
  bool _submitted = false;
  String _submitStatus = '';
  String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  StreamSubscription<User?>? _authSub;
  Timer? _submitWatchdog;
  Map<String, dynamic>? _existingSubmission;
  bool _checkingPreviousSubmission = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final uid = user?.uid ?? '';
      if (uid != _uid && mounted) {
        setState(() => _uid = uid);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _submitWatchdog?.cancel();
    _assignmentsListController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      // final base = facultySubjects.map((s) {
      //   final value = (s['value'] ?? '').toString();
      //   return {
      //     ...s,
      //     'id': value,
      //   };
      // }).toList();

      final snapshot = await FirebaseFirestore.instance
          .collection('subjects')
          .get()
          .timeout(const Duration(seconds: 20));

      const availableIcons = <IconData>[
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

      final firestoreSubjects = snapshot.docs.map((doc) {
        final data = doc.data();
        final iconIndex = data['icon'] as int? ?? 0;
        return {
          'id': doc.id,
          'value': doc.id,
          'label': data['label'] ?? 'Unnamed Subject',
          'description': data['description'] ?? '',
          'category': data['category'] ?? 'Faculty Courses',
          'icon':
              availableIcons[iconIndex < availableIcons.length ? iconIndex : 0],
          'color': Color(data['color'] as int? ?? 0xFF2196F3),
          'units': const [
            {'name': 'Unit 1'},
            {'name': 'Unit 2'},
            {'name': 'Unit 3'},
            {'name': 'Unit 4'},
          ],
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _allSubjects = firestoreSubjects;
        _loadingSubjects = false;
      });
    } on TimeoutException catch (e) {
      debugPrint('Load subjects timed out: $e');
      if (!mounted) return;
      setState(() {
        _allSubjects = [];
        _loadingSubjects = false;
      });
    } catch (e) {
      debugPrint('Load subjects failed: $e');
      if (!mounted) return;
      setState(() {
        _allSubjects = [];
        _loadingSubjects = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        _fileName = _pickedFile!.name;
        _submitted = false;
      });
    }
  }

  Future<void> _loadPreviousSubmission() async {
    // if (_selectedAssignment == null || _uid.isEmpty) {
    //   return;
    // }
    if (_selectedAssignment == null || _uid.isEmpty) return;

    try {
      setState(() {
        _checkingPreviousSubmission = true;
      });

      // final assignmentId = (_selectedAssignment!['id'] ?? '').toString();
      final assignmentId = (_selectedAssignment!['id'] ?? '').toString();

      final snapshot = await FirebaseFirestore.instance
          .collection('assignmentSubmissions')
          // .where(
          //   'assignmentId',
          //   isEqualTo: assignmentId,
          // )
          // .where(
          //   'studentUID',
          //   isEqualTo: _uid,
          // )
          // .orderBy(
          //   'submittedAt',
          //   descending: true,
          // )
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentUID', isEqualTo: _uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _existingSubmission = {
          // 'id': snapshot.docs.first.id,
          'docId': snapshot.docs.first.id,
          ...snapshot.docs.first.data(),
        };
      } else {
        _existingSubmission = null;
      }

      if (mounted) {
        setState(() {
          _checkingPreviousSubmission = false;
        });
      }
    } catch (e) {
      // debugPrint(
      //   'Failed to load previous submission: $e',
      // );
      debugPrint('Failed to load previous submission: $e');
      if (mounted) {
        setState(() {
          _checkingPreviousSubmission = false;
        });
      }
    }
  }

  bool _canResubmit() {
    if (_selectedAssignment == null) return false;

    final due = _selectedAssignment!['dueDate'];

    if (due == null) return true;

    if (due is Timestamp) {
      return DateTime.now().isBefore(
        due.toDate(),
      );
    }

    return true;
  }

  String _formatDate(DateTime date) {
    return DateFormat(
      'dd MMM yyyy hh:mm a',
    ).format(date);
  }

  Future<void> _openPreviousSubmission() async {
    if (_existingSubmission == null) return;

    final url = (_existingSubmission!['fileUrl'] ?? '').toString();

    if (url.isEmpty) return;

    final uri = Uri.parse(url);

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _submitAssignment() async {
    if (_uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to submit assignments.')),
      );
      return;
    }
    if (_selectedAssignment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an assignment first.')),
      );
      return;
    }
    if (_pickedFile == null) return;
    final bytes = _pickedFile!.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to read file data. Please try again.')),
      );
      return;
    }
    if (bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Selected file is empty. Please choose another file.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitStatus = 'Starting...';
    });

    _submitWatchdog?.cancel();
    UploadTask? uploadTask;
    var lastActivityAt = DateTime.now();
    var stallWarned = false;
    void markActivity([String? status]) {
      lastActivityAt = DateTime.now();
      if (!mounted) return;
      if (status != null) {
        setState(() => _submitStatus = status);
      }
    }

    _submitWatchdog = Timer.periodic(const Duration(seconds: 10), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (!_isSubmitting) {
        t.cancel();
        return;
      }
      final idleFor = DateTime.now().difference(lastActivityAt);
      // On web, Firebase Storage may retry silently before emitting progress/errors
      // (permissions/network/proxy). Warn first, but don't cancel too early.
      if (idleFor > const Duration(seconds: 45) && !stallWarned) {
        stallWarned = true;
        lastActivityAt = DateTime.now();
        setState(() {
          _submitStatus = 'Still uploading...';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload is taking longer than usual. If it keeps waiting, check Chrome DevTools Console/Network for a Firebase Storage error (permission denied/blocked request/offline).',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 6),
          ),
        );
      }

      // Hard-stop only after a much longer stall; align with the upload timeout below.
      if (idleFor > const Duration(minutes: 2, seconds: 15)) {
        uploadTask?.cancel();
        setState(() {
          _isSubmitting = false;
          _submitStatus = '';
        });
        t.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Submission stalled (no progress for ${idleFor.inSeconds}s). This is usually due to Firebase Storage permissions, offline connectivity, or a blocked request. Please check the browser console/network logs for the exact error.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    try {
      // Force an auth token refresh up-front; Storage uploads can appear to hang if token retrieval is blocked.
      markActivity('Checking sign-in...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not signed in. Please sign in again and retry.');
      }
      await user.getIdToken(true).timeout(const Duration(seconds: 15));

      final assignmentId = (_selectedAssignment!['id'] ?? '').toString();
      final assignmentTitle = (_selectedAssignment!['title'] ?? '').toString();
      final subjectId = (_selectedAssignment!['subjectId'] ?? '').toString();
      final subjectLabel =
          (_selectedAssignment!['subjectLabel'] ?? '').toString();

      if (assignmentId.trim().isEmpty) {
        throw Exception(
            'Invalid assignment id. Please re-select the assignment and try again.');
      }

      final safeName = (_pickedFile!.name).replaceAll('/', '_');
      final filePath =
          'assignment_submissions/$assignmentId/$_uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final storageRef = FirebaseStorage.instance.ref().child(filePath);

      debugPrint(
          'Submitting assignment: uploading to Storage: $filePath (${bytes.length} bytes)');
      markActivity('Uploading...');
      uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(
            contentType: _pickedFile?.extension == 'pdf'
                ? 'application/pdf'
                : 'application/octet-stream'),
      );

      StreamSubscription<TaskSnapshot>? uploadSub;
      uploadSub = uploadTask.snapshotEvents.listen(
        (snapshot) {
          final total = snapshot.totalBytes;
          final transferred = snapshot.bytesTransferred;
          if (!mounted) return;
          lastActivityAt = DateTime.now();
          if (total > 0) {
            final pct = ((transferred / total) * 100).clamp(0, 100);
            setState(() {
              _submitStatus = 'Uploading... ${pct.toStringAsFixed(0)}%';
            });
          } else {
            setState(() {
              _submitStatus = 'Uploading...';
            });
          }
        },
        onError: (e) {
          debugPrint('Storage upload snapshotEvents error: $e');
          if (!mounted) return;
          if (_isSubmitting) {
            setState(() {
              _isSubmitting = false;
              _submitStatus = '';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );

      try {
        await uploadTask.timeout(const Duration(minutes: 2));
      } finally {
        await uploadSub.cancel();
      }

      markActivity('Finalizing upload...');

      final downloadUrl = await storageRef
          .getDownloadURL()
          .timeout(const Duration(seconds: 30));

      markActivity('Saving submission...');

      // await FirebaseFirestore.instance.collection('assignmentSubmissions').add({
      //   'assignmentId': assignmentId,
      //   'assignmentTitle': assignmentTitle,
      //   'subjectId': subjectId,
      //   'subjectLabel': subjectLabel,
      //   'studentUID': _uid,
      //   'fileName': _pickedFile!.name,
      //   'filePath': filePath,
      //   'fileUrl': downloadUrl,
      //   'submittedAt': FieldValue.serverTimestamp(),
      //   'status': 'submitted',
      // }).timeout(const Duration(seconds: 30));
      final submissionsRef =
          FirebaseFirestore.instance.collection('assignmentSubmissions');
      final existingDocs = await submissionsRef
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentUID', isEqualTo: _uid)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 30));

      if (existingDocs.docs.isNotEmpty) {
        final oldData = existingDocs.docs.first.data();
        final oldPath = (oldData['filePath'] ?? '').toString();

        if (oldPath.isNotEmpty) {
          try {
            await FirebaseStorage.instance.ref().child(oldPath).delete();
          } catch (_) {}
        }

        await submissionsRef.doc(existingDocs.docs.first.id).update({
          'fileName': _pickedFile!.name,
          'filePath': filePath,
          'fileUrl': downloadUrl,
          'submittedAt': FieldValue.serverTimestamp(),
          'status': 'resubmitted',
        }).timeout(const Duration(seconds: 30));
      } else {
        await submissionsRef.add({
          'assignmentId': assignmentId,
          'assignmentTitle': assignmentTitle,
          'subjectId': subjectId,
          'subjectLabel': subjectLabel,
          'studentUID': _uid,
          'fileName': _pickedFile!.name,
          'filePath': filePath,
          'fileUrl': downloadUrl,
          'submittedAt': FieldValue.serverTimestamp(),
          'status': 'submitted',
        }).timeout(const Duration(seconds: 30));
      }

      if (!mounted) return;
      await _loadPreviousSubmission();
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _submitted = true;
        _pickedFile = null;
        _fileName = null;
        _submitStatus = '';
      });
      _submitWatchdog?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assignment submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on TimeoutException catch (e) {
      debugPrint('Submission timeout: $e');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitStatus = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Upload is taking too long. Please check your internet or Storage permissions and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'FirebaseAuthException during submission: code=${e.code} message=${e.message}');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitStatus = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Auth error (${e.code}): ${e.message ?? ''} Please sign in again and retry.'
                  .trim()),
          backgroundColor: Colors.red,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint(
          'FirebaseException during submission: code=${e.code} message=${e.message}');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitStatus = '';
      });
      final code = e.code.toLowerCase();
      final hint = (code.contains('permission') ||
              code.contains('unauthorized'))
          ? 'Permission denied. Check Firestore/Storage rules and ensure the student is signed in.'
          : (code.contains('unavailable') ||
                  code.contains('network') ||
                  code.contains('retry'))
              ? 'Network/unavailable. Check internet connection and try again.'
              : 'Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Submission failed (${e.code}): ${e.message ?? ''} $hint'.trim()),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('Submission failed: $e');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitStatus = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _submitWatchdog?.cancel();
    }
  }

  List<Map<String, dynamic>> _normalizeAssignments(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    final visible = items
        .where((a) => (a['status'] ?? 'active').toString() == 'active')
        .toList();
    visible.sort((a, b) {
      final at = a['createdAt'];
      final bt = b['createdAt'];
      final aMs = at is Timestamp ? at.millisecondsSinceEpoch : 0;
      final bMs = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
      return bMs.compareTo(aMs);
    });
    return visible;
  }

  Stream<List<Map<String, dynamic>>> _assignmentsStreamForSubject(
      String subjectId) async* {
    // final query = FirebaseFirestore.instance
    //     .collection('assignments')
    //     .where('subjectId', isEqualTo: subjectId);
    final query = FirebaseFirestore.instance
        .collection('subjects')
        .doc(subjectId)
        .collection('assessments');

    // 1) One-shot fetch first: avoids infinite "waiting" when realtime listeners are blocked.
    try {
      final initial = await query.get().timeout(const Duration(seconds: 15));
      yield _normalizeAssignments(initial);
    } on TimeoutException catch (e) {
      debugPrint('Initial assignments get() timed out: $e');
      // Yield something so UI doesn't spin forever; snapshots() may still succeed later.
      yield const [];
    } on FirebaseException catch (e) {
      debugPrint(
          'Initial assignments get() FirebaseException: code=${e.code} message=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Initial assignments get() failed: $e');
      rethrow;
    }

    // 2) Then follow with realtime updates.
    // IMPORTANT: don't use Stream.timeout() here.
    // Firestore only emits when data changes, so a timeout would incorrectly
    // error out after N seconds even on a healthy connection.
    yield* query.snapshots().map(_normalizeAssignments);
  }

  Widget _buildSubjectPicker() {
    final query = _subjectSearchQuery.trim().toLowerCase();
    final visibleSubjects = query.isEmpty
        ? _allSubjects
        : _allSubjects.where((s) {
            final label = (s['label'] ?? '').toString().toLowerCase();
            final category = (s['category'] ?? '').toString().toLowerCase();
            return label.contains(query) || category.contains(query);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Select Subject',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBar,
              fontFamily: 'PTSerif-Bold',
            ),
          ),
        ),
        SizedBox(height: 10),
        if (_loadingSubjects)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: LinearProgressIndicator(),
          )
        else ...[
          TextField(
            decoration: InputDecoration(
              hintText: 'Search subjects',
              prefixIcon: Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (q) => setState(() => _subjectSearchQuery = q),
          ),
          SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 900
                    ? 4
                    : width >= 650
                        ? 3
                        : width >= 420
                            ? 2
                            : 1;

                if (visibleSubjects.isEmpty) {
                  return Center(child: Text('No subjects found.'));
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: crossAxisCount == 1 ? 4.6 : 2.4,
                  ),
                  itemCount: visibleSubjects.length,
                  itemBuilder: (context, index) {
                    final subject = visibleSubjects[index];
                    return _buildSubjectCard(subject);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final label = (subject['label'] ?? '').toString();
    final category = (subject['category'] ?? '').toString();
    final color =
        (subject['color'] is Color) ? subject['color'] as Color : primaryBar;
    final icon = subject['icon'] is IconData
        ? subject['icon'] as IconData
        : Icons.book_outlined;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubject = subject;
          _selectedAssignment = null;
          _pickedFile = null;
          _fileName = null;
          _submitted = false;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryBar.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: primaryBar.withOpacity(0.06),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.isEmpty ? 'Unnamed Subject' : label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'PTSerif-Bold',
                      fontSize: 14,
                      color: primaryBar,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    category.isEmpty ? 'Subject' : category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryBar.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueDateRaw =
        _selectedAssignment != null ? _selectedAssignment!['dueDate'] : null;
    DateTime? dueDate;
    if (dueDateRaw is Timestamp) {
      dueDate = dueDateRaw.toDate();
    }
    final isDeadlinePassed = _selectedAssignment != null &&
        dueDate != null &&
        DateTime.now().isAfter(dueDate);

    return Scaffold(
      appBar: AppBar(
        title:
            Text("Assignments", style: TextStyle(fontFamily: 'PTSerif-Bold')),
        backgroundColor: primaryBar,
        elevation: 0,
      ),
      backgroundColor: primaryWhite,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: _selectedSubject == null
              ? _buildSubjectPicker()
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (_selectedSubject!['label'] ?? 'Subject')
                                .toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'PTSerif-Bold',
                              fontSize: 16,
                              color: primaryBar,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedSubject = null;
                              _selectedAssignment = null;
                              _pickedFile = null;
                              _fileName = null;
                              _submitted = false;
                            });
                          },
                          icon: Icon(Icons.swap_horiz, color: primaryButton),
                          label: Text('Change Subject',
                              style: TextStyle(color: primaryButton)),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _assignmentsStreamForSubject(
                            (_selectedSubject!['id'] ??
                                    _selectedSubject!['value'])
                                .toString()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text(
                                    'Failed to load assignments: ${snapshot.error}'));
                          }

                          final items = snapshot.data ?? const [];
                          if (items.isEmpty) {
                            return Center(
                                child: Text(
                                    'No assignments uploaded for this subject.'));
                          }

                          return ListView(
                            controller: _assignmentsListController,
                            children: [
                              ...items.map((a) {
                                final isSelected =
                                    _selectedAssignment != null &&
                                        _selectedAssignment!['id'] == a['id'];
                                final assignmentId = (a['id'] ?? '').toString();
                                final title = (a['title'] ?? '').toString();
                                final description =
                                    (a['description'] ?? '').toString();
                                final trimmedDescription = description.trim();
                                final due = a['dueDate'];
                                final dueText = due is Timestamp
                                    ? due
                                        .toDate()
                                        .toLocal()
                                        .toString()
                                        .split(' ')[0]
                                    : 'No due date';

                                return Card(
                                  elevation: isSelected ? 2 : 1,
                                  child: ListTile(
                                    leading: Icon(Icons.assignment,
                                        color: primaryBar),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title.isEmpty
                                                ? 'Untitled Assignment'
                                                : title,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: (assignmentId.isEmpty ||
                                                  trimmedDescription.isEmpty)
                                              ? null
                                              : () async {
                                                  setState(() {
                                                    _selectedAssignment = a;
                                                    _pickedFile = null;
                                                    _fileName = null;
                                                    _submitted = false;
                                                    _existingSubmission = null;
                                                  });

                                                  await _loadPreviousSubmission();

                                                  // Scroll to the lower panel where the description is shown.
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback(
                                                          (_) {
                                                    if (!_assignmentsListController
                                                        .hasClients) return;
                                                    final target =
                                                        _assignmentsListController
                                                            .position
                                                            .maxScrollExtent;
                                                    _assignmentsListController
                                                        .animateTo(
                                                      target,
                                                      duration: const Duration(
                                                          milliseconds: 250),
                                                      curve: Curves.easeOut,
                                                    );
                                                  });
                                                },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            minimumSize: Size(0, 0),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text('View Description'),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Due: $dueText'),
                                      ],
                                    ),
                                    selected: isSelected,
                                    onTap: () async {
                                      setState(() {
                                        _selectedAssignment = a;
                                        _pickedFile = null;
                                        _fileName = null;
                                        _submitted = false;
                                        _existingSubmission = null;
                                      });
                                      await _loadPreviousSubmission();
                                    },
                                  ),
                                );
                              }),

                              // ==============visible only on selecting a assignment to submit
                              if (_selectedAssignment != null) ...[
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBar.withOpacity(0.08),
                                        blurRadius: 16,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.upload_file,
                                          size: 48, color: primaryButton),
                                      SizedBox(height: 18),
                                      Text(
                                        'Attach your assignment file',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'PTSerif-Bold',
                                          color: primaryBar,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        (_selectedAssignment!['title'] ?? '')
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: primaryBar.withOpacity(0.8),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      Builder(
                                        builder: (_) {
                                          final desc = (_selectedAssignment![
                                                      'description'] ??
                                                  '')
                                              .toString()
                                              .trim();

                                          if (desc.isEmpty)
                                            return SizedBox.shrink();

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 10),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Description',
                                                  style: TextStyle(
                                                    fontFamily: 'PTSerif-Bold',
                                                    fontSize: 13,
                                                    color: primaryBar,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  desc,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: primaryBar
                                                        .withOpacity(0.75),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      SizedBox(height: 16),
                                      if (_checkingPreviousSubmission)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: CircularProgressIndicator(),
                                        ),
                                      if (_existingSubmission != null) ...[
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(12),
                                          margin: EdgeInsets.only(bottom: 16),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  Colors.green.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.check_circle,
                                                      color: Colors.green),
                                                  SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Already Submitted',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'File: ${_existingSubmission!['fileName'] ?? ''}',
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Submitted At: ${((_existingSubmission!['submittedAt'] as Timestamp?)?.toDate().toLocal().toString() ?? '')}',
                                              ),
                                              SizedBox(height: 12),
                                              ElevatedButton.icon(
                                                onPressed: () async {
                                                  final url =
                                                      (_existingSubmission![
                                                                  'fileUrl'] ??
                                                              '')
                                                          .toString();
                                                  if (url.isEmpty) return;
                                                  await launchUrl(
                                                    Uri.parse(url),
                                                    mode: LaunchMode
                                                        .externalApplication,
                                                  );
                                                },
                                                icon: Icon(Icons.open_in_new),
                                                label:
                                                    Text('View Submitted File'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (isDeadlinePassed)
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(12),
                                          margin: EdgeInsets.only(bottom: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  Colors.red.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.lock_clock,
                                                  color: Colors.red),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'Submission deadline has passed. Re-upload is disabled.',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      OutlinedButton.icon(
                                        icon: Icon(Icons.attach_file,
                                            color: primaryButton),
                                        label: Text(
                                          'Choose File',
                                          style:
                                              TextStyle(color: primaryButton),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side:
                                              BorderSide(color: primaryButton),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                        ),
                                        onPressed:
                                            (_isSubmitting || isDeadlinePassed)
                                                ? null
                                                : _pickFile,
                                      ),
                                      if (_fileName != null) ...[
                                        SizedBox(height: 12),
                                        Text(
                                          'Selected: $_fileName',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: primaryBar.withOpacity(0.8),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: (_pickedFile != null &&
                                                  !_isSubmitting &&
                                                  !isDeadlinePassed)
                                              ? _submitAssignment
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryButton,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: _isSubmitting
                                              ? SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Text(
                                                  'Submit',
                                                  style: TextStyle(
                                                    fontFamily: 'PTSerif-Bold',
                                                    fontSize: 16,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      if (_isSubmitting &&
                                          _submitStatus.isNotEmpty) ...[
                                        SizedBox(height: 10),
                                        Text(
                                          _submitStatus,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: primaryBar.withOpacity(0.75),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                      if (_submitted)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 16.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Submitted!',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],

                              // ========
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
