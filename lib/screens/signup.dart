// Student & Faculty Signup
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/screens/home.dart';
import 'package:stela_app/screens/student_dashboard.dart';
import 'package:stela_app/screens/faculty_signup.dart';
import 'package:stela_app/screens/login.dart';
import 'package:stela_app/screens/faculty_dashboard.dart';
import 'package:stela_app/screens/pending_approval_page.dart';
import 'package:stela_app/services/role_service.dart';

class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _studentFormKey = GlobalKey<FormState>();
  final _facultyFormKey = GlobalKey<FormState>();

  // UI state
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // UI: whether faculty form is shown below student
  bool _showFaculty = false;
  final ScrollController _scrollController = ScrollController();

  // Student fields
  String _name = "", _enrollment = "", _contact = "", _email = "";
  String _password = "";
  String? _branch;
  DateTime? _dob;
  bool _noEnrollment = false;

  // Faculty fields
  String _facultyName = "", _facultyEmail = "", _facultyPassword = "";
  String? _facultySubject;

  final List<String> _branches = ['CSE', 'ECE', 'IT', 'ME', 'CE'];

  @override
  void initState() {
    super.initState();
    // ensure scrollbar visibility
    // no-op here; controller created above
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: primaryWhite,
        appBar: AppBar(
          title: Text('Create Account as Student',
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
            thickness: 10,
            radius: Radius.circular(8),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Container(
                constraints: BoxConstraints(maxWidth: 760),
                padding: EdgeInsets.all(28),
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 18),

                    // Student Card (prominent)
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Form(
                          key: _studentFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Decorative gradient header
                              Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [primaryBar, primaryButton]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.school, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Student Signup',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildStudentForm(),
                              SizedBox(height: 14),
                              _buildSignupButton(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),
                    // Faculty navigation (opens a new page)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Are you faculty?',
                            style:
                                TextStyle(color: primaryBar.withOpacity(0.8))),
                        TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => FacultySignUp())),
                          child: Text('Sign up as Faculty',
                              style: TextStyle(color: primaryButton)),
                        )
                      ],
                    ),

                    SizedBox(height: 20),
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
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: primaryBar,
          child: Icon(Icons.person_add, color: Colors.white, size: 36),
        ),
        SizedBox(height: 16),
        Text('Create Student Account',
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: primaryBar)),
        SizedBox(height: 6),
        Text('Register as a student to access learning resources',
            style: TextStyle(fontSize: 14, color: primaryBar.withOpacity(0.7))),
      ],
    );
  }

  // role tabs removed - using a prominent student card with optional faculty section below

  // ---------------- Student Form ----------------
  Widget _buildStudentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputField(
          hint: 'Full Name',
          prefixIcon: Icons.person_outline,
          onChanged: (v) => _name = v,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Name required' : null,
        ),
        SizedBox(height: 12),
        InputField(
          hint: 'Phone Number',
          prefixIcon: Icons.phone,
          keyboard: TextInputType.phone,
          onChanged: (v) => _contact = v,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Contact required' : null,
        ),
        SizedBox(height: 12),
        // Enrollment with toggle
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _noEnrollment
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DisabledField(
                            hint: 'Generated Temporary ID', value: _enrollment),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                _generateTempId();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Temporary ID regenerated')));
                              },
                              icon: Icon(Icons.refresh),
                              label: Text('Regenerate'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBar),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: _enrollment));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Copied temporary ID')));
                              },
                              icon: Icon(Icons.copy),
                              label: Text('Copy ID'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryButton),
                            ),
                          ],
                        ),
                      ],
                    )
                  : InputField(
                      hint: 'Enrollment Number',
                      prefixIcon: Icons.badge_outlined,
                      onChanged: (v) => _enrollment = v,
                      validator: (v) => _noEnrollment
                          ? null
                          : (v == null || v.trim().isEmpty
                              ? 'Enrollment required'
                              : null),
                    ),
            ),
            SizedBox(width: 8),
            Column(
              children: [
                Checkbox(
                  value: _noEnrollment,
                  onChanged: (val) {
                    setState(() {
                      _noEnrollment = val ?? false;
                      if (_noEnrollment)
                        _generateTempId();
                      else
                        _enrollment = '';
                    });
                  },
                ),
                Text("I don't have an Enrollment Number",
                    style: TextStyle(fontSize: 10)),
              ],
            )
          ],
        ),
        SizedBox(height: 12),
        DropdownField(
          hint: 'Branch',
          items: _branches,
          value: _branch,
          onChanged: (v) => setState(() => _branch = v),
          validator: (v) => v == null || v.isEmpty ? 'Select branch' : null,
        ),
        if (_noEnrollment && (_branch == null || _branch!.isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
                'Enter your branch to generate a complete temporary ID.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        SizedBox(height: 12),
        DatePickerField(
          hint: 'Date of Birth',
          value: _dob,
          onChanged: (d) => setState(() => _dob = d),
          validator: (d) => d == null ? 'DOB required' : null,
        ),
        if (_noEnrollment && _dob == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
                'Enter your DOB; the temporary ID uses DDMMYYYY format as suffix.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        SizedBox(height: 12),
        InputField(
          hint: 'Email Address',
          prefixIcon: Icons.email_outlined,
          keyboard: TextInputType.emailAddress,
          onChanged: (v) => _email = v,
          validator: (v) =>
              v == null || !v.contains('@') ? 'Valid email required' : null,
        ),
        SizedBox(height: 12),
        InputField(
          hint: 'Password',
          obscure: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          suffix: IconButton(
            icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          onChanged: (v) => _password = v,
          validator: (v) =>
              v == null || v.length < 6 ? 'Password >= 6 chars' : null,
        ),
        SizedBox(height: 12),
        InputField(
          hint: 'Confirm Password',
          obscure: _obscureConfirmPassword,
          prefixIcon: Icons.lock_outline,
          suffix: IconButton(
            icon: Icon(_obscureConfirmPassword
                ? Icons.visibility_off
                : Icons.visibility),
            onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          onChanged: (v) {},
          validator: (v) =>
              v == null || v != _password ? 'Passwords do not match' : null,
        ),
      ],
    );
  }

  // Faculty form moved to a separate page `faculty_signup.dart`

  // ---------------- Helpers & Widgets ----------------
  void _generateTempId() {
    // format: firstname_branch_ddmmyyyy
    final first =
        (_name.trim().isEmpty ? 'user' : _name.split(' ').first).toLowerCase();
    final branch = (_branch ?? 'GEN').replaceAll(' ', '_');
    final dobStr = _dob == null
        ? 'nodob'
        : '${_dob!.day.toString().padLeft(2, '0')}${_dob!.month.toString().padLeft(2, '0')}${_dob!.year}';
    setState(() {
      _enrollment = '${first}_${branch}_$dobStr';
    });
  }

  Widget _buildSignupButton() {
    return isLoading
        ? Container(
            height: 56, child: Center(child: CircularProgressIndicator()))
        : SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                // Immediate UI feedback to confirm button press
                try {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Signing up...')));
                } catch (e) {
                  // ignore if scaffold not ready
                }
                await _submit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryButton,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Sign Up',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          );
  }

  // Submit handler for both tabs
  Future<void> _submit() async {
    print('SignUp._submit() called; _showFaculty=$_showFaculty');
    // Determine which form to validate based on visibility
    if (_showFaculty) {
      // If faculty section is shown and user is signing up as faculty, validate faculty form
      if (!_facultyFormKey.currentState!.validate()) return;
    } else {
      if (!_studentFormKey.currentState!.validate()) return;
    }

    setState(() => isLoading = true);
    // Clear any stale cached role/session before starting signup
    await RoleService.clearCachedRole();
    try {
      if (!_showFaculty) {
        // Student signup
        if (_noEnrollment && _enrollment.isEmpty) _generateTempId();
        final cred = await _auth.createUserWithEmailAndPassword(
            email: _email, password: _password);
        final uid = cred.user?.uid;
        await FirebaseFirestore.instance.collection('students').doc(uid).set({
          'name': _name,
          'email': _email,
          'contactNumber': _contact,
          'branch': _branch,
          'dateOfBirth': _dob?.toIso8601String(),
          'enrollmentNumber': _enrollment,
          'userRole': 'Student',
        });

        // Ensure Firestore was updated and role cache is refreshed
        await RoleService.fetchAndCacheRole();
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => StudentDashboard()));
      } else {
        // Faculty signup
        final cred = await _auth.createUserWithEmailAndPassword(
            email: _facultyEmail, password: _facultyPassword);
        final uid = cred.user?.uid;
        await FirebaseFirestore.instance.collection('faculty').doc(uid).set({
          'name': _facultyName,
          'email': _facultyEmail,
          'subject': _facultySubject,
          'userRole': 'pending_faculty',
          'approved': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Refresh cached role and in-memory details, then navigate to pending page
        await RoleService.fetchAndCacheRole();
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => PendingApprovalPage()));
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Signup Failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('OK'))
          ],
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}

