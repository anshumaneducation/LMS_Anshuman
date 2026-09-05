
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:stela_app/constants/userDetails.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PdfPageten(),
    );
  }
}

class PdfPageten extends StatefulWidget {
  @override
  _PdfPagetenState createState() => _PdfPagetenState();
}

class _PdfPagetenState extends State<PdfPageten> {
  String? totalMarks;
  String? code;
  String? starttime;
  String? endtime;
  String? expname;
  String? duration;
  String? universityName;
  String? CourseName;
  String? examTypeName;
  String? place;
  String? StudentSign;
  
  late Future<void> _fetchDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = fetchDataFromDatabase();
  }

  Future<void> fetchDataFromDatabase() async {
    final databaseReference = FirebaseDatabase.instance.ref();
    
      final DatabaseEvent event =
          await databaseReference.child('AIPT coding-TEST').child(enrollmentNo).child('Experiment 12').once();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? values =
            event.snapshot.value as Map<dynamic, dynamic>?;
        
                if (values is Map<String, dynamic>) {
                  setState(() {
                    totalMarks =
                        values['1_Total marks'].toString();
                        code =
                        values['9_Code'].toString();
                        starttime =
                        values['7_Start time'].toString();
                        endtime =
                        values['8_End time'].toString();
                        expname =
                        values['10_Aim'].toString();
                        duration =
                        values['11_Duration'].toString();
                        universityName=values['12_University Name'].toString();
                       
                        CourseName=values['13_Course Name'].toString();
                       
                        examTypeName=values['14_Exam Type'].toString();
                        
                        place=values['15_Place'].toString();
                    
                        
                  
                });
        }
      }
    
  }

  Future<void> _printPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
  child: pw.Text(
    'Report of Experiment 12', // Your heading text
    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
  ),
),
pw.SizedBox(height: 10),
pw.SizedBox(height: 10),
              pw.SizedBox(height: 10),

pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'University Name: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      pw.TextSpan(
        text: universityName,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),

pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'Course Name: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      pw.TextSpan(
        text: CourseName,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),

pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'Exam Type: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      pw.TextSpan(
        text: examTypeName,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),

pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'Place: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      pw.TextSpan(
        text: place,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),

              pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'Student Name: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      pw.TextSpan(
        text: name,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),

pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'Enrollment Number: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      pw.TextSpan(
        text: enrollmentNo,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),
pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'Name of experiment: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      pw.TextSpan(
        text: expname,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),
pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'Start time: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      pw.TextSpan(
        text: starttime,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),
pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'End time: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      pw.TextSpan(
        text: endtime,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),
pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'Total Duration: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      pw.TextSpan(
        text: duration,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),
pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'Total Marks: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      pw.TextSpan(
        text: totalMarks,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),
/*pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'Source code: \n',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      
      pw.TextSpan(
        text: code,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),*/
pw.SizedBox(height: 10),
pw.SizedBox(height: 10),
pw.SizedBox(height: 10),
pw.SizedBox(height: 10),
pw.SizedBox(height: 10),
pw.SizedBox(height: 10),
pw.SizedBox(height: 10),
pw.SizedBox(height: 10), 
pw.SizedBox(height: 10),
pw.SizedBox(height: 10),
pw.SizedBox(height: 10),
pw.SizedBox(height: 10),
pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'Student Sign: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
      pw.TextSpan(
        text: StudentSign,
        style: pw.TextStyle(fontSize: 16),
      ),
    ],
  ),
),
pw.SizedBox(height: 10),
pw.SizedBox(height: 10),
pw.RichText(
  text: pw.TextSpan(
    children: [
      pw.TextSpan(
        text: 'Faculty Sign: ',
        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
      ),
    ],
  ),
),

              // Add more text widgets here for other data
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('REPORT'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: () {
              _fetchDataFuture.then((_) {
                _printPdf();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _fetchDataFuture,
        builder: (context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          return SingleChildScrollView(
  child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                // Display fetched data here
                RichText(
  textAlign: TextAlign.center,
  text: TextSpan(
    children: [
      TextSpan(
        text: 'Report of Experiment 12', // Your heading text
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ],
  ),
),
Text(
  " ",
  style: TextStyle(fontSize: 17),
),
Text(
  " ",
  style: TextStyle(fontSize: 17),
),



 RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "University Name: ",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      /*TextSpan(
        text: "Indira Gandhi Delhi Technical University for Women",
        style: TextStyle(fontSize: 16),
      ),*/
       TextSpan(
        text: universityName,
        style: TextStyle(fontSize: 16),
      ),
   
    ],
  ),
),


 RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "Course Name: ",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      /*TextSpan(
        text: "Indira Gandhi Delhi Technical University for Women",
        style: TextStyle(fontSize: 16),
      ),*/
      TextSpan(
        text: CourseName,
        style: TextStyle(fontSize: 16),
      ),

    ],
  ),
),

RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "Exam Type: ",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      /*TextSpan(
        text: "Indira Gandhi Delhi Technical University for Women",
        style: TextStyle(fontSize: 16),
      ),*/
      TextSpan(
        text: examTypeName,
        style: TextStyle(fontSize: 16),
      ),

    ],
  ),
),

RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "Place: ",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      /*TextSpan(
        text: "Indira Gandhi Delhi Technical University for Women",
        style: TextStyle(fontSize: 16),
      ),*/
      TextSpan(
        text: place,
        style: TextStyle(fontSize: 16),
      ),

    ],
  ),
),




                RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "Student Name: ",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      TextSpan(
        text: name,
        style: TextStyle(fontSize: 16),
      ),
    ],
  ),
),
RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "Enrollment Number: ",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      TextSpan(
        text: enrollmentNo,
        style: TextStyle(fontSize: 16),
      ),
    ],
  ),
),
RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "Name of experiment: ",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      TextSpan(
        text: expname,
        style: TextStyle(fontSize: 16),
      ),
    ],
  ),
),
RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "Start time: ",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      TextSpan(
        text: starttime,
        style: TextStyle(fontSize: 16),
      ),
    ],
  ),
),
RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "End time: ",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      TextSpan(
        text: endtime,
        style: TextStyle(fontSize: 16),
      ),
    ],
  ),
),
RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "Total Duration: ",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      TextSpan(
        text: duration,
        style: TextStyle(fontSize: 16),
      ),
    ],
  ),
),
RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "Total Marks: ",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      TextSpan(
        text: totalMarks,
        style: TextStyle(fontSize: 16),
      ),
    ],
  ),
),
RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "Source code: \n",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      TextSpan(
        text: code,
        style: TextStyle(fontSize: 16),
      ),
    ],
  ),
),
Text(
  " ",
  style: TextStyle(fontSize: 17),
),
Text(
  " ",
  style: TextStyle(fontSize: 17),
),
Text(
  " ",
  style: TextStyle(fontSize: 17),
),
Text(
  " ",
  style: TextStyle(fontSize: 17),
),
Text(
  " ",
  style: TextStyle(fontSize: 17),
),
Text(
  " ",
  style: TextStyle(fontSize: 17),
),
Text(
  " ",
  style: TextStyle(fontSize: 17),
),
Text(
  " ",
  style: TextStyle(fontSize: 17),
),
Text(
  " ",
),


 RichText(
  text: TextSpan(
    children: [
      TextSpan(
        text: "Student Sign: ",
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      /*TextSpan(
        text: "Indira Gandhi Delhi Technical University for Women",
        style: TextStyle(fontSize: 16),
      ),*/
      WidgetSpan(
        child: SizedBox(
          width: 300, // Adjust the width as needed
          child: TextField(
            onChanged: (newValue) {
              // Update the university name here
              setState(() {
                StudentSign = newValue;
              });
            },
          ),
        ),
      ),

    ],
  ),
),


Text(
  " ",
  style: TextStyle(fontSize: 17),
),
Text(
  "Faculty Sign: ",
  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
),

                // Add more Text widgets here for other data
              ],
            ),
          ),
          );


        },
      ),
    );
  }
}