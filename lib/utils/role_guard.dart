import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleGuard {
  // GET CURRENT USER
  static User? get currentUser => FirebaseAuth.instance.currentUser;

  // CHECK LOGGED IN
  static bool isLoggedIn() {
    return currentUser != null;
  }

  static String? _normalizeRole(String? role) {
    if (role == null) return null;
    switch (role.toString().toLowerCase()) {
      case 'admin':
      case 'administrator':
        return 'Admin';
      case 'faculty':
      case 'approved_faculty':
        return 'Faculty';
      case 'pending_faculty':
        return 'pending_faculty';
      case 'rejected_faculty':
        return 'rejected_faculty';
      case 'student':
        return 'Student';
      default:
        return null;
    }
  }

  static Future<String?> _getRoleFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, String fallbackRole) async {
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return fallbackRole;
    final roleField = data['userRole'] ?? data['role'];
    return _normalizeRole(roleField?.toString()) ?? fallbackRole;
  }

  // GET USER ROLE
  static Future<String?> getUserRole() async {
    try {
      final user = currentUser;

      if (user == null) {
        return null;
      }

      final uid = user.uid;

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();
      final adminRole = await _getRoleFromDoc(adminDoc, 'Admin');
      if (adminRole != null) {
        return adminRole;
      }

      final facultyDoc = await FirebaseFirestore.instance
          .collection('faculty')
          .doc(uid)
          .get();
      final facultyRole = await _getRoleFromDoc(facultyDoc, 'Faculty');
      if (facultyRole != null) {
        return facultyRole;
      }

      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .get();
      final studentRole = await _getRoleFromDoc(studentDoc, 'Student');
      if (studentRole != null) {
        return studentRole;
      }

      return null;
    } catch (e) {
      print('RoleGuard Error: $e');
      return null;
    }
  }

  // IS ADMIN
  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'Admin';
  }

  // IS FACULTY
  static Future<bool> isFaculty() async {
    final role = await getUserRole();
    return role == 'Faculty';
  }

  // IS STUDENT
  static Future<bool> isStudent() async {
    final role = await getUserRole();
    return role == 'Student';
  }

  // HAS PENDING FACULTY STATUS
  static Future<bool> isPendingFaculty() async {
    final role = await getUserRole();
    return role == 'pending_faculty';
  }

  // HAS REJECTED FACULTY STATUS
  static Future<bool> isRejectedFaculty() async {
    final role = await getUserRole();
    return role == 'rejected_faculty';
  }

  // SIGN OUT
  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