// Simple reusable widgets kept local for brevity
class InputField extends StatelessWidget {
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType keyboard;
  final void Function(String) onChanged;
  final String? Function(String?)? validator;

  const InputField(
      {Key? key,
      required this.hint,
      this.prefixIcon,
      this.suffix,
      this.obscure = false,
      this.keyboard = TextInputType.text,
      required this.onChanged,
      this.validator})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: obscure,
      keyboardType: keyboard,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: primaryBar.withOpacity(0.8))
            : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: primaryWhite,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBar.withOpacity(0.2))),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class DisabledField extends StatelessWidget {
  final String hint;
  final String value;
  const DisabledField({Key? key, required this.hint, required this.value})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
            Icon(Icons.info_outline, color: primaryBar.withOpacity(0.6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class DropdownField extends StatelessWidget {
  final String hint;
  final List<String> items;
  final String? value;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const DropdownField(
      {Key? key,
      required this.hint,
      required this.items,
      this.value,
      required this.onChanged,
      this.validator})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        return InputDecorator(
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(Icons.list, color: primaryBar.withOpacity(0.7)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.value,
              isExpanded: true,
              onChanged: (v) {
                state.didChange(v);
                onChanged(v);
              },
              items: items
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

class DatePickerField extends StatelessWidget {
  final String hint;
  final DateTime? value;
  final void Function(DateTime?) onChanged;
  final String? Function(DateTime?)? validator;

  const DatePickerField(
      {Key? key,
      required this.hint,
      this.value,
      required this.onChanged,
      this.validator})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: value,
      validator: (d) => this.validator == null ? null : this.validator!(d),
      builder: (state) {
        return GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime(2000, 1, 1),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              state.didChange(picked);
              onChanged(picked);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(Icons.calendar_today,
                  color: primaryBar.withOpacity(0.7)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(state.value == null
                ? ''
                : '${state.value!.day}-${state.value!.month}-${state.value!.year}'),
          ),
        );
      },
    );
  }
}
