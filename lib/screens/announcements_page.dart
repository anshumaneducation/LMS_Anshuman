import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stela_app/constants/colors.dart';

class AnnouncementsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Announcements', style: TextStyle(fontFamily: 'PTSerif-Bold')),
        backgroundColor: primaryBar,
        elevation: 0,
      ),
      backgroundColor: primaryWhite,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading announcements'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final latestDate = docs.isNotEmpty ? _parseDate((docs.first.data() as Map<String, dynamic>?)?['timestamp']) : null;

          return Container(
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
            child: ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: docs.isEmpty ? 1 : docs.length + 1,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeader(size, docs.length, latestDate);
                }

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                final d = docs[index - 1];
                final data = d.data() as Map<String, dynamic>? ?? {};
                final title = data['title'] ?? 'Announcement';
                final body = data['body'] ?? '';
                final date = _parseDate(data['timestamp']);
                final tag = (data['tag'] ?? data['category'] ?? 'Update').toString();

                return _buildAnnouncementCard(title, body, date, tag);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Size size, int count, DateTime? latestDate) {
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
            child: Icon(Icons.campaign, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest Updates',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'PTSerif-Bold',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  count == 0 ? 'No announcements yet' : '$count announcements',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
                SizedBox(height: 4),
                if (latestDate != null)
                  Text(
                    'Last updated ${_formatDate(latestDate)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(String title, String body, DateTime? date, String tag) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryButton.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: primaryBar.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryButton.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.notifications_active, color: primaryButton, size: 18),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBar,
                      fontFamily: 'PTSerif-Bold',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            if (body.isNotEmpty)
              Text(body, style: TextStyle(color: primaryBar.withOpacity(0.8))),
            SizedBox(height: 12),
            Row(
              children: [
                _buildBadge(tag, primaryButton.withOpacity(0.12), primaryButton),
                Spacer(),
                if (date != null)
                  Text(
                    _formatDate(date),
                    style: TextStyle(color: primaryBar.withOpacity(0.6), fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color fgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: fgColor, fontWeight: FontWeight.w600),
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
                Text('No announcements yet', style: TextStyle(fontFamily: 'PTSerif-Bold', color: primaryBar)),
                SizedBox(height: 4),
                Text('Check back later for updates from faculty.', style: TextStyle(fontSize: 12, color: primaryBar.withOpacity(0.6))),
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
