import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stela_app/constants/colors.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
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

  Future<void> _submitFeedback() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final doc = {
        'title': _titleController.text.trim(),
        'message': _bodyController.text.trim(),
        'studentId': user?.uid,
        'studentName': user?.displayName ?? user?.email ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('student_feedback').add(doc);
      _titleController.clear();
      _bodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback submitted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting feedback: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _updateFeedback(String docId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final upd = {
        'title': _titleController.text.trim(),
        'message': _bodyController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('student_feedback').doc(docId).update(upd);
      Navigator.of(context).pop();
      _titleController.clear();
      _bodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback updated')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating feedback: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete feedback?'),
        content: Text('This will permanently delete your feedback.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await FirebaseFirestore.instance.collection('student_feedback').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting feedback: $e')));
    }
  }

  void _showEditDialog(String docId, Map<String, dynamic> data) {
    _titleController.text = (data['title'] ?? '').toString();
    _bodyController.text = (data['message'] ?? '').toString();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Feedback'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Subject (optional)', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _bodyController,
                  decoration: InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
                  maxLines: 6,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your message' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
            ElevatedButton(
              onPressed: _saving ? null : () => _updateFeedback(docId),
              child: _saving ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback & Queries'),
        backgroundColor: primaryBar,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryBar.withOpacity(0.08),
              primaryWhite,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(),
              SizedBox(height: 16),
              _buildFormCard(),
              SizedBox(height: 20),
              _buildSectionHeader('Your previous submissions', 'Track and manage your feedback'),
              SizedBox(height: 8),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) {
                      return Center(child: Text('You must be signed in to view your submissions'));
                    }

                    return StreamBuilder<QuerySnapshot>(
                      // Use equality filter only to avoid composite-index requirement, then sort client-side.
                      stream: FirebaseFirestore.instance
                          .collection('student_feedback')
                          .where('studentId', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          // Show detailed error to help diagnose (e.g., missing index)
                          final err = snapshot.error?.toString() ?? 'Unknown error';
                          return Center(child: Text('Error loading feedback: $err'));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) return _buildEmptyState();

                        // Convert to mutable list and sort by timestamp (desc)
                        final sorted = List.of(docs);
                        sorted.sort((a, b) {
                          dynamic ta = (a.data() as Map<String, dynamic>?)?['timestamp'];
                          dynamic tb = (b.data() as Map<String, dynamic>?)?['timestamp'];

                          int vala = 0;
                          int valb = 0;
                          if (ta is Timestamp) vala = ta.millisecondsSinceEpoch;
                          else if (ta is DateTime) vala = ta.millisecondsSinceEpoch;
                          else if (ta is int) vala = ta;
                          else if (ta is String) vala = int.tryParse(ta) ?? 0;

                          if (tb is Timestamp) valb = tb.millisecondsSinceEpoch;
                          else if (tb is DateTime) valb = tb.millisecondsSinceEpoch;
                          else if (tb is int) valb = tb;
                          else if (tb is String) valb = int.tryParse(tb) ?? 0;

                          return valb.compareTo(vala);
                        });

                        return ListView.separated(
                          itemCount: sorted.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final d = sorted[index];
                            final data = d.data() as Map<String, dynamic>? ?? {};
                            final title = data['title'] ?? '';
                            final message = data['message'] ?? '';
                            final date = _parseDate(data['timestamp']);

                            final currentUid = FirebaseAuth.instance.currentUser?.uid;
                            final isOwner = (data['studentId'] ?? '') == (currentUid ?? '');

                            return _buildSubmissionCard(
                              docId: d.id,
                              title: title,
                              message: message,
                              date: date,
                              isOwner: isOwner,
                              data: data,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBar.withOpacity(0.95),
            primaryButton.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(color: primaryBar.withOpacity(0.25), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.rate_review, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share your feedback',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'PTSerif-Bold',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Help faculty improve by sharing ideas or questions',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryButton.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: primaryBar.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send feedback or post queries for faculty',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryBar),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Subject (optional)', border: OutlineInputBorder()),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _bodyController,
              decoration: InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
              maxLines: 6,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your message' : null,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryButton),
                    child: _saving
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryButton.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: primaryBar.withOpacity(0.04), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryButton.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.history, color: primaryButton, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontFamily: 'PTSerif-Bold', color: primaryBar)),
                SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: primaryBar.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard({
    required String docId,
    required String title,
    required String message,
    required DateTime? date,
    required bool isOwner,
    required Map<String, dynamic> data,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryButton.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: primaryBar.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryButton.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.chat_bubble_outline, color: primaryButton, size: 20),
        ),
        title: Text(title.isNotEmpty ? title : 'Feedback', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBar)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),
            Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: primaryBar.withOpacity(0.7))),
            if (date != null) ...[
              SizedBox(height: 8),
              Text(_formatDate(date), style: TextStyle(fontSize: 12, color: primaryBar.withOpacity(0.55))),
            ],
          ],
        ),
        trailing: isOwner
            ? PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'edit') {
                    _showEditDialog(docId, data);
                  } else if (val == 'delete') {
                    await _confirmDelete(docId);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              )
            : null,
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title.isNotEmpty ? title : 'Feedback'),
            content: Text(message),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Close'))],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryButton.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: primaryBar.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryButton.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inbox, color: primaryButton),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No submissions yet', style: TextStyle(fontFamily: 'PTSerif-Bold', color: primaryBar)),
                SizedBox(height: 4),
                Text('Share your thoughts to help improve the course.', style: TextStyle(fontSize: 12, color: primaryBar.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(dynamic ts) {
    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
