import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/constants/userDetails.dart';
import 'package:stela_app/screens/student_dashboard.dart';
import 'package:stela_app/screens/faculty_dashboard.dart';
import 'package:stela_app/screens/admin_dashboard.dart';
import 'package:stela_app/screens/pending_approval_page.dart';
import 'package:stela_app/screens/rejected_faculty_page.dart';
import 'package:stela_app/screens/signup.dart';
import 'package:stela_app/services/role_service.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _keepLoggedIn = false;
  String email = "", password = "", role = "";
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final keepLoggedIn = prefs.getBool('keepLoggedIn') ?? false;
    final savedEmail = prefs.getString('lastEmail') ?? '';

    if (keepLoggedIn && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        email = savedEmail;
        _keepLoggedIn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: primaryWhite,
        appBar: AppBar(
          title: Text(
            'STELA',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'PTSerif-Bold',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: primaryBar,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.all(32),
              margin: EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryBar.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Logo/Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: primaryBar,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryBar.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    SizedBox(height: 24),

                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontFamily: 'PTSerif-Bold',
                        fontWeight: FontWeight.bold,
                        color: primaryBar,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sign in to your account',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'PTSerif',
                        color: primaryBar.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 32),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      textAlign: TextAlign.left,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => email = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        } else if (!value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Email Address",
                        hintStyle: TextStyle(
                          color: primaryBar.withOpacity(0.5),
                          fontFamily: 'PTSerif',
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: primaryBar.withOpacity(0.7),
                        ),
                        filled: true,
                        fillColor: primaryWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: primaryBar.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: primaryBar.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: primaryButton, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Password Field with Eye Icon
                    TextFormField(
                      controller: _passwordController,
                      textAlign: TextAlign.left,
                      obscureText: _obscurePassword,
                      onChanged: (value) => password = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Password",
                        hintStyle: TextStyle(
                          color: primaryBar.withOpacity(0.5),
                          fontFamily: 'PTSerif',
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: primaryBar.withOpacity(0.7),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: primaryBar.withOpacity(0.7),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: primaryWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: primaryBar.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: primaryBar.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: primaryButton, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _showResetPasswordDialog(context);
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: primaryButton,
                            fontSize: 14,
                            fontFamily: 'PTSerif',
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Keep Logged In Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _keepLoggedIn,
                          onChanged: (value) {
                            setState(() {
                              _keepLoggedIn = value ?? false;
                            });
                          },
                          activeColor: primaryButton,
                          side: BorderSide(
                            color: primaryBar.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Keep me logged in',
                            style: TextStyle(
                              color: primaryBar.withOpacity(0.7),
                              fontSize: 14,
                              fontFamily: 'PTSerif',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),

                    // Login Button
                    isLoading
                        ? Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: primaryButton.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(primaryBar),
                              ),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryButton,
                                foregroundColor: primaryBar,
                                elevation: 4,
                                shadowColor: primaryButton.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'PTSerif-Bold',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    SizedBox(height: 24),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: primaryBar.withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: 'PTSerif',
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SignUp()),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign Up',
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
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      email = _emailController.text;
      password = _passwordController.text;

      // Clear any stale cached role before authenticating
      await RoleService.clearCachedRole();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("✅ Firebase login successful");

      // Fetch authoritative role from Firestore and cache it
      final freshRole = await RoleService.fetchAndCacheRole();

      // Save "Keep me logged in" preference
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (_keepLoggedIn) {
        await prefs.setBool('keepLoggedIn', true);
        await prefs.setString('lastEmail', email);
      } else {
        await prefs.setBool('keepLoggedIn', false);
        await prefs.remove('lastEmail');
      }

      final navigateRole = freshRole ?? 'Student';
      if (navigateRole == 'Student') {
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => StudentDashboard()));
      } else if (navigateRole == 'Faculty') {
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => FacultyDashboard()));
      } else if (navigateRole == 'Admin') {
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => AdminDashboard()));
      } else if (navigateRole == 'pending_faculty') {
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => PendingApprovalPage()));
      } else if (navigateRole == 'rejected_faculty') {
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => RejectedFacultyPage()));
      } else {
        throw Exception('Invalid user role: $navigateRole');
      }
    } catch (e) {
      print("❌ Login Exception: $e");
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Login Failed"),
          content: Text("Wrong credentials or no user role found."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showResetPasswordDialog(BuildContext context) {
    String resetEmail = '';

    // Capture the parent context (the one that contains the Scaffold) so
    // we can show a SnackBar after closing the dialog. The dialog's
    // builder provides a new context that is NOT a descendant of the
    // page's Scaffold, so calling ScaffoldMessenger.of(dialogContext)
    // would fail.
    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Reset Password"),
          content: TextField(
            onChanged: (value) => resetEmail = value,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Enter your email",
            ),
          ),
          actions: [
            TextButton(
                child: Text("Send"),
                // deprecated
                // onPressed: () async {
                //   if (resetEmail.isEmpty || !resetEmail.contains('@')) {
                //     Navigator.pop(dialogContext);
                //     ScaffoldMessenger.of(parentContext).showSnackBar(
                //         SnackBar(content: Text("Enter a valid email address.")));
                //     return;
                //   }

                //   try {
                //     // Check whether an account exists for this email. If there
                //     // are no providers returned, there's no user registered with
                //     // that email and Firebase may not send a reset link.
                //     final methods =
                //         await _auth.fetchSignInMethodsForEmail(resetEmail);
                //     if (methods.isEmpty) {
                //       Navigator.pop(dialogContext);
                //       ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(
                //           content: Text("No account found for $resetEmail")));
                //       return;
                //     }

                //     await _auth.sendPasswordResetEmail(email: resetEmail);
                //     Navigator.pop(dialogContext);
                //     ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(
                //         content: Text("Reset link sent to $resetEmail")));
                //   } on FirebaseAuthException catch (e) {
                //     Navigator.pop(dialogContext);
                //     // Show the FirebaseAuthException message which is more
                //     // descriptive (e.g. user-not-found, invalid-email, etc.).
                //     ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(
                //         content:
                //             Text("Failed to send reset link: ${e.message}")));
                //   } catch (e) {
                //     Navigator.pop(dialogContext);
                //     ScaffoldMessenger.of(parentContext).showSnackBar(
                //         SnackBar(content: Text("Failed to send reset link: $e")));
                //   }
                // },
                onPressed: () async {
                  if (resetEmail.isEmpty || !resetEmail.contains('@')) {
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text("Enter a valid email address."),
                      ),
                    );

                    return;
                  }

                  try {
                    await _auth.sendPasswordResetEmail(
                      email: resetEmail.trim(),
                    );

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "If an account exists, a reset link has been sent.",
                        ),
                      ),
                    );
                  } on FirebaseAuthException catch (e) {
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.message ?? "Failed to send reset email",
                        ),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Something went wrong: $e",
                        ),
                      ),
                    );
                  }
                }),
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        );
      },
    );
  }
}
