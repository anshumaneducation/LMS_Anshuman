import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  static bool _initialized = false;
  late DatabaseReference _quizzesRef;

  Future<void> initialize() async {
    if (!_initialized) {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }
      _quizzesRef = FirebaseDatabase.instance.ref().child('quizzes');
      _initialized = true;
      print('QuizService: Initialized successfully');
    }
  }

  /// Get all quizzes for a specific subject
  Future<List<Map<String, dynamic>>> getQuizzesForSubject(
      String subjectId) async {
    await initialize();

    // Map student subject IDs to faculty subject labels
    final String subjectKey = mapSubjectIdToFacultyKey(subjectId);
    print(
        'QuizService: Fetching quizzes for "$subjectId" using key "$subjectKey"');

    try {
      final snapshot = await _quizzesRef.child(subjectKey).get();
      List<Map<String, dynamic>> quizzes = [];

      if (snapshot.exists) {
        final dynamic snapshotValue = snapshot.value;
        if (snapshotValue is Map) {
          snapshotValue.forEach((unitKey, unitValue) {
            if (unitValue is Map) {
              // Format 1: Direct quiz under subject
              if (unitValue.containsKey('title') &&
                  unitValue.containsKey('questions')) {
                quizzes.add(_formatQuizFromData(unitKey, unitValue, 'Unit 1'));
              } else {
                // Format 2: Nested under units
                unitValue.forEach((quizKey, quizValue) {
                  if (quizValue is Map && quizValue.containsKey('title')) {
                    quizzes.add(_formatQuizFromData(
                        quizKey, quizValue, unitKey.toString()));
                  }
                });
              }
            }
          });
        }
      }

      print('QuizService: Found ${quizzes.length} quizzes');
      return quizzes;
    } catch (e) {
      print('QuizService Error: $e');
      return [];
    }
  }

  /// Helper to format raw Firebase data into a UI-friendly quiz map
  Map<String, dynamic> _formatQuizFromData(
      dynamic key, dynamic value, String parentUnit) {
    final parsedQuestions =
        _parseQuestions(value['facultyQuestions'] ?? value['questions']);

    return {
      'id': key.toString(),
      'title': value['title']?.toString() ?? '',
      'date': value['date']?.toString() ?? '',
      'unit': value['unit']?.toString() ?? parentUnit.replaceAll('_', ' '),
      'questions': parsedQuestions,
      'facultyQuestions': parsedQuestions,
      'duration': value['duration']?.toString() ??
          _calculateDuration(value['questions']),
      'totalMarks': value['totalMarks']?.toString() ?? '0',
      'pin': value['pin']?.toString() ?? '',
      'instructions': value['instructions']?.toString() ?? '',
      'isFromFaculty': true,
    };
  }

  /// Get all quizzes for all subjects
  Future<Map<String, List<Map<String, dynamic>>>> getAllQuizzes() async {
    await initialize();
    Map<String, List<Map<String, dynamic>>> allQuizzes = {};

    final List<String> subjects = [
      'artificial_intelligence_programming_tools',
      'cloud_computing',
      'compiler_design',
      'computer_networks',
      'computer_organization_and_architecture',
      'machine_learning',
      'wireless_networks',
      'internet_of_things',
      'theory_of_computation',
      'c_programming',
    ];

    for (String subjectId in subjects) {
      allQuizzes[subjectId] = await getQuizzesForSubject(subjectId);
    }
    return allQuizzes;
  }

  /// Map student subject ID to faculty subject key
  static String mapSubjectIdToFacultyKey(String subjectId) {
    final String normalized = subjectId
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
        .replaceAll(RegExp(r"^_+|_+$"), '');

    final Map<String, String> mappings = {
      'pydbasics': 'Artificial_Intelligence_-_Programming_Tools',
      'aipt': 'Artificial_Intelligence_-_Programming_Tools',
      'artificial_intelligence_programming_tools':
          'Artificial_Intelligence_-_Programming_Tools',
      'cloud': 'Cloud_Computing',
      'cloud_computing': 'Cloud_Computing',
      'compiler': 'Compiler_Design',
      'compiler_design': 'Compiler_Design',
      'networks': 'Computer_Networks',
      'computer_networks': 'Computer_Networks',
      'coa': 'Computer_Organization_and_Architecture',
      'computer_organization_and_architecture':
          'Computer_Organization_and_Architecture',
      'ml': 'Machine_Learning',
      'machine_learning': 'Machine_Learning',
      'wireless': 'Wireless_Networks',
      'wireless_networks': 'Wireless_Networks',
      'iot': 'Internet_of_Things',
      'internet_of_things': 'Internet_of_Things',
      'theory_of_computation': 'Theory_of_Computation',
      'toc': 'Theory_of_Computation',
      'c_programming': 'C_Programming',
      'c_programming_language': 'C_Programming',
    };

    if (mappings.containsKey(normalized)) {
      return mappings[normalized]!;
    }

    return normalized.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join('_');
  }

  /// Parse questions from Firebase data
  List<Map<String, dynamic>> _parseQuestions(dynamic questionsData) {
    List<Map<String, dynamic>> questions = [];
    if (questionsData is List) {
      for (var question in questionsData) {
        if (question is Map) {
          Map<String, dynamic> parsed = {};
          question.forEach((k, v) {
            if (v is List) {
              parsed[k.toString()] = v
                  .map((item) =>
                      item is Map ? Map<String, dynamic>.from(item) : item)
                  .toList();
            } else if (v is Map) {
              parsed[k.toString()] = Map<String, dynamic>.from(v);
            } else {
              parsed[k.toString()] = v;
            }
          });
          questions.add(parsed);
        }
      }
    }
    return questions;
  }

  String _calculateDuration(dynamic questionsData) {
    int count = (questionsData is List) ? questionsData.length : 0;
    return '${(count * 1.5).ceil()} min';
  }

  Future<List<Map<String, dynamic>>> getQuizzesForUnit(
      String subjectId, String unitName) async {
    await initialize();
    final String subjectKey = mapSubjectIdToFacultyKey(subjectId);
    final String unitKey = unitName.replaceAll(' ', '_');
    try {
      final snapshot = await _quizzesRef.child(subjectKey).child(unitKey).get();
      List<Map<String, dynamic>> quizzes = [];
      if (snapshot.exists && snapshot.value is Map) {
        (snapshot.value as Map).forEach((k, v) {
          if (v is Map && v.containsKey('title')) {
            quizzes.add(_formatQuizFromData(k, v, unitName));
          }
        });
      }
      return quizzes;
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getQuizzesStream(String subjectId) {
    final String subjectKey = mapSubjectIdToFacultyKey(subjectId);
    return _quizzesRef.child(subjectKey).onValue.map((event) {
      List<Map<String, dynamic>> quizzes = [];
      if (event.snapshot.exists && event.snapshot.value is Map) {
        (event.snapshot.value as Map).forEach((uk, uv) {
          if (uv is Map) {
            if (uv.containsKey('title')) {
              quizzes.add(_formatQuizFromData(uk, uv, 'Unit 1'));
            } else {
              uv.forEach((qk, qv) {
                if (qv is Map && qv.containsKey('title')) {
                  quizzes.add(_formatQuizFromData(qk, qv, uk.toString()));
                }
              });
            }
          }
        });
      }
      return quizzes;
    });
  }
}
