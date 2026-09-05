import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../screens/faculty_subjects_data.dart';
import 'faculty_quiz_manage.dart';

class FacultySubjectPicker extends StatefulWidget {
  final List<Map<String, dynamic>> subjects;
  final Function(Map<String, dynamic>) onSubjectTap;
  final String title;

  const FacultySubjectPicker({
    Key? key,
    required this.subjects,
    required this.onSubjectTap,
    required this.title,
  }) : super(key: key);

  @override
  _FacultySubjectPickerState createState() => _FacultySubjectPickerState();
}

class _FacultySubjectPickerState extends State<FacultySubjectPicker> with TickerProviderStateMixin {
  String selectedCategory = 'All';
  String _searchQuery = '';
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  
  List<String> categories = ['All', 'Programming', 'Mathematics', 'Engineering', 'Technology'];

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredSubjects {
    final query = _searchQuery.trim().toLowerCase();
    final categoryFiltered = selectedCategory == 'All'
        ? widget.subjects
        : widget.subjects
            .where((subject) => subject['category'] == selectedCategory)
            .toList();

    if (query.isEmpty) return categoryFiltered;
    return categoryFiltered.where((subject) {
      final label = (subject['label'] ?? subject['title'] ?? '').toString().toLowerCase();
      final category = (subject['category'] ?? '').toString().toLowerCase();
      return label.contains(query) || category.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Responsive grid: 1 column on small/mobile widths, 2 on medium, 3 on large/tablet+.
    final double width = screenSize.width;
    int crossAxisCount;
    double childAspectRatio;
    if (width < 480) {
      // Mobile phones (portrait) — one card per row
      crossAxisCount = 1;
      childAspectRatio = 3.4; // wider card
    } else if (width < 800) {
      // Small tablets / landscape phones — two columns
      crossAxisCount = 2;
      childAspectRatio = 2.2;
    } else {
      // Large screens / tablets — three columns
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
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'PTSerif-Bold',
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Select a subject to continue',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
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
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBar,
                      fontFamily: 'PTSerif-Bold',
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategory == category;
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : primaryBar,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontFamily: 'PTSerif',
                              ),
                            ),
                            selectedColor: primaryButton,
                            backgroundColor: Colors.grey[100],
                            checkmarkColor: Colors.white,
                            onSelected: (selected) {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
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
                  SizedBox(height: 20),
                  Text(
                    'Subjects (${filteredSubjects.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryBar.withOpacity(0.8),
                      fontFamily: 'PTSerif',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
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

  Widget _buildSubjectCard(BuildContext context, Map<String, dynamic> subject, int index) {
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
            _navigateToQuizManage(context, subject);
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
                Flexible(
                    fit: FlexFit.loose,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (subject['title'] ?? subject['label'] ?? 'Untitled').toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryBar,
                            fontFamily: 'PTSerif-Bold',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          (subject['category'] ?? '').toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: primaryBar.withOpacity(0.6),
                            fontFamily: 'PTSerif',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: subject['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        color: subject['color'],
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Manage',
                        style: TextStyle(
                          color: subject['color'],
                          fontSize: 10,
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

  void _navigateToQuizManage(BuildContext context, Map<String, dynamic> subject) {
    widget.onSubjectTap(subject);
  }
}