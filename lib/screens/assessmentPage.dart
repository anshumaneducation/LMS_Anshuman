//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:stela_app/constants/userDetails.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(AssessmentPage());
}

class AssessmentPage extends StatefulWidget {
  @override
  _AssessmentPageState createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  List<String> selectedOptions = ["", "", "", "", "", "", "", "", "", ""];
  bool resultButtonClicked = false; 
  final databaseReference = FirebaseDatabase.instance.ref(); 

  List<String> correctAnswers = [
  // Python basics
  "array",  // Question 1
  "A sequence of numbers",  // Question 2
  "np.arange(10)",  // Question 3
  "read_csv()",  // Question 4
  "scatter()",  // Question 5

  // Libraries
  "sns.boxplot()",  // Question 6
  "Machine Learning models",  // Question 7
  "LSTM",  // Question 8
  "Its dynamic computation graph",  // Question 9
  "Tensors can only have a single data type"  // Question 10
];


  List<List<String>> questions = [
    // Python basics
    [
      "Which of the following is NOT a valid Python data type?",
      "list", "array", "tuple", "dictionary"
    ],
    [
      "What does the range() function in Python return?",
      "A sequence of numbers", "A list of integers", "A dictionary", "A generator object"
    ],
    [
      "Which of the following statements creates a NumPy array with values ranging from 0 to 9?",
      "np.array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])", "np.arange(10)", 
      "np.linspace(0, 9, 10)", "np.zeros(10)"
    ],
    [
      "In Pandas, what method is used to read CSV files?",
      "read_csv()", "load_csv()", "read_file()", "load_file()"
    ],
    [
      "Which function is used to create a scatter plot in Matplotlib?",
      "plot()", "scatter()", "bar()", "line()"
    ],
    // Libraries
    [
      "Which of the following Seaborn functions is used to create a box plot?",
      "sns.boxplot()", "sns.scatterplot()", "sns.lineplot()", "sns.histplot()"
    ],
    [
      "What is TensorFlow primarily used for?",
      "Machine Learning models", "Natural Language Processing (NLP)", 
      "Web development", "Data visualization"
    ],
    [
      "Which of the following algorithms is NOT available in scikit-learn?",
      "LSTM", "Random Forest", "Support Vector Machine (SVM)", "K-means clustering"
    ],
    [
      "What is PyTorch known for in the field of deep learning?",
      "Its dynamic computation graph", "Being a high-level API for TensorFlow", 
      "Its support for SQL databases", "Its compatibility with JavaScript"
    ],
    [
      "Which of the following statements about PyTorch tensors is NOT true?",
      "Tensors can only have a single data type", "Tensors can be created from Python lists", 
      "Tensors support automatic differentiation", "Tensors can be used for GPU-accelerated computations"
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Assessment'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
              for (int i = 0; i < questions.length; i++)
                _buildQuestionWidget(i + 1, questions[i]),
              SizedBox(height: 20),
              ElevatedButton(
                //onPressed: resultButtonClicked ? null : _showResultDialog,
                onPressed: _showResultDialog,
                child: Text('Result'),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
    );
  }

  Widget _buildQuestionWidget(int questionNumber, List<String> question) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Question $questionNumber: ${question[0]}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          for (int i = 1; i < question.length; i++)
            RadioListTile(
              title: Text(question[i]),
              value: question[i],
              groupValue: selectedOptions[questionNumber - 1],
              onChanged: (value) {
                setState(() {
                  selectedOptions[questionNumber - 1] = value.toString(); 
                });
              },
            ),
        ],
      ),
    );
  }

  void _showResultDialog() async {
  int correctCount = 0;
  int incorrectCount = 0;
  int unattemptedCount = 0;
  List<String> result = [];

  for (int i = 0; i < correctAnswers.length; i++) {
    if (selectedOptions[i] == correctAnswers[i]) {
      correctCount++;
      result.add('Correct');
    } else if (selectedOptions[i].isEmpty) {
      unattemptedCount++;
      result.add('Unattempted');
    } else {
      incorrectCount++;
      result.add('Incorrect');
    }
  }

  // Check if the name exists in the database
  DataSnapshot snapshot = await databaseReference.child('AI-PT').child(name).get();

  // If the name does not exist, show the result dialog and add the name with marks
  if (!snapshot.exists) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'RESULT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marks Obtained: $correctCount out of ${correctAnswers.length}',
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 10),
              ...List.generate(
                correctAnswers.length,
                (index) {
                  if (result[index] == 'Correct') {
                    return Text(
                      'Question ${index + 1}: ${result[index]}',
                      style: TextStyle(color: Colors.green),
                    );
                  } else if (result[index] == 'Unattempted') {
                    return Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Question ${index + 1}: Unattempted, ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextSpan(
                            text: 'Correct Answer: ${correctAnswers[index]}',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Question ${index + 1}: Incorrect, ',
                            style: TextStyle(color: Colors.red),
                          ),
                          TextSpan(
                            text: 'Correct Answer: ${correctAnswers[index]}',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                // Add the name with marks to the database
                await databaseReference.child('AI-PT').child(name).set({
                  'Enrollment number': enrollmentNo,
                  'Total marks': correctCount,
                  'Correct': correctCount,
                  'Incorrect': incorrectCount,
                  'Unattempted': unattemptedCount,

                });
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  } else {
    // If the name already exists, show a message indicating that the assessment has already been submitted
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'ASSESSMENT ALREADY SUBMITTED',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Your assessment has already been submitted. You cannot submit it again.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}


}


/*Map<String, dynamic>? data, document;
var userDetails;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(AssessmentPage());
}

class AssessmentPage extends StatefulWidget {
  @override
  _AssessmentPageState createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  List<String> selectedOptions = ["", "", "", "", ""];
  bool resultButtonClicked = false; // To track if result button is clicked
  final databaseReference = FirebaseDatabase.instance.reference(); // Firebase database reference

  // Define the correct answers for each question
  List<String> correctAnswers = ["Paris", "William Shakespeare", "H2O", "Mars", "Leonardo da Vinci"];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Assessment'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
              _buildQuestionWidget(1),
              _buildQuestionWidget(2),
              _buildQuestionWidget(3),
              _buildQuestionWidget(4),
              _buildQuestionWidget(5),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: resultButtonClicked ? null : _showResultDialog, // Disable button after first click
                child: Text('Result'),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(int questionNumber) {
    late String question;
    late List<String> options;

    // Define questions and options based on questionNumber
    switch (questionNumber) {
      case 1:
        question = 'What is the capital of France?';
        options = ['Paris', 'Berlin', 'London', 'Rome'];
        break;
      case 2:
        question = 'Who wrote "Romeo and Juliet"?';
        options = ['William Shakespeare', 'Jane Austen', 'Charles Dickens', 'Mark Twain'];
        break;
      case 3:
        question = 'What is the chemical symbol for water?';
        options = ['H2O', 'CO2', 'NaCl', 'O2'];
        break;
      case 4:
        question = 'Which planet is known as the Red Planet?';
        options = ['Mars', 'Venus', 'Mercury', 'Jupiter'];
        break;
      case 5:
        question = 'Who painted the Mona Lisa?';
        options = ['Leonardo da Vinci', 'Pablo Picasso', 'Vincent van Gogh', 'Michelangelo'];
        break;
      default:
        question = 'Question';
        options = ['Option A', 'Option B', 'Option C', 'Option D'];
    }

    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Question $questionNumber: $question',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          for (var option in options)
            RadioListTile(
              title: Text(option),
              value: option,
              groupValue: selectedOptions[questionNumber - 1],
              onChanged: (value) {
                setState(() {
                  selectedOptions[questionNumber - 1] = value.toString(); // Ensure value is converted to String
                });
              },
            ),
        ],
      ),
    );
  }

  void _showResultDialog() async {
    int correctCount = 0;
    List<String> result = [];
    

    for (int i = 0; i < correctAnswers.length; i++) {
  if (selectedOptions[i] == correctAnswers[i]) {
    correctCount++;
    result.add('Correct');
  } else if (selectedOptions[i] == null || selectedOptions[i].isEmpty) {
    result.add('Unattempted, Correct Answer: ${correctAnswers[i]}');
  } else {
    result.add('Incorrect, Correct Answer: ${correctAnswers[i]}');
  }
}



    // Upload marks to Firebase
    databaseReference.child(name).get().then((DataSnapshot snapshot) {
  if (!snapshot.exists) {
    // Name does not exist in the database, so we add it
    return databaseReference.child(name).set({
      'marks': correctCount,
    });
  }
}).catchError((error) {
  print('Error fetching data: $error');
});





    setState(() {
      resultButtonClicked = true;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'RESULT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
  correctAnswers.length,
  (index) {
    if (result[index] == 'Correct') {
      return Text(
        'Question ${index + 1}: ${result[index]}',
        style: TextStyle(color: Colors.green),
      );
    } else if (result[index] == 'Unattempted') {
      return Text(
        'Question ${index + 1}: Unattempted, Correct Answer: ${correctAnswers[index]}',
        style: TextStyle(color: Colors.yellow),
      );
    } else {
      return Text(
        'Question ${index + 1}: Incorrect, Correct Answer: ${correctAnswers[index]}',
        style: TextStyle(color: Colors.red),
      );
    }
  }
),

          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
*/

/*import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stela_app/constants/colors.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:stela_app/constants/experimentDesc.dart';
import 'package:stela_app/screens/BasicsexperimentList.dart'
    as BasicsexperimentList;
import 'package:stela_app/screens/NumpyexperimentList copy.dart';
import 'package:stela_app/screens/MatplotlibexperimentList copy.dart';
import 'package:stela_app/screens/PandasexperimentList copy.dart';
import 'package:stela_app/screens/SeabornexperimentList copy.dart';
import 'package:stela_app/screens/TensorflowexperimentList copy.dart';
import 'package:stela_app/screens/SklearnexperimentList copy.dart';
import 'package:stela_app/screens/KerasexperimentList copy.dart';
import 'package:stela_app/screens/PytorchexperimentList copy.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stela_app/constants/userDetails.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(AssessmentPage());
}

class AssessmentPage extends StatefulWidget {
  @override
  _AssessmentPageState createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  List<String> selectedOptions = ["", "", "", "", ""];

  // Define the correct answers for each question
  List<String> correctAnswers = ["Paris", "Option B", "Option C", "Option D", "Option A"];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Assessment'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
              _buildQuestionWidget(1),
              _buildQuestionWidget(2),
              _buildQuestionWidget(3),
              _buildQuestionWidget(4),
              _buildQuestionWidget(5),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showResultDialog,
                child: Text('Result'),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(int questionNumber) {
  late String question;
  late List<String> options;

  // Define questions and options based on questionNumber
  switch (questionNumber) {
    case 1:
      question = 'What is the capital of France?';
      options = ['Paris', 'Berlin', 'London', 'Rome'];
      break;
    case 2:
      question = 'Who wrote "Romeo and Juliet"?';
      options = ['William Shakespeare', 'Jane Austen', 'Charles Dickens', 'Mark Twain'];
      break;
    case 3:
      question = 'What is the chemical symbol for water?';
      options = ['H2O', 'CO2', 'NaCl', 'O2'];
      break;
    case 4:
      question = 'Which planet is known as the Red Planet?';
      options = ['Mars', 'Venus', 'Mercury', 'Jupiter'];
      break;
    case 5:
      question = 'Who painted the Mona Lisa?';
      options = ['Leonardo da Vinci', 'Pablo Picasso', 'Vincent van Gogh', 'Michelangelo'];
      break;
    default:
      question = 'Question';
      options = ['Option A', 'Option B', 'Option C', 'Option D'];
  }

  return Padding(
    padding: EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Question $questionNumber: $question',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        for (var option in options)
          RadioListTile(
            title: Text(option),
            value: option,
            groupValue: selectedOptions[questionNumber - 1],
            onChanged: (value) {
              setState(() {
                selectedOptions[questionNumber - 1] = value.toString(); // Ensure value is converted to String
              });
            },
          ),
      ],
    ),
  );
}



  void _showResultDialog() {
    int correctCount = 0;
    for (int i = 0; i < correctAnswers.length; i++) {
      if (selectedOptions[i] == correctAnswers[i]) {
        correctCount++;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
          'RESULT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      
          content: Text('Marks: $correctCount/ ${correctAnswers.length}'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}*/


