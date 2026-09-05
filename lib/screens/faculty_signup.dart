import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/screens/subjects.dart';
import 'package:stela_app/screens/signup.dart';
import 'package:stela_app/screens/login.dart';
import 'package:stela_app/screens/home.dart';
import 'package:stela_app/screens/faculty_dashboard.dart';
import 'package:stela_app/screens/pending_approval_page.dart';
import 'package:stela_app/services/role_service.dart';

class FacultySignUp extends StatefulWidget {
  @override
  _FacultySignUpState createState() => _FacultySignUpState();
}

class _FacultySignUpState extends State<FacultySignUp> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  String _name = '';
  String _email = '';
  String _password = '';
  String _contact = '';
  String _teacherCode = '';
  bool _loading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account as Faculty',
            style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBar,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => Home()),
            (route) => false,
          ),
        ),
      ),
      body: Center(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          thickness: 10,
          radius: Radius.circular(8),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Container(
              constraints: BoxConstraints(maxWidth: 600),
              padding: EdgeInsets.all(20),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 6,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with avatar
                        Column(
                          children: [
                            CircleAvatar(
                                radius: 36,
                                backgroundColor: primaryBar,
                                child: Icon(Icons.person,
                                    color: Colors.white, size: 36)),
                            SizedBox(height: 12),
                            Text('Create Faculty Account',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBar)),
                            SizedBox(height: 12),
                          ],
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                              hintText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline,
                                  color: primaryBar.withOpacity(0.8))),
                          onChanged: (v) => _name = v,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Name required'
                              : null,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                              hintText: 'Teacher Code',
                              prefixIcon: Icon(Icons.badge_outlined,
                                  color: primaryBar.withOpacity(0.8))),
                          onChanged: (v) => _teacherCode = v,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Teacher code required';
                            final name = _name.trim();
                            if (name.isEmpty) return 'Enter full name first';
                            final parts = name.split(RegExp(r"\s+"));
                            if (parts.length < 2)
                              return 'Enter first and last name to generate code';
                            final expected =
                                (parts.first[0] + parts.last).toLowerCase();
                            final provided = v.trim().toLowerCase();
                            if (provided != expected)
                              return 'Teacher code should be "$expected" based on your name';
                            return null;
                          },
                        ),
                        SizedBox(height: 12),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                              hintText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone,
                                  color: primaryBar.withOpacity(0.8))),
                          keyboardType: TextInputType.phone,
                          onChanged: (v) => _contact = v,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Contact required'
                              : null,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                              hintText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: primaryBar.withOpacity(0.8))),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (v) => _email = v,
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Valid email required'
                              : null,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: primaryBar.withOpacity(0.8))),
                          obscureText: true,
                          onChanged: (v) => _password = v,
                          validator: (v) => v == null || v.length < 6
                              ? 'Password >= 6 chars'
                              : null,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                              hintText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: primaryBar.withOpacity(0.8))),
                          obscureText: true,
                          onChanged: (v) {},
                          validator: (v) => v == null || v != _password
                              ? 'Passwords do not match'
                              : null,
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: primaryButton,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: _loading
                                ? CircularProgressIndicator()
                                : Text('Sign Up',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                        SizedBox(height: 12),
                        // Link back to the student signup page
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Are you student?',
                                style: TextStyle(
                                    color: primaryBar.withOpacity(0.8))),
                            TextButton(
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => SignUp())),
                              child: Text('Sign up as Student',
                                  style: TextStyle(color: primaryButton)),
                            )
                          ],
                        ),

                        SizedBox(height: 16),
                        // Login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: primaryBar.withOpacity(0.7),
                                fontSize: 14,
                                fontFamily: 'PTSerif',
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => Login()),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Log In',
                                style: TextStyle(
                                  color: primaryButton,
                                  fontSize: 14,
                                  fontFamily: 'PTSerif',
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
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
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // Clear stale cached role before creating account
    await RoleService.clearCachedRole();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: _email, password: _password);
      final uid = cred.user?.uid;
      await FirebaseFirestore.instance.collection('faculty').doc(uid).set({
        'name': _name,
        'email': _email,
        'contactNumber': _contact,
        'teacherCode': _teacherCode,
        'userRole': 'pending_faculty',
        'approved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Refresh role cache and in-memory details after signup
      await RoleService.fetchAndCacheRole();
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => PendingApprovalPage()));
    } catch (e) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                  title: Text('Signup failed'),
                  content: Text(e.toString()),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'))
                  ]));
    } finally {
      setState(() => _loading = false);
    }
  }
}
