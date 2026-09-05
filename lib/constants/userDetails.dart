import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

var userUID;

String name = "",
    email = "",
    enrollmentNo = "",
    contactNum = "",
    password = "",
    confirmPassword = "",
    userRole = "";

Map<String, dynamic>? data, document;
var userDetails;
String? userCollection;

// ✅ FIXED: Return type changed from void ➝ Future<void>
Future<void> getDetails() async {
  // Ensure we have a valid UID; prefer the shared `userUID` but fall back
  // to the currently authenticated user if it's not set (handles hot-reload
  // or direct navigation cases).
  var uid = userUID ?? FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    print('⚠️ getDetails(): no user UID found (user not signed in?)');
    // Clear any existing values to avoid showing stale data
    name = email = enrollmentNo = contactNum = userRole = "";
    return;
  }

  // Try to locate the user document in students -> faculty -> admins
  // (mirrors the login logic). This ensures faculty users also get the
  // correct profile fields when opening Profile from a faculty account.
  DocumentSnapshot? docSnap;
  final colOrder = ['students', 'faculty', 'admins'];
  for (final col in colOrder) {
    final snap = await FirebaseFirestore.instance.collection(col).doc(uid).get();
    if (snap.exists) {
      docSnap = snap;
      break;
    }
  }

  if (docSnap == null || !docSnap.exists) {
    print('❌ getDetails(): no user document found for UID $uid in students/faculty/admins');
    // Clear any existing values to avoid showing stale data
    name = email = enrollmentNo = contactNum = userRole = "";
    return;
  }

  userDetails = docSnap;
  data = userDetails.data() as Map<String, dynamic>?; // gets details in the form of a map

  // Remember which collection we found by checking a likely userRole field
  userRole = data?['userRole'] ?? userRole ?? "";
  // Record the collection where the document was found so updates can target it
  // We infer collection from the document's path: students, faculty, or admins
  // The earlier loop found the document in 'col' — but we don't keep 'col' here,
  // so derive from common keys or fallback to 'students'. If the document
  // contains 'enrollmentNumber' we assume it's a student, otherwise fall back.
  if (data != null && data!.containsKey('enrollmentNumber')) {
    userCollection = 'students';
  } else if (data != null && (data!.containsKey('department') || userRole.toLowerCase() == 'faculty')) {
    userCollection = 'faculty';
  } else {
    userCollection = 'students';
  }

  // Assign values from the found document with common fallback keys.
  name = data?['name'] ?? data?['fullName'] ?? "";
  email = data?['email'] ?? data?['emailAddress'] ?? FirebaseAuth.instance.currentUser?.email ?? "";
  enrollmentNo = data?['enrollmentNumber'] ?? data?['enrollmentNo'] ?? "";
  contactNum = data?['contactNumber'] ?? data?['phone'] ?? "";

  // Ensure the global userUID is set so other code can rely on it
  userUID = uid;

  // Debugging: if all fields are empty, print the raw document to help
  // diagnose why profile shows 'Not available'. Remove or lower verbosity
  // in production if desired.
  if ((name.isEmpty) && (email.isEmpty) && (enrollmentNo.isEmpty) && (contactNum.isEmpty)) {
    print('🔎 getDetails(): fetched document data is empty or missing keys:');
    print(data);
  }
}

/// Update user details in Firestore. This will attempt to update the document
/// in the earlier-detected user collection (if available) or fall back to
/// trying students/faculty/admins in that order. The updates map should
/// contain the fields to be updated.
Future<void> updateDetails(Map<String, dynamic> updates) async {
  final uid = userUID ?? FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    throw Exception('No user UID available for update');
  }

  final firestore = FirebaseFirestore.instance;

  // If we know the collection, try it first
  if (userCollection != null) {
    try {
      await firestore.collection(userCollection!).doc(uid).update(updates);
      return;
    } catch (e) {
      // Continue to fallback
      print('updateDetails: failed to update in $userCollection — $e');
    }
  }

  // Fallback search order
  final colOrder = ['students', 'faculty', 'admins'];
  for (final col in colOrder) {
    final docRef = firestore.collection(col).doc(uid);
    final snap = await docRef.get();
    if (snap.exists) {
      await docRef.update(updates);
      // remember for next time
      userCollection = col;
      return;
    }
  }

  throw Exception('updateDetails: no user document found to update');
}

// (Optional: Keep it commented if not used)
Future<void> getAssessmentLink() async {
  final assesmentLinks = await FirebaseFirestore.instance
      .collection('assessments')
      .doc('Assessments')
      .get(); // gets document

  document = assesmentLinks.data();
}
