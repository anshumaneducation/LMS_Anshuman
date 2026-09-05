import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stela_app/constants/colors.dart';

class FacultyLabPracticalsManage extends StatefulWidget {
  @override
  _FacultyLabPracticalsManageState createState() => _FacultyLabPracticalsManageState();
}

class _FacultyLabPracticalsManageState extends State<FacultyLabPracticalsManage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _loading = false;

  void _showCreateDialog() {
    _titleController.clear();
    _descController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Create Lab Practical'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: _createLabPractical, child: Text('Create')),
        ],
      ),
    );
  }

  Future<void> _createLabPractical() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty) return;
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    try {
      await FirebaseFirestore.instance.collection('lab_practicals').add({
        'title': title,
        'description': desc,
        'createdBy': user?.uid,
        'createdByName': user?.displayName ?? user?.email ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lab Practicals'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('lab_practicals').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return Center(child: Text('No lab practicals yet. Tap + to add.'));
          return ListView.separated(
            padding: EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (c, i) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>? ?? {};
              final title = data['title'] ?? 'Untitled';
              final desc = data['description'] ?? '';
              return ListTile(
                title: Text(title),
                subtitle: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _showEditDialog(d.id, data);
                    if (v == 'delete') _deletePractical(d.id);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                onTap: () => _openDetail(d.id, data),
              );
            },
          );
        },
      ),
    );
  }

  void _openDetail(String id, Map<String, dynamic> data) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _LabPracticalDetail(id: id, data: data)));
  }

  void _showEditDialog(String id, Map<String, dynamic> data) {
    _titleController.text = data['title'] ?? '';
    _descController.text = data['description'] ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Lab Practical'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
            SizedBox(height: 8),
            TextField(controller: _descController, decoration: InputDecoration(labelText: 'Description'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(onPressed: () => _updatePractical(id), child: Text('Save')),
        ],
      ),
    );
  }

  Future<void> _updatePractical(String id) async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('lab_practicals').doc(id).update({
        'title': title,
        'description': desc,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletePractical(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Lab Practical'),
        content: Text('Are you sure? This will remove the lab practical.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseFirestore.instance.collection('lab_practicals').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }
}

class _LabPracticalDetail extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  const _LabPracticalDetail({required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled';
    final desc = data['description'] ?? '';
    final createdByName = data['createdByName'] ?? '';
    return Scaffold(
      appBar: AppBar(title: Text('Lab Practical')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(desc),
          SizedBox(height: 16),
          if (createdByName.isNotEmpty) Text('Created by $createdByName', style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}
