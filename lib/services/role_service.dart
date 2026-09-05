import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stela_app/constants/userDetails.dart' as UD;
import 'package:stela_app/utils/role_guard.dart';

class RoleService {
  /// Clears any locally cached role/session state.
  static Future<void> clearCachedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userRole');
    } catch (e) {
      // ignore prefs errors
    }
    // Clear in-memory globals
    UD.userUID = null;
    UD.userRole = '';
  }

  /// Fetches the authoritative role for the currently signed-in Firebase user,
  /// updates SharedPreferences and the in-memory user details by calling
  /// `getDetails()` from userDetails. Returns the role string or null.
  static Future<String?> fetchAndCacheRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    UD.userUID = user.uid;

    try {
      // Prefer RoleGuard which queries Firestore in a consistent order.
      final role = await RoleGuard.getUserRole();
      if (role != null && role.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', role);
        } catch (e) {
          // ignore prefs write errors
        }
        // Refresh in-memory profile details
        await UD.getDetails();
        return role;
      }

      // As a fallback, attempt direct Firestore lookups (mirrors RoleGuard)
      final uid = user.uid;
      final adminDoc =
          await FirebaseFirestore.instance.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        await _cacheRole('Admin');
        await UD.getDetails();
        return 'Admin';
      }
      final facultyDoc =
          await FirebaseFirestore.instance.collection('faculty').doc(uid).get();
      if (facultyDoc.exists) {
        final data = facultyDoc.data();
        final role = data?['userRole']?.toString();
        if (role != null && role.isNotEmpty) {
          await _cacheRole(role);
          await UD.getDetails();
          return role;
        }
        await _cacheRole('Faculty');
        await UD.getDetails();
        return 'Faculty';
      }
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .get();
      if (studentDoc.exists) {
        await _cacheRole('Student');
        await UD.getDetails();
        return 'Student';
      }
    } catch (e) {
      print('RoleService.fetchAndCacheRole error: $e');
    }

    return null;
  }

  static Future<void> _cacheRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', role);
    } catch (e) {
      // ignore
    }
    UD.userRole = role;
  }
}
