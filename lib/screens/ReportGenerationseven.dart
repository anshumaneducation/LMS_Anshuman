import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:signature/signature.dart';
import 'package:stela_app/constants/userDetails.dart'; // Import the signature package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PdfPageseven(),
    );
  }
}

class PdfPageseven extends StatefulWidget {
  @override
  _PdfPagesevenState createState() => _PdfPagesevenState();
}

class _PdfPagesevenState extends State<PdfPageseven> {
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
  Uint8List? facultySign; // Uint8List to hold signature image data

  late Future<void> _fetchDataFuture;
  final _controller = SignatureController(
    penStrokeWidth: 5, // Set the stroke width here
  );

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = fetchDataFromDatabase();
  }

  Future<void> fetchDataFromDatabase() async {
    final databaseReference = FirebaseDatabase.instance.ref();

    final DatabaseEvent event = await databaseReference
        .child('AIPT coding-TEST')
        .child(enrollmentNo)
        .child('Experiment 7')
        .once();
    if (event.snapshot.value != null) {
      Map<dynamic, dynamic>? values =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (values is Map<String, dynamic>) {
        setState(() {
          totalMarks = values['1_Total marks'].toString();
          code = values['9_Code'].toString();
          starttime = values['7_Start time'].toString();
          endtime = values['8_End time'].toString();
          expname = values['10_Aim'].toString();
          duration = values['11_Duration'].toString();
          universityName = values['12_University Name'].toString();

          CourseName = values['13_Course Name'].toString();

          examTypeName = values['14_Exam Type'].toString();

          place = values['15_Place'].toString();
        });
      }
    }
  }

  Future<void> _printPdf() async {
    final pdf = pw.Document();

    // Your content data with nullable string values
    List<Map<String, String?>> contentData = [
      {"label": "University Name", "value": universityName},
      {"label": "Course Name", "value": CourseName},
      {"label": "Exam Type", "value": examTypeName},
      {"label": "Place", "value": place},
      {"label": "Student Name", "value": name},
      {"label": "Enrollment Number", "value": enrollmentNo},
      {"label": "Name of experiment", "value": expname},
      {"label": "Start time", "value": starttime},
      {"label": "End time", "value": endtime},
      {"label": "Total Duration", "value": duration},
      {"label": "Total Marks", "value": totalMarks},
      {"label": "Student Sign", "value": StudentSign},
      {"label": "Faculty Sign", "value": null},
      {"label": "Source Code", "value": code}, // Placeholder for faculty sign
    ];

    // Function to add a new page with content
    void addPageContent(List<Map<String, String?>> content, bool isFirstPage) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            List<pw.Widget> pageChildren = [];

            if (isFirstPage) {
              pageChildren.add(
                pw.Center(
                  child: pw.Text(
                    'Report of Experiment 7', // Your heading text
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );
              pageChildren.add(pw.SizedBox(height: 10));
            }

            // Iterate over content items
            for (var item in content) {
              // If the item is the code, split it into sections of 10 lines each
              if (item["label"] == "Source Code") {
                // Add heading for source code
                pageChildren.add(pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Source Code: ',
                        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ));
                pageChildren.add(pw.SizedBox(height: 10)); // Add spacing

                String code = item["value"] ?? ''; // Get code value
                List<String> codeLines = code.split('\n'); // Split code into lines

                // Iterate through code lines and add them to pages
                for (int i = 0; i < codeLines.length; i += 30) {
                  int endIndex = i + 30;
                  if (endIndex > codeLines.length) {
                    endIndex = codeLines.length;
                  }

                  // Join lines into a single string
                  String codeSection = codeLines.sublist(i, endIndex).join('\n');

                  // Add code section as a paragraph
                  pageChildren.add(pw.Paragraph(
                    text: codeSection,
                    style: pw.TextStyle(fontSize: 16),
                  ));
                  pageChildren.add(pw.SizedBox(height: 10)); // Add spacing

                  // Check if we need to add a new page for the remaining code
                  if ((endIndex < codeLines.length || i != 0) && i != 0) {
                    pdf.addPage(pw.Page(
                      build: (pw.Context context) {
                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Do not add the heading for source code on subsequent pages
                            pw.SizedBox(height: 10), // Add spacing
                            // Add remaining code section
                            pw.Paragraph(
                              //text: codeLines.sublist(endIndex).join('\n'),
                              text: codeSection,
                              style: pw.TextStyle(fontSize: 16),
                            ),
                          ],
                        );
                      },
                    ));
                  }
                }
              } 
              else if(item["label"] == "Faculty Sign") {
                // For other items, add them as RichText
              pageChildren.add(
  pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: '${item["label"]}: ',
          style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
        ),
        pw.WidgetSpan(
          child: pw.Center(
            child: pw.Image(
              pw.MemoryImage(facultySign!),
              width: 200,
              height: 100,
            ),
          ),
        ),
      ],
    ),
  ),
);
pageChildren.add(pw.SizedBox(height: 10)); // Add spacing
 // Add spacing
              }
            else {
                // For other items, add them as RichText
                pageChildren.add(pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: '${item["label"]}: ',
                        style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(
                        text: item["value"] ?? '', // Handle null value here
                        style: pw.TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ));
                pageChildren.add(pw.SizedBox(height: 10)); // Add spacing
              }
            }

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: pageChildren,
            );
          },
        ),
      );
    }

    // Determine number of content items per page
    final int itemsPerPage = 13;
    for (int i = 0; i < contentData.length; i += itemsPerPage) {
      int endIndex = i + itemsPerPage;
      if (endIndex > contentData.length) {
        endIndex = contentData.length;
      }
      // Check if it's the first page
      bool isFirstPage = (i == 0);
      addPageContent(contentData.sublist(i, endIndex), isFirstPage);
    }

    // Add faculty sign if available

    // Save and print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
 void _captureFacultySign() async {
  final Uint8List? data = await _controller.toPngBytes();
  if (data != null) {
    setState(() {
      facultySign = data;
    });
  } else {
    // Handle the case when the data is null, maybe show an error message
    print("Error: Signature data is null");
  }
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
                          text: 'Report of Experiment 7', // Your heading text
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
                  // Add other data widgets...
                  SizedBox(height: 10),
                  Text(
                    "Faculty Sign (Please sign by dragging on touchpad with a click, and do capture it, only then report will be generated):",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  // Signature Pad for faculty sign
                  Signature(
                    controller: _controller,
                    height: 200,
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _captureFacultySign,
                    child: Text('Capture Faculty Sign'),
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
