import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/screens/subject_detail.dart';
import 'package:stela_app/services/quiz_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stela_app/widgets/code_editor_widget.dart';
import 'package:stela_app/models/quiz_model.dart';

/// Clean, single-file quizzes implementation.
/// Exposes `QuizzesScreen` as the main entry point for the Quizzes route.
class QuizzesScreen extends StatefulWidget {
  static const String routeName = '/quizzes';

  @override
  _QuizzesScreenState createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final QuizService _quizService = QuizService();
  Map<String, List<Map<String, dynamic>>> _facultyQuizzes = {};
  bool _loadingFacultyQuizzes = true;

  List<Map<String, dynamic>> _allSubjects = [];

  // static const List<Map<String, dynamic>> _staticSubjects = [
  //   {
  //     'id': 'artificial_intelligence_programming_tools',
  //     'title': 'Artificial Intelligence - Programming Tools',
  //     'icon': Icons.psychology,
  //     'color': Colors.orange,
  //     'category': 'AI & Data',
  //     'units': [
  //       {'name': 'Unit 1', 'topics': ['Introduction to AI', 'Python Basics', 'Data Structures']},
  //       {'name': 'Unit 2', 'topics': ['Machine Learning Fundamentals', 'Supervised Learning', 'Algorithms']},
  //       {'name': 'Unit 3', 'topics': ['Neural Networks', 'Deep Learning', 'TensorFlow']},
  //       {'name': 'Unit 4', 'topics': ['Natural Language Processing', 'Computer Vision', 'AI Applications']}
  //     ]
  //   },
  //   {
  //     'id': 'cloud_computing',
  //     'title': 'Cloud Computing',
  //     'icon': Icons.cloud,
  //     'color': Colors.blue,
  //     'category': 'Engineering',
  //     'units': [
  //       {'name': 'Unit 1', 'topics': ['Cloud Fundamentals', 'Service Models', 'Deployment Models']},
  //       {'name': 'Unit 2', 'topics': ['AWS Services', 'EC2', 'S3 Storage']},
  //       {'name': 'Unit 3', 'topics': ['Azure Platform', 'Google Cloud', 'Multi-cloud Strategy']},
  //       {'name': 'Unit 4', 'topics': ['Security', 'Monitoring', 'Cost Optimization']}
  //     ]
  //   },
  //   {
  //     'id': 'compiler_design',
  //     'title': 'Compiler Design',
  //     'icon': Icons.build,
  //     'color': Colors.redAccent,
  //     'category': 'Core Systems',
  //     'units': [
  //       {'name': 'Unit 1', 'topics': ['Lexical Analysis', 'Tokens', 'Regular Expressions']},
  //       {'name': 'Unit 2', 'topics': ['Syntax Analysis', 'Parsing', 'Grammar']},
  //       {'name': 'Unit 3', 'topics': ['Semantic Analysis', 'Symbol Tables', 'Type Checking']},
  //       {'name': 'Unit 4', 'topics': ['Code Generation', 'Optimization', 'Runtime Environment']}
  //     ]
  //   },
  //   {
  //     'id': 'computer_networks',
  //     'title': 'Computer Networks',
  //     'icon': Icons.network_check,
  //     'color': Colors.lightBlue,
  //     'category': 'Networking',
  //     'units': [
  //       {'name': 'Unit 1', 'topics': ['Network Basics', 'OSI Model', 'TCP/IP']},
  //       {'name': 'Unit 2', 'topics': ['Data Link Layer', 'Ethernet', 'Switching']},
  //       {'name': 'Unit 3', 'topics': ['Network Layer', 'Routing', 'IP Addressing']},
  //       {'name': 'Unit 4', 'topics': ['Transport Layer', 'Application Layer', 'Network Security']}
  //     ]
  //   },
  //   {
  //     'id': 'computer_organization_and_architecture',
  //     'title': 'Computer Organization and Architecture',
  //     'icon': Icons.computer,
  //     'color': Colors.green,
  //     'category': 'Core Systems',
  //     'units': [
  //       {'name': 'Unit 1', 'topics': ['Basic Computer Organization', 'CPU', 'Memory']},
  //       {'name': 'Unit 2', 'topics': ['Instruction Set Architecture', 'RISC vs CISC', 'Assembly Language']},
  //       {'name': 'Unit 3', 'topics': ['Pipeline Processing', 'Cache Memory', 'Virtual Memory']},
  //       {'name': 'Unit 4', 'topics': ['I/O Organization', 'Multiprocessors', 'Performance Evaluation']}
  //     ]
  //   },
  //   {
  //     'id': 'machine_learning',
  //     'title': 'Machine Learning',
  //     'icon': Icons.memory,
  //     'color': Colors.deepPurple,
  //     'category': 'AI & Data',
  //     'units': [
  //       {'name': 'Unit 1', 'topics': ['ML Introduction', 'Types of Learning', 'Data Preprocessing']},
  //       {'name': 'Unit 2', 'topics': ['Supervised Learning', 'Classification', 'Regression']},
  //       {'name': 'Unit 3', 'topics': ['Unsupervised Learning', 'Clustering', 'Dimensionality Reduction']},
  //       {'name': 'Unit 4', 'topics': ['Deep Learning', 'Neural Networks', 'Model Evaluation']}
  //     ]
  //   },
  //   {
  //     'id': 'theory_of_computation',
  //     'title': 'Theory of Computation',
  //     'icon': Icons.functions,
  //     'color': Colors.indigo,
  //     'category': 'Core Systems',
  //     'units': [
  //       {'name': 'Unit 1', 'topics': ['Automata Theory', 'Finite Automata', 'Regular Languages']},
  //       {'name': 'Unit 2', 'topics': ['Context-Free Languages', 'Pushdown Automata', 'Parsing']},
  //       {'name': 'Unit 3', 'topics': ['Turing Machines', 'Decidability', 'Reducibility']},
  //       {'name': 'Unit 4', 'topics': ['Complexity Theory', 'P vs NP', 'Approximation Algorithms']},
  //     ]
  //   },
  //   {
  //     'id': 'wireless_networks',
  //     'title': 'Wireless Networks',
  //     'icon': Icons.wifi,
  //     'color': Colors.cyan,
  //     'category': 'Networking',
  //     'units': [
  //       {'name': 'Unit 1', 'topics': ['Wireless Fundamentals', 'Radio Waves', 'Antennas']},
  //       {'name': 'Unit 2', 'topics': ['WiFi Standards', '802.11', 'Access Points']},
  //       {'name': 'Unit 3', 'topics': ['Cellular Networks', '4G/5G', 'Mobile Communication']},
  //       {'name': 'Unit 4', 'topics': ['Bluetooth', 'IoT Protocols', 'Network Security']}
  //     ]
  //   },
  //   {
  //     'id': 'internet_of_things',
  //     'title': 'Internet of Things',
  //     'icon': Icons.sensors,
  //     'color': Colors.deepOrange,
  //     'category': 'Engineering',
  //     'units': [
  //       {'name': 'Unit 1', 'topics': ['IoT Introduction', 'Sensors', 'Actuators']},
  //       {'name': 'Unit 2', 'topics': ['Communication Protocols', 'MQTT', 'CoAP']},
  //       {'name': 'Unit 3', 'topics': ['IoT Platforms', 'Cloud Integration', 'Data Analytics']},
  //       {'name': 'Unit 4', 'topics': ['Security', 'Edge Computing', 'IoT Applications']}
  //       ,{'name': 'IOT workshop', 'topics': ['Hands-on Projects', 'Device Setup', 'Practical Implementations']}
  //     ]
  //   },
  //   {
  //     'id': 'c_programming',
  //     'title': 'C Programming',
  //     'icon': Icons.code,
  //     'color': Colors.blueGrey,
  //     'category': 'Programming',
  //     'units': [
  //       {'name': 'Unit 1', 'topics': ['C Basics', 'Variables', 'Data Types']},
  //       {'name': 'Unit 2', 'topics': ['Control Structures', 'Loops', 'Functions']},
  //       {'name': 'Unit 3', 'topics': ['Arrays', 'Pointers', 'Strings']},
  //       {'name': 'Unit 4', 'topics': ['Structures', 'File Handling', 'Dynamic Memory']}
  //     ]
  //   },
  // ];

