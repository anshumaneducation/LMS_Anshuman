import 'package:flutter/material.dart';
import '../models/quiz_model.dart';

/// Widget for adding/editing a coding question in the quiz creation form
class CodingQuestionForm extends StatefulWidget {
  final Map<String, dynamic>? initialQuestion;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const CodingQuestionForm({
    Key? key,
    this.initialQuestion,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<CodingQuestionForm> createState() => _CodingQuestionFormState();
}

class _CodingQuestionFormState extends State<CodingQuestionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _solutionCodeController;
  late ProgrammingLanguage _selectedLanguage;
  late int _marks;
  List<Map<String, dynamic>> _testCases = [];

  @override
  void initState() {
    super.initState();
    
    if (widget.initialQuestion != null) {
      _questionController = TextEditingController(text: widget.initialQuestion!['question']?.toString() ?? '');
      _solutionCodeController = TextEditingController(text: widget.initialQuestion!['solutionCode']?.toString() ?? '');
      
      String langStr = widget.initialQuestion!['language']?.toString().toLowerCase() ?? 'python';
      _selectedLanguage = ProgrammingLanguage.values.firstWhere(
        (e) => e.name == langStr,
        orElse: () => ProgrammingLanguage.python,
      );
      
      _marks = _toInt(widget.initialQuestion!['marks'], 1);
      
      if (widget.initialQuestion!['testCases'] != null && widget.initialQuestion!['testCases'] is List) {
        final List<dynamic> cases = widget.initialQuestion!['testCases'];
        _testCases = cases.map((c) {
          if (c is Map) {
            return {
              'input': c['input']?.toString() ?? '',
              'expectedOutput': c['expectedOutput']?.toString() ?? '',
              'isHidden': c['isHidden'] == true,
              'description': c['description']?.toString() ?? '',
            };
          }
          return {
            'input': '',
            'expectedOutput': '',
            'isHidden': false,
            'description': '',
          };
        }).toList();
      }
    } else {
      _questionController = TextEditingController();
      _solutionCodeController = TextEditingController();
      _selectedLanguage = ProgrammingLanguage.python;
      _marks = 1;
    }
  }

  int _toInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _solutionCodeController.dispose();
    super.dispose();
  }

  void _addTestCase() {
    setState(() {
      _testCases.add({
        'input': '',
        'expectedOutput': '',
        'isHidden': false,
        'description': '',
      });
    });
  }

  void _removeTestCase(int index) {
    setState(() {
      _testCases.removeAt(index);
    });
  }

  void _saveQuestion() {
    if (_formKey.currentState!.validate()) {
      if (_testCases.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add at least one test case')),
        );
        return;
      }

      final Map<String, dynamic> questionData = widget.initialQuestion != null ? Map<String, dynamic>.from(widget.initialQuestion!) : {};

      // Remove deprecated keys if present in older questions.
      questionData.remove('starterCode');
      questionData.remove('starterCodeByLanguage');
      questionData.remove('starterCodesByLanguage');
      questionData.remove('starterCodeMap');
      questionData.remove('timeLimit');
      questionData.remove('memoryLimit');
      
      questionData.addAll({
        'type': 'coding',
        'question': _questionController.text,
        'language': _selectedLanguage.name,
        'solutionCode': _solutionCodeController.text,
        'marks': _marks,
        'testCases': _testCases,
      });

      widget.onSave(questionData);
    } else {
      // Show snackbar if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the errors in the form before saving'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.initialQuestion != null ? 'Edit Coding Question' : 'Add Coding Question'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(Icons.close),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  TextFormField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      labelText: 'Question',
                      hintText: 'Enter the coding problem description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a question';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),
                  
                  // Language selection
                  DropdownButtonFormField<ProgrammingLanguage>(
                    value: _selectedLanguage,
                    decoration: InputDecoration(
                      labelText: 'Programming Language',
                      border: OutlineInputBorder(),
                    ),
                    items: ProgrammingLanguage.values.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Row(
                          children: [
                            Icon(_getLanguageIcon(lang), size: 20),
                            SizedBox(width: 8),
                            Text(getLanguageDisplayName(lang)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                      }
                    },
                  ),
                  
                  SizedBox(height: 16),

                  // Marks
                  TextFormField(
                    initialValue: _marks.toString(),
                    decoration: InputDecoration(
                      labelText: 'Marks',
                      hintText: 'e.g., 5, 10, 3',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final parsed = int.tryParse(value.trim());
                      if (parsed == null) return 'Invalid number';
                      if (parsed <= 0) return 'Marks must be > 0';
                      return null;
                    },
                    onChanged: (value) {
                      _marks = int.tryParse(value.trim()) ?? _marks;
                    },
                  ),

                  SizedBox(height: 16),
                  
                  SizedBox(height: 16),
                  
                  // Solution code
                  TextFormField(
                    controller: _solutionCodeController,
                    decoration: InputDecoration(
                      labelText: 'Solution Code',
                      hintText: 'Reference solution for evaluation',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 6,
                    style: TextStyle(fontFamily: 'monospace'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a solution';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Test cases section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Test Cases',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('Add Test Case'),
                        onPressed: _addTestCase,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Test cases list
                  ..._testCases.asMap().entries.map((entry) {
                    final index = entry.key;
                    final testCase = entry.value;
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Test Case ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: testCase['isHidden'] ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          _testCases[index]['isHidden'] = value ?? false;
                                        });
                                      },
                                    ),
                                    Text('Hidden'),
                                    SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeTestCase(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 8),
                            
                            TextFormField(
                              initialValue: testCase['description'],
                              decoration: InputDecoration(
                                labelText: 'Description (Optional)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                _testCases[index]['description'] = value;
                              },
                            ),
                            
                            SizedBox(height: 8),
                            
                            TextFormField(
                              initialValue: testCase['input'],
                              decoration: InputDecoration(
                                labelText: 'Input',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              maxLines: 2,
                              style: TextStyle(fontFamily: 'monospace'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Input required';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _testCases[index]['input'] = value;
                              },
                            ),
                            
                            SizedBox(height: 8),
                            
                            TextFormField(
                              initialValue: testCase['expectedOutput'],
                              decoration: InputDecoration(
                                labelText: 'Expected Output',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              maxLines: 2,
                              style: TextStyle(fontFamily: 'monospace'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Output required';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _testCases[index]['expectedOutput'] = value;
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  
                  SizedBox(height: 24),
                  
                  // Save button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.onCancel,
                        child: Text('Cancel'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saveQuestion,
                        child: Text('Save Question'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getLanguageIcon(ProgrammingLanguage lang) {
    switch (lang) {
      case ProgrammingLanguage.python:
        return Icons.code;
      case ProgrammingLanguage.java:
        return Icons.coffee;
      case ProgrammingLanguage.cpp:
        return Icons.code_outlined;
      case ProgrammingLanguage.javascript:
        return Icons.javascript;
      case ProgrammingLanguage.dart:
        return Icons.flutter_dash;
    }
  }
}
