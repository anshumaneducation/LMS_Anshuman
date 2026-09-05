import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TakeQuizPage extends StatefulWidget {
  final String subject;
  final String quizId;
  final Map<String, dynamic> quizData;
  TakeQuizPage(
      {required this.subject, required this.quizId, required this.quizData});

  @override
  _TakeQuizPageState createState() => _TakeQuizPageState();
}

class _TakeQuizPageState extends State<TakeQuizPage> {
  Map<int, String> answers = {};
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    // Support both Firestore and local quiz formats
    final questions = widget.quizData['questions'] ??
        widget.quizData['sections']?['mcq'] ??
        [];
    return Scaffold(
      appBar: AppBar(title: Text(widget.quizData['title'] ?? 'Quiz')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.quizData['description'] ?? '',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, idx) {
                  final q = questions[idx];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Q${idx + 1}: ${q['question']}',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...List.generate((q['options'] ?? []).length,
                              (optIdx) {
                            final opt = q['options'][optIdx];
                            return RadioListTile<String>(
                              title: Text(opt),
                              value: opt,
                              groupValue: answers[idx],
                              onChanged: submitted
                                  ? null
                                  : (val) {
                                      setState(() {
                                        answers[idx] = val!;
                                      });
                                    },
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!submitted)
              ElevatedButton(
                child: Text('Submit'),
                onPressed: () {
                  setState(() {
                    submitted = true;
                  });
                  // TODO: Save student answers to Firestore if needed
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Quiz submitted!')));
                },
              ),
            if (submitted)
              Text('Thank you for submitting!',
                  style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