  // final List<String> categories = ['All', 'AI & Data', 'Engineering', 'Core Systems', 'Networking', 'Programming', 'Faculty Courses'];
  List<String> get categories {
    final dynamicCategories = _allSubjects
        .map((s) => (s['category'] ?? 'General').toString())
        .toSet()
        .toList();

    dynamicCategories.sort();

    return ['All', ...dynamicCategories];
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // _allSubjects = List<Map<String, dynamic>>.from(_staticSubjects);
    _loadAllSubjectsAndQuizzes();
  }

  Future<void> _loadAllSubjectsAndQuizzes() async {
    await _loadFirestoreSubjects();
    await _loadFacultyQuizzes();
  }

  Future<void> _loadFirestoreSubjects() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('subjects').get();

      final firestoreSubjects = snapshot.docs.map((doc) {
        final data = doc.data();
        final iconIndex = data['icon'] as int? ?? 0;
        final List<IconData> availableIcons = const [
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

        return {
          'id': doc.id,
          'title': data['label'] ?? 'Unnamed Subject',
          'label': data['label'] ?? 'Unnamed Subject',
          'description': data['description'] ?? '',
          // Keep student quiz filter predictable for custom subjects.
          // 'category': 'Faculty Courses',
          'category': data['category'] ?? 'General',
          'icon':
              availableIcons[iconIndex < availableIcons.length ? iconIndex : 0],
          'color': Color(data['color'] as int? ?? 0xFF2196F3),
          // Provide a minimal units structure so SubjectDetailScreen works.
          'units': const [
            {
              'name': 'Unit 1',
              'topics': ['Faculty Created Content']
            },
            {
              'name': 'Unit 2',
              'topics': ['Faculty Created Content']
            },
            {
              'name': 'Unit 3',
              'topics': ['Faculty Created Content']
            },
            {
              'name': 'Unit 4',
              'topics': ['Faculty Created Content']
            },
          ],
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _allSubjects = firestoreSubjects;
      });
    } catch (e) {
      print('Error loading Firestore subjects for quizzes: $e');
    }
  }

