/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:datatable/datatable.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            title: 'Firebase Data Tables',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: MyHomePage(),
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DatabaseReference _aiptRef;
  late DatabaseReference _ccRef;
  late DatabaseReference _coaRef;

  @override
  void initState() {
    super.initState();
    _aiptRef = FirebaseDatabase.instance.reference().child('aipt');
    _ccRef = FirebaseDatabase.instance.reference().child('cc');
    _coaRef = FirebaseDatabase.instance.reference().child('coa');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Data Tables'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 600,
              columns: [
                DataColumn2(label: Text('Enroll No.')),
                DataColumn2(label: Text('Value 1')),
                DataColumn2(label: Text('Value 2')),
                DataColumn2(label: Text('Value 3')),
                DataColumn2(label: Text('Value 4')),
                DataColumn2(label: Text('Value 5')),
              ],
              rows: [],
            ),
            SizedBox(height: 20),
            DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 600,
              columns: [
                DataColumn2(label: Text('Enroll No.')),
                DataColumn2(label: Text('Value 1')),
                DataColumn2(label: Text('Value 2')),
                DataColumn2(label: Text('Value 3')),
                DataColumn2(label: Text('Value 4')),
                DataColumn2(label: Text('Value 5')),
              ],
              rows: [],
            ),
            SizedBox(height: 20),
            DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 600,
              columns: [
                DataColumn2(label: Text('Enroll No.')),
                DataColumn2(label: Text('Value 1')),
                DataColumn2(label: Text('Value 2')),
                DataColumn2(label: Text('Value 3')),
                DataColumn2(label: Text('Value 4')),
                DataColumn2(label: Text('Value 5')),
              ],
              rows: [],
            ),
          ],
        ),
    );
  }
}*/
