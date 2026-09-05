import 'package:flutter/material.dart';
import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/screens/login.dart';
import 'package:stela_app/screens/signup.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBar,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              width: constraints.maxWidth > 600
                  ? constraints.maxWidth * 0.4
                  : double.infinity,
              padding: EdgeInsets.all(
                constraints.maxWidth > 600 ? 40 : 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: constraints.maxWidth > 600 ? 80 : 50),
                  // Responsive logo
                  Container(
                    width: constraints.maxWidth > 600 ? 300 : 200,
                    // child: Image.asset('assets/images/STELA.png')
                    child: Image.asset('assets/images/anshuman.png'),
                  ),
                  SizedBox(height: constraints.maxWidth > 600 ? 60 : 40),
                  // Login Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryWhite,
                        padding: EdgeInsets.symmetric(
                          vertical: constraints.maxWidth > 600 ? 20 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        side: BorderSide(
                          color: primaryButton,
                          width: 2.0,
                        ),
                      ),
                      child: Text(
                        'LOG IN',
                        style: TextStyle(
                          fontSize: constraints.maxWidth > 600 ? 18 : 15,
                          fontFamily: 'PTSerif-Bold',
                          fontWeight: FontWeight.bold,
                          color: primaryButton,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: constraints.maxWidth > 600 ? 24 : 15),
                  // Sign Up Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUp()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryWhite,
                        padding: EdgeInsets.symmetric(
                          vertical: constraints.maxWidth > 600 ? 20 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        side: BorderSide(
                          color: primaryButton,
                          width: 2.0,
                        ),
                      ),
                      child: Text(
                        'SIGN UP',
                        style: TextStyle(
                          fontSize: constraints.maxWidth > 600 ? 18 : 15,
                          fontFamily: 'PTSerif-Bold',
                          fontWeight: FontWeight.bold,
                          color: primaryButton,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
