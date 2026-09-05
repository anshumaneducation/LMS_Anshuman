import 'package:flutter/material.dart';

class ATablePage extends StatelessWidget {
  const ATablePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assessment Table')),
      body: Center(
        child: Text(
          'Assessment Table Content Goes Here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
