import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:stela_app/utils/role_guard.dart';
import 'package:stela_app/constants/colors.dart';
import 'package:stela_app/screens/admin_side_panel.dart';
import 'package:stela_app/screens/admin_dashboard.dart';
import 'package:stela_app/screens/admin_manage_subjects.dart';
import 'package:stela_app/screens/admin_analytics_page.dart';

class AdminManageUsersPage extends StatefulWidget {
  const AdminManageUsersPage({Key? key}) : super(key: key);

  @override
  State<AdminManageUsersPage> createState() => _AdminManageUsersPageState();
}

class _AdminManageUsersPageState extends State<AdminManageUsersPage> {
  bool _isAuthorized = false;
  bool _isLoading = true;
  // Pagination & search state for students
  static const int _pageSize = 50;
  int _currentPage = 1;
  DocumentSnapshot? _lastDocument; // last doc of current page
  bool _hasMorePages = true; // track if there are more pages
  // Stores the startAfter document for each page (index 0 = null for first page)
  final List<DocumentSnapshot?> _pageStartDocs = [null];
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();
  // Stream for the students list (pagination or search)
  Stream<QuerySnapshot>? _studentStream;

  @override
  void initState() {
    super.initState();
    _verifyAdmin();
    _resetStudentStream();
  }

  // VERIFY ADMIN
  Future<void> _verifyAdmin() async {
    final allowed = await RoleGuard.isAdmin();

    setState(() {
      _isAuthorized = allowed;
      _isLoading = false;
    });

    if (!allowed) {
      await RoleGuard.logout();
    }
  }

  // Reset pagination to first page and load students stream
  void _resetStudentStream() {
    _currentPage = 1;
    _hasMorePages = true;
    _pageStartDocs
      ..clear()
      ..add(null);
    _loadStudentPage(startAfter: null);
  }

  // Load a page of students, optionally starting after a document
  void _loadStudentPage({DocumentSnapshot? startAfter}) {
    // Order by document ID to have a stable ordering for pagination
    Query query = FirebaseFirestore.instance
        .collection('students')
        .orderBy(FieldPath.documentId)
        .limit(_pageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    setState(() {
      _studentStream = query.snapshots();
    });
  }

  // Navigate to next page
  void _nextPage() {
    if (_lastDocument == null) return;
    _pageStartDocs.add(_lastDocument);
    _currentPage++;
    _loadStudentPage(startAfter: _lastDocument);
  }

  // Navigate to previous page
  void _previousPage() {
    if (_currentPage <= 1) return;
    // Remove current page start doc
    _pageStartDocs.removeLast();
    _currentPage--;
    final startAfter = _pageStartDocs.last;
    _loadStudentPage(startAfter: startAfter);
  }

  Future<void> _logout() async {
    await RoleGuard.logout();

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _handleSidebarSelection(int index) {
    if (index == 1) {
      return;
    }

    Widget destination;
    switch (index) {
      case 0:
        destination = const AdminDashboard();
        break;
      case 2:
        destination = const AdminManageSubjectsPage();
        break;
      case 3:
        destination = const AdminAnalyticsPage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  // DELETE USER
  Future<void> _deleteUser(
    String collection,
    String uid,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete User',
          ),
          content: const Text(
            'Are you sure you want to delete this user?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection(collection).doc(uid).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: $e'),
        ),
      );
    }
  }

