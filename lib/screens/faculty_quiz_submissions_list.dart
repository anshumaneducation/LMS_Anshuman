import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../utils/download_helper.dart' as download_helper;

class FacultyQuizSubmissionsList extends StatelessWidget {
  final String subjectKey;
  final String subjectLabel;
  final String? quizId;
  final String? quizTitle;

  const FacultyQuizSubmissionsList({
    Key? key,
    required this.subjectKey,
    required this.subjectLabel,
    this.quizId,
    this.quizTitle,
  }) : super(key: key);

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream() {
    final coll = FirebaseFirestore.instance.collection('quiz_submissions');
    // Stream by subjectKey; we'll filter client-side by quizId/quizTitle to
    // include older docs that might be missing quizId but have quizTitle set.
    return coll.where('subjectKey', isEqualTo: subjectKey).snapshots();
  }

  String _fmtScore(num? v) {
    final d = (v ?? 0).toDouble();
    if (d % 1 == 0) return d.toInt().toString();
    return d.toStringAsFixed(2);
  }

  double _questionMaxMarks(Map<String, dynamic> question) {
    final type = (question['type'] ?? '').toString();
    if (type == 'coding' || type == 'subjective' || type == 'mcq' || type.isEmpty) {
      final v = question['marks'];
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is String) return double.tryParse(v) ?? 1.0;
    }
    return 1.0;
  }

  int? _asOptionIndex(dynamic value, List<String> options) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final idx = options.indexOf(value);
      if (idx >= 0) return idx;
      return int.tryParse(value);
    }
    return null;
  }

  bool _isMcqCorrect(Map<String, dynamic> question, dynamic userAnswer) {
    final options = List<String>.from(question['options'] ?? const <String>[]);
    final correctRaw = question['correct'];
    final correctIdx = _asOptionIndex(correctRaw, options);
    final userIdx = _asOptionIndex(userAnswer, options);
    if (correctIdx != null && userIdx != null) return correctIdx == userIdx;

    // Fallback for legacy shapes where values might be stored as strings.
    if (correctRaw != null && userAnswer != null) {
      return correctRaw.toString() == userAnswer.toString();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quizTitle != null && quizTitle!.isNotEmpty
            ? 'Submissions — ${quizTitle!}'
            : (quizId != null ? 'Submissions — $quizId' : 'All submissions — $subjectLabel')),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _buildStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text('No submissions'));

          // Filter client-side for the requested quiz. Some older submissions
          // may be missing quizId but have a quizTitle; include those as well.
          final filtered = docs.where((doc) {
            final d = doc.data();
            if (quizId != null && quizId!.isNotEmpty) {
              if ((d['quizId'] ?? '') == quizId) return true;
            }
            if (quizTitle != null && quizTitle!.isNotEmpty) {
              if ((d['quizTitle'] ?? '') == quizTitle) return true;
            }
            return false;
          }).toList();

          if (filtered.isEmpty) return Center(child: Text('No submissions for this quiz'));

          // sort by timestamp desc
          filtered.sort((a, b) {
            final ta = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tb = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tb.compareTo(ta);
          });

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final d = filtered[index].data();
              final studentName = d['studentName'] ?? 'Unknown';
              final qTitle = d['quizTitle'] ?? d['quizId'] ?? 'Quiz';
              final earnedMarks = (d['correctAnswers'] ?? d['correct'] ?? 0) as num;
              final totalMarks = (d['totalMarks'] ?? 0) as num;
              final timestamp = (d['timestamp'] as Timestamp?)?.toDate()?.toString().split('.')[0] ?? '';
                final isAutoTerminated = (d['autoTerminated'] == true) ||
                  (d['status']?.toString() == 'terminated_focus_loss');
                final statusText = isAutoTerminated ? 'AUTO-ENDED' : 'SUBMITTED';

              return Card(
                child: ListTile(
                  title: Text('$studentName — $qTitle'),
                  subtitle: Text('Marks: ${_fmtScore(earnedMarks)}${totalMarks > 0 ? ' / ${_fmtScore(totalMarks)}' : ''} • $statusText • $timestamp'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    tooltip: 'Delete submission',
                    onPressed: () async {
                      final docId = filtered[index].id;
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Delete submission'),
                          content: Text('Are you sure you want to delete this submission by $studentName? This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await FirebaseFirestore.instance.collection('quiz_submissions').doc(docId).delete();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission deleted')));
                        } catch (e) {
                          print('Error deleting submission $docId: $e');
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete submission: $e')));
                        }
                      }
                    },
                  ),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) {
                      final quizData = d['quizData'] as Map<String, dynamic>?;
                      final questions = (quizData != null && quizData['facultyQuestions'] != null)
                          ? List<Map<String, dynamic>>.from(quizData['facultyQuestions'])
                          : (quizData != null && quizData['questions'] != null)
                              ? List<Map<String, dynamic>>.from(quizData['questions'])
                              : <Map<String, dynamic>>[];

                      final answers = List<dynamic>.from(d['answers'] ?? []);
                      final codingAnswers = List<dynamic>.from(d['codingAnswers'] ?? []);
                      final subjectiveAnswers = List<dynamic>.from(d['subjectiveAnswers'] ?? []);
                        final subjectiveKeywordScores = (d['subjectiveKeywordScoreByQuestion'] as List?)
                            ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
                            .toList() ??
                          const <double>[];
                        final subjectiveMatchedKeywordsRaw = d['subjectiveMatchedKeywordsByQuestion'];
                        final subjectiveMatchedKeywordsByIndex = <int, List<String>>{};
                        if (subjectiveMatchedKeywordsRaw is List) {
                          for (int i = 0; i < subjectiveMatchedKeywordsRaw.length; i++) {
                            subjectiveMatchedKeywordsByIndex[i] =
                                List<String>.from((subjectiveMatchedKeywordsRaw[i] as List?) ?? const <String>[]);
                          }
                        } else if (subjectiveMatchedKeywordsRaw is Map) {
                          subjectiveMatchedKeywordsRaw.forEach((k, v) {
                            final idx = int.tryParse(k.toString());
                            if (idx != null) {
                              subjectiveMatchedKeywordsByIndex[idx] =
                                  List<String>.from((v as List?) ?? const <String>[]);
                            }
                          });
                        }
                        final subjectiveTotalKeywords = (d['subjectiveTotalKeywordsByQuestion'] as List?)
                            ?.map((e) => (e as num?)?.toInt() ?? 0)
                            .toList() ??
                          const <int>[];

                      final earnedMarks = (d['correctAnswers'] ?? d['correct'] ?? 0) as num;
                      final storedTotalMarks = (d['totalMarks'] ?? 0) as num;
                      final computedTotalMarks = questions.fold<double>(0, (sum, q) => sum + _questionMaxMarks(q));
                      final totalMarks = storedTotalMarks.toDouble() > 0 ? storedTotalMarks.toDouble() : computedTotalMarks;

                      final marksFromCorrect = (d['marksFromCorrect'] ?? d['marksFull'] ?? d['fullMarks'] ?? d['marksCorrect']) as num?;
                      final marksFromPartial = (d['marksFromPartial'] ?? d['partialMarks'] ?? d['marksPartial']) as num?;
                      final codingPassedTotal = (d['codingTestCasesPassed'] ?? d['codingPassedTotal'] ?? d['testCasesPassedTotal']) as num?;
                      final codingTotalTotal = (d['codingTestCasesTotal'] ?? d['codingTotalCases'] ?? d['testCasesTotal']) as num?;
                      final codingPassedByQuestion = (d['codingTestCasesPassedByQuestion'] as List?)?.map((e) => (e as num?)?.toInt() ?? 0).toList();
                      final codingTotalByQuestion = (d['codingTestCasesTotalByQuestion'] as List?)?.map((e) => (e as num?)?.toInt() ?? 0).toList();

                      // Fallback breakdown for older submissions that didn't store these fields.
                      final bool hasBreakdown = marksFromCorrect != null || marksFromPartial != null || (codingPassedTotal != null && codingTotalTotal != null);
                      double computedMcqFullMarks = 0;
                      final computedCodingTotalsByQuestion = <int, int>{};
                      if (!hasBreakdown && questions.isNotEmpty) {
                        for (int i = 0; i < questions.length; i++) {
                          final q = questions[i];
                          final type = (q['type'] ?? '').toString();
                          if (type == 'coding') {
                            final tcs = (q['testCases'] ?? []) as List;
                            computedCodingTotalsByQuestion[i] = tcs.length;
                            continue;
                          }
                          if (type == 'subjective') {
                            continue;
                          }
                          final ua = answers.length > i ? answers[i] : null;
                          if (_isMcqCorrect(q, ua)) {
                            computedMcqFullMarks += _questionMaxMarks(q);
                          }
                        }
                      }

                      return AlertDialog(
                        title: Text('$studentName — $qTitle'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Basic metadata
                                if (d['studentId'] != null) Text('Student ID: ${d['studentId']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                if (d['unit'] != null) Text('Unit: ${d['unit']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                SizedBox(height: 8),
                                // Questions
                                ...List.generate(questions.length, (index) {
                                  final q = questions[index];
                                  final type = (q['type'] ?? '').toString();
                                  final isCoding = type == 'coding';
                                  final isSubjective = type == 'subjective';
                                  
                                  if (isCoding) {
                                    final code = codingAnswers.length > index ? codingAnswers[index].toString() : '';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${index + 1}. [Coding] ${q['question'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold)),
                                          SizedBox(height: 6),
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[900],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              code.isEmpty ? '// No code submitted' : code,
                                              style: TextStyle(
                                                color: Colors.greenAccent,
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  if (isSubjective) {
                                    final ans = subjectiveAnswers.length > index ? subjectiveAnswers[index].toString() : '';
                                    final keywordScore =
                                        subjectiveKeywordScores.length > index ? subjectiveKeywordScores[index] : 0.0;
                                    final matched = subjectiveMatchedKeywordsByIndex[index] ?? const <String>[];
                                    final totalKeywords =
                                        subjectiveTotalKeywords.length > index ? subjectiveTotalKeywords[index] : 0;
                                    final maxMarks = _questionMaxMarks(q);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${index + 1}. [Subjective] ${q['question'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold)),
                                          SizedBox(height: 6),
                                          Text(
                                            'Auto score: ${_fmtScore(keywordScore)} / ${_fmtScore(maxMarks)}',
                                            style: TextStyle(fontSize: 12, color: Colors.blueGrey[700]),
                                          ),
                                          Text(
                                            totalKeywords > 0
                                                ? 'Keyword matches: ${matched.length}/$totalKeywords'
                                                : 'Keyword matches: no keywords configured',
                                            style: TextStyle(fontSize: 12, color: Colors.blueGrey[700]),
                                          ),
                                          if (matched.isNotEmpty)
                                            Text(
                                              'Matched keywords: ${matched.join(', ')}',
                                              style: TextStyle(fontSize: 12, color: Colors.green[700]),
                                            ),
                                          SizedBox(height: 6),
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.blueGrey.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.blueGrey.withOpacity(0.25)),
                                            ),
                                            child: Text(
                                              ans.trim().isEmpty ? '(No answer submitted)' : ans,
                                              style: TextStyle(fontSize: 12, color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

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
                                          final isUser = userAnswer == optIdx || userAnswer == opt;
                                          final isCorrect = correct == optIdx || correct == opt;
                                          Color bg = Colors.transparent;
                                          if (isCorrect) bg = Colors.green.withOpacity(0.12);
                                          else if (isUser && !isCorrect) bg = Colors.red.withOpacity(0.08);

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
                                SizedBox(height: 8),
                                // Footer metadata
                                Text('Marks: ${_fmtScore(earnedMarks)}${totalMarks > 0 ? ' / ${_fmtScore(totalMarks)}' : ''}'),
                                if (marksFromCorrect != null)
                                  Text('Full marks: ${_fmtScore(marksFromCorrect)}')
                                else if (computedMcqFullMarks > 0)
                                  Text('Full marks: ${_fmtScore(computedMcqFullMarks)}'),
                                if (marksFromPartial != null) Text('Partial marks: ${_fmtScore(marksFromPartial)}'),
                                ...() {
                                  final lines = <Widget>[];
                                  bool anyCodingQuestion = false;
                                  for (int i = 0; i < questions.length; i++) {
                                    final q = questions[i];
                                    if ((q['type'] ?? '').toString() != 'coding') continue;
                                    anyCodingQuestion = true;

                                    final int? passed = (codingPassedByQuestion != null && codingPassedByQuestion.length > i)
                                        ? codingPassedByQuestion[i]
                                        : null;
                                    final int? total = (codingTotalByQuestion != null && codingTotalByQuestion.length > i)
                                        ? codingTotalByQuestion[i]
                                        : computedCodingTotalsByQuestion[i];

                                    if (total == null || total == 0) {
                                      lines.add(Text('Coding Q${i + 1} test cases: 0/0 passed'));
                                    } else if (passed == null) {
                                      lines.add(Text('Coding Q${i + 1} test cases: —/$total passed'));
                                    } else {
                                      lines.add(Text('Coding Q${i + 1} test cases: $passed/$total passed'));
                                    }
                                  }

                                  // For submissions where questions are missing, fall back to aggregate totals if present.
                                  if (!anyCodingQuestion && codingPassedTotal != null && codingTotalTotal != null) {
                                    lines.add(Text('Coding test cases: ${codingPassedTotal.toInt()}/${codingTotalTotal.toInt()} passed'));
                                  }
                                  return lines;
                                }(),
                                if (d['timeTakenSeconds'] != null) Text('Time taken: ${d['timeTakenSeconds']} seconds'),
                                if (d['timestamp'] != null)
                                  Text('Submitted: ${((d['timestamp'] is Timestamp) ? (d['timestamp'] as Timestamp).toDate().toString() : d['timestamp'].toString())}'),
                              ],
                            ),
                          ),
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
