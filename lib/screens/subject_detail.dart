import 'package:flutter/material.dart';
import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/screens/faculty_quiz_taking_screen.dart';
import '../services/quiz_service.dart';

class SubjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectDetailScreen({Key? key, required this.subject}) : super(key: key);

  @override
  _SubjectDetailScreenState createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final QuizService _quizService = QuizService();
  
  Map<String, dynamic>? _subjectWithFacultyQuizzes;
  bool _loadingFacultyQuizzes = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadFacultyQuizzesForSubject();
  }

  Future<void> _loadFacultyQuizzesForSubject() async {
    try {
      // Robust lookup for subject ID
      final dynamic subjectMap = widget.subject;
      String rawId = 'general';
      if (subjectMap is Map) {
        rawId = (subjectMap['id'] ?? subjectMap['title'] ?? subjectMap['label'] ?? 'general').toString();
      }
      
      String subjectId = rawId;
      print('Loading faculty quizzes for subject identifier: $subjectId');
      
      List<Map<String, dynamic>> facultyQuizzes = await _quizService.getQuizzesForSubject(subjectId);
      print('Retrieved ${facultyQuizzes.length} faculty quizzes for $subjectId');
      
      // Create a copy of the subject and merge faculty quizzes
      Map<String, dynamic> updatedSubject = Map<String, dynamic>.from(widget.subject);
      List<Map<String, dynamic>> units = [];
      
      // Initialize units with clean structure
      for (var unit in (updatedSubject['units'] ?? [])) {
        Map<String, dynamic> cleanUnit = {
          'name': unit['name'],
          'topics': unit['topics'],
          'quizzes': [], // Start with empty quizzes
        };
        units.add(cleanUnit);
      }
      
      // Group faculty quizzes by unit
      Map<String, List<Map<String, dynamic>>> quizzesByUnit = {};
      for (var quiz in facultyQuizzes) {
        String unitName = quiz['unit'] ?? 'Unit 1';
        print('Quiz "${quiz['title']}" assigned to unit: $unitName');
        
        if (!quizzesByUnit.containsKey(unitName)) {
          quizzesByUnit[unitName] = [];
        }
        
        quizzesByUnit[unitName]!.add({
          'name': quiz['title'],
          'title': quiz['title'],
          'questions': quiz['questions']?.length ?? 0,
          'duration': quiz['duration'],
          'id': quiz['id'],
          'isFromFaculty': true,
          'date': quiz['date'],
          'unit': quiz['unit'],
          'facultyQuestions': quiz['questions'],
          'instructions': quiz['instructions'] ?? '',
          'pin': quiz['pin'], // Add the PIN field
        });
      }
      
      print('Quizzes grouped by unit: ${quizzesByUnit.keys.toList()}');
      
      // Add faculty quizzes to corresponding units
      for (int i = 0; i < units.length; i++) {
        String unitName = units[i]['name'];
        if (quizzesByUnit.containsKey(unitName)) {
          units[i]['quizzes'] = quizzesByUnit[unitName]!;
          print('Added ${quizzesByUnit[unitName]!.length} quizzes to $unitName');
          quizzesByUnit.remove(unitName);
        }
      }
      
      // Add new units for faculty quizzes that don't match existing units
      quizzesByUnit.forEach((unitName, quizzes) {
        print('Creating new unit: $unitName with ${quizzes.length} quizzes');
        units.add({
          'name': unitName,
          'topics': ['Faculty Created Content'],
          'quizzes': quizzes,
          'isFacultyUnit': true,
        });
      });
      
      updatedSubject['units'] = units;
      
      setState(() {
        _subjectWithFacultyQuizzes = updatedSubject;
        _loadingFacultyQuizzes = false;
      });
    } catch (e) {
      print('Error loading faculty quizzes for subject: $e');
      setState(() {
        _subjectWithFacultyQuizzes = widget.subject;
        _loadingFacultyQuizzes = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _getTotalTopicsCount() {
    int totalTopics = 0;
    final subject = _subjectWithFacultyQuizzes ?? widget.subject;
    final units = subject['units'] as List<dynamic>;
    for (var unit in units) {
      final topics = unit['topics'] as List<dynamic>;
      totalTopics += topics.length;
    }
    return totalTopics;
  }

  int _getTotalQuizzesCount() {
    int totalQuizzes = 0;
    final subject = _subjectWithFacultyQuizzes ?? widget.subject;
    final units = subject['units'] as List<dynamic>;
    for (var unit in units) {
      if (unit['quizzes'] != null) {
        final quizzes = unit['quizzes'] as List<dynamic>;
        totalQuizzes += quizzes.length;
      }
    }
    return totalQuizzes;
  }

  @override
  Widget build(BuildContext context) {
    final currentSubject = _subjectWithFacultyQuizzes ?? widget.subject;
    
    if (_loadingFacultyQuizzes) {
      return Scaffold(
        backgroundColor: primaryWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(widget.subject['color']),
              ),
              SizedBox(height: 16),
              Text(
                'Loading quizzes...',
                style: TextStyle(
                  color: primaryBar.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: primaryWhite,
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with better styling
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: widget.subject['color'],
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.subject['color'],
                      widget.subject['color'].withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 60, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                widget.subject['icon'],
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      widget.subject['category'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    widget.subject['title'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'PTSerif-Bold',
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Header Info Section
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: widget.subject['color'].withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        color: widget.subject['color'],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Course Units',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBar,
                          fontFamily: 'PTSerif-Bold',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Explore the comprehensive curriculum organized into 4 structured units',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryBar.withOpacity(0.7),
                      fontFamily: 'PTSerif',
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip('${currentSubject['units'].length} Units', Icons.library_books, widget.subject['color']),
                      SizedBox(width: 12),
                      _buildInfoChip('${_getTotalQuizzesCount()} Quizzes', Icons.quiz, widget.subject['color']),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Units Grid with improved layout
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 12,
                childAspectRatio: MediaQuery.of(context).size.width > 600 ? 4.0 : 4.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final unit = currentSubject['units'][index];
                  return _buildUnitCard(context, unit, index);
                },
                childCount: currentSubject['units'].length,
              ),
            ),
          ),
          
          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context, Map<String, dynamic> unit, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 + (index * 100)),
        curve: Curves.easeOutBack,
        child: Card(
          elevation: 6,
          shadowColor: widget.subject['color'].withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              _showUnitDetails(context, unit);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    widget.subject['color'].withOpacity(0.03),
                  ],
                ),
                border: Border.all(
                  color: widget.subject['color'].withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Unit number
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.subject['color'],
                            widget.subject['color'].withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: widget.subject['color'].withOpacity(0.2),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    
                    // Title and info section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            unit['name'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryBar,
                              fontFamily: 'PTSerif-Bold',
                            ),
                          ),
                          SizedBox(height: 4),
                          if (unit['quizzes'] != null)
                            Text(
                              '${(unit['quizzes'] as List).length} Quizzes',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.subject['color'],
                                fontWeight: FontWeight.w600,
                                fontFamily: 'PTSerif',
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Action button
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.subject['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.subject['color'].withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: widget.subject['color'],
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUnitDetails(BuildContext context, Map<String, dynamic> unit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: primaryWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.subject['color'].withOpacity(0.1),
                    widget.subject['color'].withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: widget.subject['color'].withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: primaryBar.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Unit header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.subject['color'],
                              widget.subject['color'].withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: widget.subject['color'].withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.subject['icon'],
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              unit['name'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryBar,
                                fontFamily: 'PTSerif-Bold',
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  widget.subject['title'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryBar.withOpacity(0.6),
                                    fontFamily: 'PTSerif',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: widget.subject['color'].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${(unit['topics'] as List).length} Topics',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: widget.subject['color'],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content Section - Quizzes Only
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title
                    Row(
                      children: [
                        Icon(
                          Icons.quiz,
                          color: widget.subject['color'],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Quizzes in ${unit['name']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryBar,
                            fontFamily: 'PTSerif-Bold',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Test your knowledge and understanding',
                      style: TextStyle(
                        fontSize: 13,
                        color: primaryBar.withOpacity(0.6),
                        fontFamily: 'PTSerif',
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Quizzes list
                    Expanded(
                      child: unit['quizzes'] != null ? ListView.builder(
                        itemCount: (unit['quizzes'] as List).length,
                        itemBuilder: (context, index) {
                          final quiz = (unit['quizzes'] as List)[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: widget.subject['color'].withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                _showQuizDetails(context, quiz);
                              },
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            widget.subject['color'],
                                            widget.subject['color'].withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: widget.subject['color'].withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.quiz_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            quiz['title'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: primaryBar,
                                              fontFamily: 'PTSerif',
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.help_outline,
                                                size: 12,
                                                color: widget.subject['color'],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${quiz['questions']} questions',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: primaryBar.withOpacity(0.6),
                                                  fontFamily: 'PTSerif',
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: widget.subject['color'],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                quiz['duration'],
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: primaryBar.withOpacity(0.6),
                                                  fontFamily: 'PTSerif',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: widget.subject['color'].withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        color: widget.subject['color'],
                                        size: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ) : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 48,
                              color: primaryBar.withOpacity(0.3),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No quizzes available',
                              style: TextStyle(
                                fontSize: 16,
                                color: primaryBar.withOpacity(0.6),
                                fontFamily: 'PTSerif',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Action button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${unit['name']} content will be available soon!',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: widget.subject['color'],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.all(16),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.subject['color'],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: widget.subject['color'].withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_filled, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Start Learning ${unit['name']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuizDetails(BuildContext context, Map<String, dynamic> quiz) {
    bool isFacultyQuiz = quiz['isFromFaculty'] == true;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                widget.subject['color'].withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with faculty indicator
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.subject['color'],
                          widget.subject['color'].withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: widget.subject['color'].withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFacultyQuiz ? Icons.school : Icons.quiz,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz['title'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryBar,
                            fontFamily: 'PTSerif-Bold',
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            if (isFacultyQuiz) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Faculty Created',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                            ],
                            Text(
                              quiz['name'] ?? quiz['title'],
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.subject['color'],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (isFacultyQuiz && quiz['date'] != null) ...[
                          SizedBox(height: 2),
                          Text(
                            'Created: ${quiz['date']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryBar.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),

              // Show instructions if provided by faculty
              if (quiz['instructions'] != null && quiz['instructions'].toString().trim().isNotEmpty) ...[
                Text(
                  'Instructions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBar),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.subject['color'].withOpacity(0.08)),
                  ),
                  child: Text(
                    quiz['instructions'].toString(),
                    style: TextStyle(fontSize: 13, color: primaryBar.withOpacity(0.8)),
                  ),
                ),
                SizedBox(height: 16),
              ],
              
              // Quiz details
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.subject['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.subject['color'].withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Icon(
                                Icons.help_outline,
                                color: widget.subject['color'],
                                size: 24,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${quiz['questions']}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: widget.subject['color'],
                                ),
                              ),
                              Text(
                                'Questions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryBar.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: widget.subject['color'].withOpacity(0.3),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: widget.subject['color'],
                                size: 24,
                              ),
                              SizedBox(height: 8),
                              Text(
                                quiz['duration'].split(' ')[0],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: widget.subject['color'],
                                ),
                              ),
                              Text(
                                'Minutes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryBar.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: widget.subject['color']),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: widget.subject['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (isFacultyQuiz && quiz['facultyQuestions'] != null && (quiz['facultyQuestions'] as List).isNotEmpty) {
                          // Check if quiz has a PIN requirement
                          String quizPin = quiz['pin']?.toString() ?? '';
                          if (quizPin.isNotEmpty) {
                            // Show PIN verification dialog
                            bool pinVerified = await _showPinVerificationDialog(context, quizPin);
                            if (!pinVerified) {
                              return; // Don't start quiz if PIN verification failed
                            }
                          }
                          
                          // Close the quiz details dialog first
                          Navigator.pop(context);
                          
                          // Check if context is still mounted before navigating
                          if (mounted) {
                            // Start faculty quiz with actual questions
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FacultyQuizTakingScreen(
                                  quiz: quiz,
                                  subject: widget.subject,
                                ),
                              ),
                            );
                          }
                        } else {
                          // Close the dialog first
                          Navigator.pop(context);
                          
                          // Check if context is still mounted before showing snackbar
                          if (mounted) {
                            // Show coming soon for static quizzes
                            ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isFacultyQuiz 
                                        ? 'No questions available for this quiz yet.'
                                        : 'Quiz functionality coming soon!',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: widget.subject['color'],
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: EdgeInsets.all(16),
                            ),
                          );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.subject['color'],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Start Quiz',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showPinVerificationDialog(BuildContext context, String correctPin) async {
    TextEditingController _pinController = TextEditingController();
    bool isCorrect = false;
    
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: primaryBar,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Enter Quiz PIN',
                    style: TextStyle(
                      fontFamily: 'PTSerif',
                      fontWeight: FontWeight.bold,
                      color: primaryBar,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This quiz requires a 6-digit PIN to access.',
                    style: TextStyle(
                      fontFamily: 'PTSerif',
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      fontFamily: 'PTSerif',
                    ),
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      labelStyle: TextStyle(
                        fontFamily: 'PTSerif',
                        color: primaryBar,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryBar),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryBar, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryBar.withOpacity(0.3)),
                      ),
                      prefixIcon: Icon(Icons.pin, color: primaryBar),
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value.length == 6) {
                        // Auto-validate when 6 digits are entered
                        setState(() {});
                      }
                    },
                  ),
                  if (_pinController.text.isNotEmpty && _pinController.text != correctPin)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Incorrect PIN. Please try again.',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontFamily: 'PTSerif',
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'PTSerif',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _pinController.text.length == 6
                      ? () {
                          if (_pinController.text == correctPin) {
                            isCorrect = true;
                            Navigator.of(context).pop();
                          } else {
                            setState(() {
                              // This will trigger the error message display
                            });
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBar,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Verify',
                    style: TextStyle(
                      fontFamily: 'PTSerif',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    
    return isCorrect;
  }
}