  // USER CARD
  Widget _buildUserCard({
    required String uid,
    required Map<String, dynamic> data,
    required String role,
    required String collection,
  }) {
    final name = data['name'] ?? 'No Name';
    final email = data['email'] ?? 'No Email';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryBar,
          child: Text(
            role[0],
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                role,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          onPressed: () {
            _deleteUser(
              collection,
              uid,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPendingFacultyCard({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    final name = data['name'] ?? 'No Name';
    final email = data['email'] ?? 'No Email';
    final createdAt = data['createdAt'] as Timestamp?;
    final createdAtLabel = createdAt != null
        ? createdAt.toDate().toLocal().toString().split('.').first
        : 'Unknown';
    final institute = data['institute'] ??
        data['instituteName'] ??
        data['college'] ??
        'Not provided';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryBar,
                child: const Icon(Icons.pending, color: Colors.white),
              ),
              title: Text(name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(email),
                  const SizedBox(height: 4),
                  Text('Institute: $institute'),
                  const SizedBox(height: 2),
                  Text('Requested: $createdAtLabel'),
                ],
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _rejectPendingFaculty(uid),
                  child:
                      const Text('Reject', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: primaryButton),
                  onPressed: () => _approvePendingFaculty(uid),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // USER STREAM (students with pagination / search)
  Widget _buildStudentStream() {
    Stream<QuerySnapshot> baseStream = _searchTerm.isNotEmpty
        ? FirebaseFirestore.instance.collection('students').snapshots()
        : _studentStream!;

    return StreamBuilder<QuerySnapshot>(
      stream: baseStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              _searchTerm.isNotEmpty ? 'No results' : 'No Students found',
            ),
          );
        }

        List<QueryDocumentSnapshot> docs = snapshot.data!.docs.cast();

        // Apply search filter if searching
        if (_searchTerm.isNotEmpty) {
          final lowerSearch = _searchTerm.toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            return name.contains(lowerSearch) || email.contains(lowerSearch);
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('No results'));
          }
        } else {
          // Update pagination helper variables when not searching
          if (docs.isNotEmpty) {
            _lastDocument = docs.last;
            // If we got fewer than _pageSize items, we're on the last page
            _hasMorePages = docs.length >= _pageSize;
          }
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildUserCard(
              uid: doc.id,
              data: data,
              role: 'Student',
              collection: 'students',
            );
          },
        );
      },
    );
  }

  Future<void> _approvePendingFaculty(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('faculty').doc(uid).update({
        'userRole': 'Faculty',
        'approved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faculty approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving faculty: $e')),
      );
    }
  }

  Future<void> _rejectPendingFaculty(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('faculty').doc(uid).update({
        'userRole': 'rejected_faculty',
        'approved': false,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faculty request rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting faculty: $e')),
      );
    }
  }

  // USER STREAM (faculty – approved only)
  Widget _buildFacultyStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('faculty')
          .where('userRole', isEqualTo: 'Faculty')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No Faculty found'),
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildUserCard(
              uid: doc.id,
              data: data,
              role: 'Faculty',
              collection: 'faculty',
            );
          },
        );
      },
    );
  }

  // USER STREAM (pending faculty requests)
  Widget _buildPendingFacultyStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('faculty')
          .where('userRole', isEqualTo: 'pending_faculty')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading pending requests: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No pending faculty requests'),
          );
        }
        final docs = snapshot.data!.docs.cast<QueryDocumentSnapshot>().toList()
          ..sort((a, b) {
            final aCreated = (a.data() as Map<String, dynamic>)['createdAt'];
            final bCreated = (b.data() as Map<String, dynamic>)['createdAt'];
            if (aCreated is Timestamp && bCreated is Timestamp) {
              return bCreated.compareTo(aCreated);
            }
            if (aCreated is Timestamp) return -1;
            if (bCreated is Timestamp) return 1;
            return 0;
          });

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildPendingFacultyCard(
              uid: doc.id,
              data: data,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // LOADING
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // UNAUTHORIZED
    if (!_isAuthorized) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Unauthorized Access',
          ),
        ),
      );
    }

    // MAIN PAGE
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Row(
          children: [
            AdminSidebar(
              selectedIndex: 1,
              onItemSelected: _handleSidebarSelection,
              onLogout: _logout,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: primaryBar,
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: const Text(
                              'Manage Users',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Search bar (only for students tab)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search students by name or email',
                                prefixIcon: Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchTerm = value.trim();
                                  if (_searchTerm.isEmpty) {
                                    _resetStudentStream();
                                  }
                                  // Search filtering is done client-side in _buildStudentStream()
                                });
                              },
                            ),
                          ),
                          const TabBar(
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white70,
                            tabs: [
                              Tab(
                                text: 'Students',
                                icon: Icon(
                                  Icons.school,
                                  color: Colors.white,
                                ),
                              ),
                              Tab(
                                text: 'Faculty',
                                icon: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              Tab(
                                text: 'Pending Requests',
                                icon: Icon(
                                  Icons.hourglass_top,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildStudentStream(),
                        _buildFacultyStream(),
                        _buildPendingFacultyStream(),
                      ],
                    ),
                  ),
                  // Pagination controls (only show when not searching) - moved to bottom
                  if (_searchTerm.isEmpty)
                    Material(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed:
                                  _currentPage > 1 ? _previousPage : null,
                            ),
                            Text('Page $_currentPage'),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: _hasMorePages && _searchTerm.isEmpty
                                  ? _nextPage
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
