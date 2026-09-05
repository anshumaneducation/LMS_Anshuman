// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:stela_app/screens/home.dart';
// import 'package:stela_app/screens/student_dashboard.dart';
// import 'package:stela_app/screens/faculty_dashboard.dart';
// import 'package:stela_app/screens/admin_dashboard.dart';

// class AuthGate extends StatelessWidget {
//   const AuthGate({Key? key}) : super(key: key);

//   Future<String?> _resolveUserRole(String uid) async {
//     try {
//       final studentDoc = await FirebaseFirestore.instance.collection('students').doc(uid).get();
//       if (studentDoc.exists) return (studentDoc.data() as Map<String, dynamic>?)?['userRole'] ?? 'Student';

//       final facultyDoc = await FirebaseFirestore.instance.collection('faculty').doc(uid).get();
//       if (facultyDoc.exists) return (facultyDoc.data() as Map<String, dynamic>?)?['userRole'] ?? 'Faculty';

//       final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
//       if (adminDoc.exists) return (adminDoc.data() as Map<String, dynamic>?)?['userRole'] ?? 'Admin';
//     } catch (e) {
//       // ignore and fall through
//       print('Error resolving user role: $e');
//     }
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Scaffold(body: Center(child: CircularProgressIndicator()));
//         }

//         final user = snapshot.data;
//         if (user == null) {
//           // Not signed in
//           return Home();
//         }

//         // Signed in - resolve role and navigate accordingly
//         return FutureBuilder<String?>(
//           future: _resolveUserRole(user.uid),
//           builder: (context, roleSnap) {
//             if (roleSnap.connectionState == ConnectionState.waiting) {
//               return Scaffold(body: Center(child: CircularProgressIndicator()));
//             }

//             final role = roleSnap.data;
//             if (role == null) {
//               // No role doc found - fallback to Home (or force sign out)
//               return Home();
//             }

//             if (role == 'Student') return StudentDashboard();
//             if (role == 'Faculty') return FacultyDashboard();
//             if (role == 'Admin') return AdminDashboard();

//             return Home();
//           },
//         );
//       },
//     );
//   }
// }

// ----------------------------------MSTELA--------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:stela_app/screens/home.dart';
import 'package:stela_app/screens/student_dashboard.dart';
import 'package:stela_app/screens/faculty_dashboard.dart';
import 'package:stela_app/screens/admin_dashboard.dart';
import 'package:stela_app/screens/pending_approval_page.dart';
import 'package:stela_app/screens/rejected_faculty_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  Future<String?> _resolveUserRole(String uid) async {
    try {
      // ADMIN CHECK FIRST
      final adminDoc =
          await FirebaseFirestore.instance.collection('admins').doc(uid).get();

      if (adminDoc.exists) {
        return 'Admin';
      }

      // FACULTY CHECK
      final facultyDoc =
          await FirebaseFirestore.instance.collection('faculty').doc(uid).get();

      if (facultyDoc.exists) {
        return 'Faculty';
      }

      // STUDENT CHECK
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .get();

      if (studentDoc.exists) {
        return 'Student';
      }
    } catch (e) {
      print('Error resolving user role: $e');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        // NOT LOGGED IN
        if (user == null) {
          return Home();
        }

        // LOGGED IN → RESOLVE ROLE
        return FutureBuilder<String?>(
          future: _resolveUserRole(user.uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final role = roleSnap.data;

            // UNKNOWN USER
            if (role == null) {
              // Force logout
              FirebaseAuth.instance.signOut();

              return const Scaffold(
                body: Center(
                  child: Text(
                    'Unauthorized access detected.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              );
            }

            // ROLE ROUTING
            if (role == 'Admin') {
              return AdminDashboard();
            }

            if (role == 'Faculty') {
              return FacultyDashboard();
            }

            if (role == 'Student') {
              return StudentDashboard();
            }

            if (role == 'pending_faculty') {
              return const PendingApprovalPage();
            }

            if (role == 'rejected_faculty') {
              return const RejectedFacultyPage();
            }

            // FALLBACK SECURITY
            FirebaseAuth.instance.signOut();

            return const Scaffold(
              body: Center(
                child: Text(
                  'Invalid role detected.',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