  Future<void> _loadFacultyQuizzes() async {
    try {
      final Map<String, List<Map<String, dynamic>>> facultyQuizzes = {};
      // Load quizzes for every available subject (static + Firestore).
      for (final subject in _allSubjects) {
        final subjectId = (subject['id'] ?? '').toString();
        if (subjectId.isEmpty) continue;
        facultyQuizzes[subjectId] =
            await _quizService.getQuizzesForSubject(subjectId);
      }

      if (!mounted) return;
      setState(() {
        _facultyQuizzes = facultyQuizzes;
        _loadingFacultyQuizzes = false;
      });
    } catch (e) {
      print('Error loading faculty quizzes: $e');
      setState(() {
        _loadingFacultyQuizzes = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredSubjects {
    List<Map<String, dynamic>> updatedSubjects = _mergeWithFacultyQuizzes();

    if (_selectedCategory != 'All') {
      updatedSubjects = updatedSubjects
          .where((subject) => subject['category'] == _selectedCategory)
          .toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      updatedSubjects = updatedSubjects.where((subject) {
        final title = (subject['title'] ?? '').toString().toLowerCase();
        final category = (subject['category'] ?? '').toString().toLowerCase();
        return title.contains(query) || category.contains(query);
      }).toList();
    }

    return updatedSubjects;
  }

  List<Map<String, dynamic>> _mergeWithFacultyQuizzes() {
    List<Map<String, dynamic>> updatedSubjects = [];

    for (var subject in _allSubjects) {
      Map<String, dynamic> updatedSubject = Map<String, dynamic>.from(subject);
      String subjectId = subject['id'];

      // Get faculty quizzes for this subject
      List<Map<String, dynamic>> facultyQuizzes =
          _facultyQuizzes[subjectId] ?? [];

      // Create a deep copy of units to make them modifiable
      List<Map<String, dynamic>> units = [];
      for (var unit in (updatedSubject['units'] ?? [])) {
        // Start with clean units (no static quizzes)
        Map<String, dynamic> cleanUnit = {
          'name': unit['name'],
          'topics': unit['topics'],
          'quizzes': [], // Initialize with empty quizzes array
        };
        units.add(cleanUnit);
      }

      if (facultyQuizzes.isNotEmpty) {
        // Group faculty quizzes by unit
        Map<String, List<Map<String, dynamic>>> quizzesByUnit = {};
        for (var quiz in facultyQuizzes) {
          String unitName = quiz['unit'] ?? 'Unit 1';
          if (!quizzesByUnit.containsKey(unitName)) {
            quizzesByUnit[unitName] = [];
          }

          // Convert to expected format
          quizzesByUnit[unitName]!.add({
            'name': quiz['title'],
            'title': quiz['title'],
            'questions': quiz['questions']?.length ?? 0,
            'duration': quiz['duration'],
            'id': quiz['id'],
            'isFromFaculty': true,
            'date': quiz['date'],
            'unit': quiz['unit'],
            'facultyQuestions': quiz['questions'], // Store full question data
          });
        }

        // Add faculty quizzes to the corresponding units
        for (int i = 0; i < units.length; i++) {
          String unitName = units[i]['name'];
          if (quizzesByUnit.containsKey(unitName)) {
            units[i]['quizzes'] = quizzesByUnit[unitName]!;

            // Remove from the map since we've processed it
            quizzesByUnit.remove(unitName);
          }
        }

        // Create new units for any remaining faculty quizzes that don't match existing units
        quizzesByUnit.forEach((unitName, quizzes) {
          units.add({
            'name': unitName,
            'topics': ['Faculty Created Content'],
            'quizzes': quizzes,
            'isFacultyUnit': true,
          });
        });
      }

      updatedSubject['units'] = units;
      updatedSubjects.add(updatedSubject);
    }

    return updatedSubjects;
  }

  bool _hasFacultyQuizzes(Map<String, dynamic> subject) {
    String subjectId = subject['id'];
    return _facultyQuizzes[subjectId]?.isNotEmpty ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    double childAspectRatio;

    if (screenWidth > 1200) {
      crossAxisCount = 3;
      childAspectRatio = 2.2;
    } else if (screenWidth > 800) {
      crossAxisCount = 2;
      childAspectRatio = 2.0;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 2.6;
    }

    return Scaffold(
      backgroundColor: primaryWhite,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: primaryBar,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryBar,
                      primaryButton,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quizzes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'PTSerif-Bold',
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Test your knowledge across various subjects',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontFamily: 'PTSerif',
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.quiz,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      '${filteredSubjects.length} subjects available',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Category Filter
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        child: FilterChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : primaryBar,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: primaryButton,
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? primaryButton.withOpacity(0.3)
                                : primaryBar.withOpacity(0.2),
                            width: isSelected ? 1.5 : 1,
                          ),
                          elevation: isSelected ? 6 : 2,
                          shadowColor: isSelected
                              ? primaryButton.withOpacity(0.3)
                              : Colors.black.withOpacity(0.1),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Subject Search
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          ),

          // Subjects Grid with Loading State
          _loadingFacultyQuizzes
              ? SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primaryButton),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading faculty quizzes...',
                            style: TextStyle(
                              color: primaryBar.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final subject = filteredSubjects[index];
                        return _buildSubjectCard(context, subject, index);
                      },
                      childCount: filteredSubjects.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
      BuildContext context, Map<String, dynamic> subject, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      child: Card(
        elevation: 8,
        shadowColor: subject['color'].withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _navigateToQuiz(context, subject);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  subject['color'].withOpacity(0.05),
                ],
              ),
            ),
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: subject['color'],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: subject['color'].withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    subject['icon'],
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        subject['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryBar,
                          fontFamily: 'PTSerif-Bold',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            subject['category'],
                            style: TextStyle(
                              fontSize: 10,
                              color: primaryBar.withOpacity(0.6),
                              fontFamily: 'PTSerif',
                            ),
                          ),
                          // Show faculty quiz indicator
                          if (_hasFacultyQuizzes(subject)) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Faculty Quizzes',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: subject['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: subject['color'],
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'View Subject',
                        style: TextStyle(
                          color: subject['color'],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToQuiz(BuildContext context, Map<String, dynamic> subject) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SubjectDetailScreen(subject: subject),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}

class QuizTakingScreen extends StatefulWidget {
  final dynamic quiz;
  QuizTakingScreen({required this.quiz});

  @override
  _QuizTakingScreenState createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen>
    with TickerProviderStateMixin {
  // Safe accessor for quiz as Map<String, dynamic>
  Map<String, dynamic> get quiz =>
      Map<String, dynamic>.from(widget.quiz as Map);

  int current = 0;
  Map<int, int> answers = {};
  Map<int, String> codingAnswers = {};
  Map<int, String> subjectiveAnswers = {};
  Map<int, ProgrammingLanguage> codingLanguages = {};
  Duration remaining = Duration(minutes: 5);
  Timer? _timer;
  late AnimationController _progressController;
  late AnimationController _questionController;
  late Animation<Offset> _slideAnimation;
  List<Map<String, dynamic>> _mcqs = [];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: Duration(seconds: 300), // 5 minutes
      vsync: this,
    );
    _questionController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: Offset(1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _questionController, curve: Curves.easeOut));

    _progressController.forward();
    _questionController.forward();

    // Load questions - prefer new facultyQuestions format, fall back to old sections.mcq
    if (quiz['facultyQuestions'] != null &&
        (quiz['facultyQuestions'] as List).isNotEmpty) {
      // New format with mixed MCQ and coding questions
      _mcqs = List<Map<String, dynamic>>.from((quiz['facultyQuestions'] as List)
          .map((q) => Map<String, dynamic>.from(q as Map)))
        .where((q) => !_isCodingQuestion(q))
        .toList();
      print(
          '✅ Loaded quiz with facultyQuestions format: ${_mcqs.length} questions');
      for (int i = 0; i < _mcqs.length; i++) {
        print(
            '  Q${i + 1}: type=${_mcqs[i]['type']}, hasTestCases=${_mcqs[i]['testCases'] != null}');
      }
    } else {
      // Old format - MCQ only
      final raw = (quiz['sections']?['mcq'] ?? []) as List;
      _mcqs = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((q) => !_isCodingQuestion(q))
          .toList();
      print(
          '⚠️ Loaded quiz with old sections.mcq format: ${_mcqs.length} questions');
      for (int i = 0; i < _mcqs.length; i++) {
        print(
            '  Q${i + 1}: type=${_mcqs[i]['type']}, hasOptions=${_mcqs[i]['options'] != null}');
      }
    }

    _shuffleMcqs();

    // Initialize default coding language from the question language.
    for (int i = 0; i < _mcqs.length; i++) {
      if (_isCodingQuestion(_mcqs[i])) {
        final lang = _getProgrammingLanguage(_mcqs[i]['language']?.toString());
        codingLanguages[i] = lang;
      }
    }

    _timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (remaining.inSeconds <= 1) {
        t.cancel();
        _finish();
      } else {
        setState(() => remaining = Duration(seconds: remaining.inSeconds - 1));
      }
    });
  }

  void _shuffleMcqs() {
    // Determine base seed from user id and quiz id so shuffle differs per user
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    String quizId = (quiz['id'] ?? quiz['key'] ?? '').toString();
    int baseSeed = uid.isNotEmpty
        ? _stableSeed(uid + '::' + quizId)
        : DateTime.now().millisecondsSinceEpoch;

    // Only shuffle MCQ questions - skip coding questions
    for (int i = 0; i < _mcqs.length; i++) {
      final q = Map<String, dynamic>.from(_mcqs[i]);

      // Skip shuffling for coding questions
      if (_isCodingQuestion(q)) {
        _mcqs[i] = q;
        continue;
      }

      // Shuffle options for MCQ questions
      final List opts = List.from(q['options'] ?? q['choices'] ?? []);
      final int correctIndex = q['correct'] ?? 0;

      final List<Map<String, dynamic>> paired = [];
      for (int j = 0; j < opts.length; j++)
        paired.add({'text': opts[j], 'orig': j});

      paired.shuffle(Random(baseSeed + i));
      final List newOptions = paired.map((p) => p['text']).toList();
      final int newCorrect =
          paired.indexWhere((p) => p['orig'] == correctIndex);

      // Update fields used by this UI
      q['options'] = newOptions;
      q['correct'] = newCorrect >= 0 ? newCorrect : 0;
      _mcqs[i] = q;
    }

    // Shuffle question order using baseSeed to make question ordering stable per user
    _mcqs.shuffle(Random(baseSeed ^ 0x9e3779b1));
  }

  int _stableSeed(String s) {
    int h = 0;
    for (int i = 0; i < s.length; i++) {
      h = (h * 31 + s.codeUnitAt(i)) & 0x7fffffff;
    }
    return h;
  }

  Future<void> _finish() async {
    _timer?.cancel();

    // Show a loading dialog while evaluating
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Evaluating your answers...',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );

    double score = 0;
    double totalMarks = 0;
    final Map<int, int> codingPassedByQuestion = {};
    final Map<int, int> codingTotalByQuestion = {};
    final Map<int, double> subjectiveKeywordScoreByQuestion = {};
    final Map<int, List<String>> subjectiveMatchedKeywordsByQuestion = {};
    final Map<int, int> subjectiveTotalKeywordsByQuestion = {};

    // Process each question
    for (int i = 0; i < _mcqs.length; i++) {
      final q = _mcqs[i];
      final maxMarks = _questionMaxMarks(q);
      totalMarks += maxMarks;
      if (_isCodingQuestion(q)) {
        // Proper marking scheme for coding question:
        // 1. Evaluate based on test cases success rate
        final studentCode = codingAnswers[i] ?? '';
        final testCases = (q['testCases'] ?? []) as List;
        final studentLanguage = codingLanguages[i] ??
            _getProgrammingLanguage(q['language']?.toString());
        final facultyLanguage =
            _getProgrammingLanguage(q['language']?.toString());

        if (studentCode.trim().isNotEmpty && testCases.isNotEmpty) {
          final results = await SimulatedCodeRunner.runTests(
            code: studentCode,
            testCasesData: testCases,
            language: studentLanguage,
            solutionLanguage: facultyLanguage,
            solutionCode: q['solutionCode']?.toString(),
            skipDelay: true, // Internal calculation should be fast
          );

          int passed = results.where((r) => r.isPassed).length;
          double questionScore = passed / testCases.length;
          score += questionScore * maxMarks;
          codingPassedByQuestion[i] = passed;
          codingTotalByQuestion[i] = testCases.length;

          print(
              'Coding Q${i + 1} Score: ${questionScore * maxMarks} / $maxMarks ($passed/${testCases.length} passed)');
        }
      } else if (_isSubjectiveQuestion(q)) {
        final answerText = (subjectiveAnswers[i] ?? '').trim();
        final keywords = _extractQuestionKeywords(q);
        subjectiveTotalKeywordsByQuestion[i] = keywords.length;

        if (answerText.isNotEmpty && keywords.isNotEmpty) {
          final matched = _matchKeywordsInAnswer(answerText, keywords);
          final ratio = matched.length / keywords.length;
          final questionScore = ratio * maxMarks;
          score += questionScore;
          subjectiveKeywordScoreByQuestion[i] = questionScore;
          subjectiveMatchedKeywordsByQuestion[i] = matched;
        } else {
          subjectiveKeywordScoreByQuestion[i] = 0.0;
          subjectiveMatchedKeywordsByQuestion[i] = <String>[];
        }
      } else {
        // Evaluate MCQ
        if (answers[i] == q['correct']) {
          score += maxMarks;
        }
      }
    }

    // Dismiss loading dialog
    if (mounted) Navigator.pop(context);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            QuizResultScreen(
          score: score,
          total: _mcqs.length,
          totalMarks: totalMarks,
          quizTitle: widget.quiz['title'] ?? 'Quiz',
          quizColor: widget.quiz['color'] ?? primaryButton,
          quiz: widget.quiz,
          answers: answers,
          codingAnswers: codingAnswers,
          codingLanguages: codingLanguages,
          subjectiveAnswers: subjectiveAnswers,
          codingPassedByQuestion: codingPassedByQuestion,
          codingTotalByQuestion: codingTotalByQuestion,
          subjectiveKeywordScoreByQuestion: subjectiveKeywordScoreByQuestion,
          subjectiveMatchedKeywordsByQuestion:
              subjectiveMatchedKeywordsByQuestion,
          subjectiveTotalKeywordsByQuestion: subjectiveTotalKeywordsByQuestion,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _nextQuestion() {
    if (current < _mcqs.length - 1) {
      _questionController.reset();
      setState(() => current++);
      _questionController.forward();
    } else {
      _finish();
    }
  }

  void _previousQuestion() {
    if (current > 0) {
      _questionController.reset();
      setState(() => current--);
      _questionController.forward();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  bool _isCodingQuestion(Map<String, dynamic> question) {
    // Coding questions are identified by explicit type; fallback to testCases+language for back-compat.
    final isCoding = question['type'] == 'coding' ||
        (question['testCases'] != null && question['language'] != null);
    return isCoding;
  }

  bool _isSubjectiveQuestion(Map<String, dynamic> question) {
    return question['type'] == 'subjective';
  }

  double _questionMaxMarks(Map<String, dynamic> question) {
    if (_isCodingQuestion(question) || _isSubjectiveQuestion(question)) {
      final v = question['marks'];
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is String) return double.tryParse(v) ?? 1.0;
    }
    return 1.0;
  }

  List<String> _extractQuestionKeywords(Map<String, dynamic> question) {
    final raw = question['keywords'];
    if (raw is List) {
      return raw
          .map((k) => k.toString().trim().toLowerCase())
          .where((k) => k.isNotEmpty)
          .toSet()
          .toList();
    }
    if (raw is String) {
      return raw
          .split(RegExp(r'[,;\n]+'))
          .map((k) => k.trim().toLowerCase())
          .where((k) => k.isNotEmpty)
          .toSet()
          .toList();
    }
    return <String>[];
  }

  List<String> _matchKeywordsInAnswer(String answer, List<String> keywords) {
    final normalizedAnswer = answer.toLowerCase();
    final matched = <String>[];
    for (final keyword in keywords) {
      final escaped = RegExp.escape(keyword.trim());
      if (escaped.isEmpty) continue;
      final pattern =
          RegExp('(^|[^a-z0-9])$escaped([^a-z0-9]|\$)', caseSensitive: false);
      if (pattern.hasMatch(normalizedAnswer)) {
        matched.add(keyword);
      }
    }
    return matched;
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  ProgrammingLanguage _getProgrammingLanguage(String? langStr) {
    if (langStr == null) return ProgrammingLanguage.python;
    switch (langStr.toLowerCase()) {
      case 'python':
        return ProgrammingLanguage.python;
      case 'java':
        return ProgrammingLanguage.java;
      case 'cpp':
      case 'c++':
        return ProgrammingLanguage.cpp;
      case 'javascript':
      case 'js':
        return ProgrammingLanguage.javascript;
      case 'dart':
        return ProgrammingLanguage.dart;
      default:
        return ProgrammingLanguage.python;
    }
  }

  String _languageLabel(ProgrammingLanguage lang) {
    switch (lang) {
      case ProgrammingLanguage.python:
        return 'Python';
      case ProgrammingLanguage.java:
        return 'Java';
      case ProgrammingLanguage.cpp:
        return 'C++';
      case ProgrammingLanguage.javascript:
        return 'JavaScript';
      case ProgrammingLanguage.dart:
        return 'Dart';
    }
  }

  /// Decode escape sequences in strings from Firebase
  String _decodeString(String text) {
    if (text.isEmpty) return text;
    // Replace literal \n with actual newlines
    return text
        .replaceAll('\\n', '\n')
        .replaceAll('\\t', '\t')
        .replaceAll('\\r', '\r');
  }

  /// Check if current question can be answered and user can continue
  bool _canContinue() {
    final q = _mcqs[current];
    if (_isCodingQuestion(q) || _isSubjectiveQuestion(q)) {
      // For coding questions: always allow moving to the next question
      // (student can skip without writing code)
      return true;
    } else {
      // For MCQ questions, require an answer to be selected
      return answers[current] != null;
    }
  }

  /// Show test results dialog for coding question
  void _showTestResults() async {
    final q = _mcqs[current];
    if (q['testCases'] == null || (q['testCases'] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No test cases available for this question')),
      );
      return;
    }

    final code = codingAnswers[current] ?? "";

    // Show loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Running Tests...',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );

    final studentLanguage = codingLanguages[current] ??
        _getProgrammingLanguage(q['language']?.toString());
    final facultyLanguage = _getProgrammingLanguage(q['language']?.toString());

    // Simulated Code Execution
    final results = await SimulatedCodeRunner.runTests(
      code: code,
      testCasesData: q['testCases'] as List,
      language: studentLanguage,
      solutionLanguage: facultyLanguage,
      solutionCode: q['solutionCode']?.toString(),
    );

    // Dismiss loading and show results
    if (mounted) Navigator.pop(context);

    showDialog(
      context: context,
      builder: (ctx) => TestResultsDialog(
        results: results,
        language: studentLanguage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mcqs.isEmpty)
      return Scaffold(body: Center(child: Text('No questions')));
    final q = _mcqs[current];
    final quizColor = widget.quiz['color'] ?? primaryButton;

    print('📝 QUIZ BUILD: current=$current, totalQ=${_mcqs.length}');
    print('   Question data: ${q.keys.toList()}');
    print('   Is coding: ${_isCodingQuestion(q)}');
    print('   Has options: ${q['options'] != null}');

    return Scaffold(
      backgroundColor: primaryWhite,
      appBar: AppBar(
        title: Text(
          widget.quiz['title'] ?? 'Quiz',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'PTSerif-Bold',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: quizColor,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  _fmt(remaining),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: quizColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${current + 1} of ${_mcqs.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontFamily: 'PTSerif',
                      ),
                    ),
                    Text(
                      '${((current + 1) / _mcqs.length * 100).round()}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (current + 1) / _mcqs.length,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ],
            ),
          ),

          // Question Section
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),

                    // Question Type Badge
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isCodingQuestion(q)
                            ? Colors.purple.shade100
                            : _isSubjectiveQuestion(q)
                                ? Colors.orange.shade100
                                : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isCodingQuestion(q)
                                ? Icons.code
                                : _isSubjectiveQuestion(q)
                                    ? Icons.subject
                                    : Icons.quiz,
                            size: 16,
                            color: _isCodingQuestion(q)
                                ? Colors.purple.shade700
                                : _isSubjectiveQuestion(q)
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _isCodingQuestion(q)
                                ? 'Coding Question'
                                : _isSubjectiveQuestion(q)
                                    ? 'Subjective Question'
                                    : 'Multiple Choice',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isCodingQuestion(q)
                                  ? Colors.purple.shade700
                                  : _isSubjectiveQuestion(q)
                                      ? Colors.orange.shade700
                                      : Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: quizColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        q['question'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBar,
                          height: 1.4,
                          fontFamily: 'PTSerif-Bold',
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Content based on question type
                    if (_isCodingQuestion(q)) ...[
                      // Content: Scrollable area with test cases and code editor,
                      // with action buttons fixed at the bottom of this panel.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Show test cases if available
                                    if (q['testCases'] != null &&
                                        (q['testCases'] as List).isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Sample Test Cases:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          ...(q['testCases'] as List)
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final tc = entry.value
                                                as Map<String, dynamic>;
                                            return Container(
                                              margin:
                                                  EdgeInsets.only(bottom: 12),
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (tc['description'] != null)
                                                    Text(
                                                      _decodeString(tc[
                                                                  'description']
                                                              ?.toString() ??
                                                          ''),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Input: ${_decodeString(tc['input']?.toString() ?? '')}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                  Text(
                                                    'Output: ${_decodeString((tc['expectedOutput'] ?? tc['output'])?.toString() ?? '')}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Write your solution below:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          'Language:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        DropdownButton<ProgrammingLanguage>(
                                          value: codingLanguages[current] ??
                                              _getProgrammingLanguage(
                                                  q['language']?.toString()),
                                          items: ProgrammingLanguage.values
                                              .map(
                                                (lang) => DropdownMenuItem<
                                                    ProgrammingLanguage>(
                                                  value: lang,
                                                  child: Text(
                                                      _languageLabel(lang)),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (newLang) {
                                            if (newLang == null) return;
                                            setState(() {
                                              codingLanguages[current] =
                                                  newLang;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    // Code editor
                                    Container(
                                      height: 300,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: CodeEditorWidget(
                                        language: codingLanguages[current] ??
                                            _getProgrammingLanguage(
                                                q['language']?.toString()),
                                        initialCode:
                                            codingAnswers[current] ?? '',
                                        onCodeChanged: (code) {
                                          if (codingAnswers[current] != code) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              if (mounted) {
                                                setState(() {
                                                  codingAnswers[current] = code;
                                                });
                                              }
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            // BUTTONS: Run Tests, Submit
                            Container(
                              color: Colors.grey[100],
                              padding: EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: _showTestResults,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                    child: Text('Run Tests',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        // Mark as "attempted" so results screen includes this question.
                                        answers[current] = 1;
                                      });
                                      _nextQuestion();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                    child: Text('Submit Answer',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_isSubjectiveQuestion(q)) ...[
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Write your answer below:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                key: ValueKey('subjective_answer_$current'),
                                maxLines: 10,
                                minLines: 6,
                                initialValue: subjectiveAnswers[current] ?? '',
                                onChanged: (value) {
                                  subjectiveAnswers[current] = value;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Type your explanation here...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignLabelWithHint: true,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Note: This question is auto-evaluated using faculty-defined keywords.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ListView.builder(
                          itemCount: (q['options'] as List).length,
                          itemBuilder: (context, optionIndex) {
                            final option = (q['options'] as List)[optionIndex];
                            final isSelected = answers[current] == optionIndex;

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => setState(
                                      () => answers[current] = optionIndex),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? quizColor.withOpacity(0.1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? quizColor
                                            : Colors.grey.withOpacity(0.3),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color:
                                                    quizColor.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? quizColor
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected
                                                  ? quizColor
                                                  : Colors.grey
                                                      .withOpacity(0.5),
                                              width: 2,
                                            ),
                                          ),
                                          child: isSelected
                                              ? Icon(Icons.check,
                                                  color: Colors.white, size: 16)
                                              : null,
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            option,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isSelected
                                                  ? quizColor
                                                  : primaryBar,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
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
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (current > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _previousQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: primaryBar,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Previous',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (current > 0) SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_isCodingQuestion(_mcqs[current]) ||
                            _isSubjectiveQuestion(_mcqs[current]))
                        ? _nextQuestion
                        : (_canContinue() ? _nextQuestion : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: quizColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      current < _mcqs.length - 1
                          ? ((_isCodingQuestion(_mcqs[current]) ||
                                  _isSubjectiveQuestion(_mcqs[current]))
                              ? 'Skip & Next'
                              : 'Next Question')
                          : 'Submit Quiz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuizResultScreen extends StatefulWidget {
  final double score;
  final int total;
  final double totalMarks;
  final String quizTitle;
  final Color quizColor;
  final Map<String, dynamic>? quiz;
  final Map<int, dynamic> answers;
  final Map<int, String> codingAnswers;
  final Map<int, ProgrammingLanguage> codingLanguages;
  final Map<int, String> subjectiveAnswers;
  final Map<int, int> codingPassedByQuestion;
  final Map<int, int> codingTotalByQuestion;
  final Map<int, double> subjectiveKeywordScoreByQuestion;
  final Map<int, List<String>> subjectiveMatchedKeywordsByQuestion;
  final Map<int, int> subjectiveTotalKeywordsByQuestion;

  QuizResultScreen({
    required this.score,
    required this.total,
    required this.totalMarks,
    required this.quizTitle,
    required this.answers,
    required this.codingAnswers,
    this.codingLanguages = const {},
    this.subjectiveAnswers = const {},
    this.codingPassedByQuestion = const {},
    this.codingTotalByQuestion = const {},
    this.subjectiveKeywordScoreByQuestion = const {},
    this.subjectiveMatchedKeywordsByQuestion = const {},
    this.subjectiveTotalKeywordsByQuestion = const {},
    this.quizColor = Colors.blue,
    this.quiz,
  });

  @override
  _QuizResultScreenState createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _scoreController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _scoreController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _scoreAnimation =
        Tween<double>(begin: 0.0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    Future.delayed(Duration(milliseconds: 500), () {
      _scoreController.forward();
    });
    // Persist student submission so progress page can read it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveSubmissionIfNeeded();
    });
  }

  Future<void> _saveSubmissionIfNeeded() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final quizMap = widget.quiz;
      final quizId =
          quizMap != null ? (quizMap['id'] ?? quizMap['key'] ?? '') : '';
      final percentage =
          (widget.score / (widget.totalMarks > 0 ? widget.totalMarks : 1)) *
              100.0;

      // Avoid duplicate submissions: check existing doc for same student and quiz
      if (quizId.isNotEmpty) {
        final existing = await FirebaseFirestore.instance
            .collection('quiz_submissions')
            .where('quizId', isEqualTo: quizId)
            .where('studentId', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          // already saved
          return;
        }
      }

      String studentName = '';
      String studentEnrollment = '';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final sd = doc.data();
          studentName = (sd?['name'] ?? '').toString();
          studentEnrollment =
              (sd?['enrollmentNumber'] ?? sd?['enrollmentNo'] ?? '').toString();
        }
      } catch (e) {
        print('Error reading student profile: $e');
      }

      // Convert maps to lists for storage
      final mcqAnswersList =
          List.generate(widget.total, (i) => widget.answers[i]);
      final codingAnswersList =
          List.generate(widget.total, (i) => widget.codingAnswers[i] ?? '');
      final subjectiveAnswersList =
          List.generate(widget.total, (i) => widget.subjectiveAnswers[i] ?? '');
      final codingLanguagesList = List.generate(
        widget.total,
        (i) => (widget.codingLanguages[i] ?? ProgrammingLanguage.python).name,
      );
      final codingPassedList = List.generate(
          widget.total, (i) => widget.codingPassedByQuestion[i] ?? 0);
      final codingTotalList = List.generate(
          widget.total, (i) => widget.codingTotalByQuestion[i] ?? 0);
      final subjectiveKeywordScoreList = List.generate(widget.total,
          (i) => widget.subjectiveKeywordScoreByQuestion[i] ?? 0.0);
      final subjectiveMatchedKeywordsMap = <String, List<String>>{};
      for (int i = 0; i < widget.total; i++) {
        subjectiveMatchedKeywordsMap[i.toString()] = List<String>.from(
            widget.subjectiveMatchedKeywordsByQuestion[i] ?? const <String>[]);
      }
      final subjectiveTotalKeywordsList = List.generate(widget.total,
          (i) => widget.subjectiveTotalKeywordsByQuestion[i] ?? 0);

      final submission = {
        'quizId': quizId,
        'quizTitle': widget.quizTitle,
        'subjectLabel': quizMap != null
            ? (quizMap['subjectLabel'] ??
                quizMap['subject'] ??
                quizMap['unit'] ??
                '')
            : '',
        'subjectId': quizMap != null ? (quizMap['id'] ?? '') : '',
        'studentId': user.uid,
        'studentName': studentName,
        'enrollmentNumber': studentEnrollment,
        'enrollmentNo': studentEnrollment,
        'answers': mcqAnswersList,
        'codingAnswers': codingAnswersList,
        'codingLanguages': codingLanguagesList,
        'subjectiveAnswers': subjectiveAnswersList,
        'codingTestCasesPassedByQuestion': codingPassedList,
        'codingTestCasesTotalByQuestion': codingTotalList,
        'subjectiveKeywordScoreByQuestion': subjectiveKeywordScoreList,
        'subjectiveMatchedKeywordsByQuestion': subjectiveMatchedKeywordsMap,
        'subjectiveTotalKeywordsByQuestion': subjectiveTotalKeywordsList,
        'correctAnswers': widget.score,
        'percentage': percentage,
        'totalMarks': widget.totalMarks,
        'timeTakenSeconds': 0,
        'timestamp': FieldValue.serverTimestamp(),
        'quizData': quizMap ?? {},
      };

      await FirebaseFirestore.instance
          .collection('quiz_submissions')
          .add(submission);
      print('Saved student submission for quizId=$quizId student=${user.uid}');
    } catch (e) {
      print('Error saving student submission: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  String get _performanceText {
    final percentage =
        (widget.score / (widget.totalMarks > 0 ? widget.totalMarks : 1)) * 100;
    if (percentage >= 90) return 'Excellent!';
    if (percentage >= 80) return 'Great Job!';
    if (percentage >= 70) return 'Good Work!';
    if (percentage >= 60) return 'Not Bad!';
    return 'Keep Trying!';
  }

  Color get _performanceColor {
    final percentage =
        (widget.score / (widget.totalMarks > 0 ? widget.totalMarks : 1)) * 100;
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final percentage =
        (widget.score / (widget.totalMarks > 0 ? widget.totalMarks : 1)) * 100;
    final totalText = widget.totalMarks % 1 == 0
        ? widget.totalMarks.toInt().toString()
        : widget.totalMarks.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: primaryWhite,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.quizColor,
                      widget.quizColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Quiz Completed!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PTSerif-Bold',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.quizTitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontFamily: 'PTSerif',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(height: 40),

                      // Score Circle
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _performanceColor.withOpacity(0.1),
                                _performanceColor.withOpacity(0.05),
                              ],
                            ),
                            border: Border.all(
                              color: _performanceColor.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _scoreAnimation,
                                  builder: (context, child) {
                                    final val = _scoreAnimation.value;
                                    final text = val % 1 == 0
                                        ? val.toInt().toString()
                                        : val.toStringAsFixed(1);
                                    return Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: _performanceColor,
                                        fontFamily: 'PTSerif-Bold',
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  '/ $totalText',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: primaryBar.withOpacity(0.6),
                                    fontFamily: 'PTSerif',
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _performanceColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${percentage.round()}%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _performanceColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 32),

                      // Performance Text
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Text(
                          _performanceText,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _performanceColor,
                            fontFamily: 'PTSerif-Bold',
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      Text(
                        percentage >= 70
                            ? 'You have a good understanding of the subject!'
                            : 'Review the topics and try again to improve your score.',
                        style: TextStyle(
                          fontSize: 16,
                          color: primaryBar.withOpacity(0.7),
                          fontFamily: 'PTSerif',
                        ),
                        textAlign: TextAlign.center,
                      ),

                      Spacer(),

                      // Action Buttons
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.quizColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                'Back to Quizzes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: widget.quizColor,
                                side: BorderSide(color: widget.quizColor),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Try Again',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small pre-quiz details form (kept minimal and reusable).
class PreQuizFormScreen extends StatefulWidget {
  @override
  State<PreQuizFormScreen> createState() => _PreQuizFormScreenState();
}

class _PreQuizFormScreenState extends State<PreQuizFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _universityController = TextEditingController();
  final _courseController = TextEditingController();

  @override
  void dispose() {
    _universityController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details'), backgroundColor: primaryBar),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
                controller: _universityController,
                decoration: InputDecoration(labelText: 'University')),
            SizedBox(height: 12),
            TextFormField(
                controller: _courseController,
                decoration: InputDecoration(labelText: 'Course')),
            Spacer(),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? true)
                        Navigator.pop(context, {
                          'university': _universityController.text.trim(),
                          'course': _courseController.text.trim()
                        });
                    },
                    child: Text('Continue')))
          ]),
        ),
      ),
    );
  }
}
