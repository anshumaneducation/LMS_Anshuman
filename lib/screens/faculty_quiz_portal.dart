import 'package:flutter/material.dart';
import 'package:stela_app/screens/faculty_quiz_manage.dart';

class FacultyQuizPortal extends StatefulWidget {
  final Map<String, dynamic> subject;
  static const String routeName = '/faculty-quiz-portal';

  const FacultyQuizPortal({Key? key, required this.subject}) : super(key: key);

  @override
  _FacultyQuizPortalState createState() => _FacultyQuizPortalState();
}

class _FacultyQuizPortalState extends State<FacultyQuizPortal> {
  @override
  Widget build(BuildContext context) {
    return FacultyQuizManage(subject: widget.subject);
  }
}
