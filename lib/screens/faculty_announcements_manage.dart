import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stela_app/constants/colors.dart';

class FacultyAnnouncementsManage extends StatefulWidget {
  final Map<String, dynamic>? subject;
  const FacultyAnnouncementsManage({this.subject});

  @override
  State<FacultyAnnouncementsManage> createState() => _FacultyAnnouncementsManageState();
}

class _FacultyAnnouncementsManageState extends State<FacultyAnnouncementsManage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _createAnnouncement() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final doc = {
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'createdBy': user?.uid,
        'createdByName': user?.displayName ?? user?.email ?? '',
        'subjectId': widget.subject?['id'],
        'subjectLabel': widget.subject?['label'] ?? 'General',
      };

      await FirebaseFirestore.instance.collection('announcements').add(doc);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Announcement created')));
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating announcement: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _updateAnnouncement(String docId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final upd = {
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'createdBy': user?.uid,
        'createdByName': user?.displayName ?? user?.email ?? '',
      };

      await FirebaseFirestore.instance.collection('announcements').doc(docId).update(upd);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Announcement updated')));
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating announcement: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete announcement?'),
        content: Text('This will permanently delete the announcement.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await FirebaseFirestore.instance.collection('announcements').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Announcement deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting announcement: $e')));
    }
  }

  void _showEditDialog(String docId, Map<String, dynamic> data) {
    _titleController.text = (data['title'] ?? '').toString();
    _bodyController.text = (data['body'] ?? '').toString();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Announcement'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _bodyController,
                  decoration: InputDecoration(labelText: 'Body'),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
            ElevatedButton(
              onPressed: _saving ? null : () => _updateAnnouncement(docId),
              child: _saving ? SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create Announcement'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _bodyController,
                  decoration: InputDecoration(labelText: 'Body'),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
            ElevatedButton(
              onPressed: _saving ? null : _createAnnouncement,
              child: _saving ? SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : Text('Post'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject ?? {'id': null, 'label': 'General', 'color': primaryBar};
    // Build a query: if subject id available, filter by subject
    Query announcementsQuery = FirebaseFirestore.instance.collection('announcements');
    if (subject['id'] != null) {
      announcementsQuery = announcementsQuery.where('subjectId', isEqualTo: subject['id']);
    }
    announcementsQuery = announcementsQuery.orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Announcements - ${subject['label']}'),
        backgroundColor: subject['color'] ?? primaryBar,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Create New Announcement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: subject['color'] ?? primaryButton,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _showCreateDialog,
            ),
            SizedBox(height: 24),
            Text(
              'Previous Announcements',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: announcementsQuery.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error loading announcements'));
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return Center(child: Text('No announcements yet.'));

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final d = docs[index];
                      final data = d.data() as Map<String, dynamic>? ?? {};
                      final title = data['title'] ?? '';
                      final body = data['body'] ?? '';
                      final ts = data['timestamp'];
                      DateTime? date;
                      if (ts is Timestamp) date = ts.toDate();
                      if (ts is DateTime) date = ts;

                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.announcement, color: subject['color'] ?? primaryButton),
                          title: Text(title),
                          subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (date != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text('${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}'),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (val) async {
                                  if (val == 'edit') {
                                    _showEditDialog(d.id, data);
                                  } else if (val == 'delete') {
                                    await _confirmDelete(d.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            // Optionally show full details
                            showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(title),
                                content: Text(body),
                                actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Close'))],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}