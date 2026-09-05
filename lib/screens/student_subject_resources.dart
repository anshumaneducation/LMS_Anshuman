import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentSubjectResources extends StatelessWidget {
  final String? subjectLabel;
  final String? subjectId;

  const StudentSubjectResources({
    this.subjectLabel,
    this.subjectId,
  });

  @override
  Widget build(BuildContext context) {
    if (subjectId != null && subjectId!.isNotEmpty) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subjects')
            .doc(subjectId)
            .collection('resources')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text('No resources yet.'));
          return ListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final url =
                  (data['fileURL'] ?? data['fileUrl'] ?? data['url'] ?? '')
                      .toString();
              final name = (data['fileName'] ?? data['title'] ?? '').toString();
              final isLink =
                  (data['fileType'] ?? '').toString().toLowerCase() == 'link' ||
                      (data['type'] ?? '').toString().toLowerCase() == 'link';

              return ListTile(
                leading: Icon(isLink ? Icons.link : Icons.picture_as_pdf,
                    color: Colors.red),
                title: Text(name.isNotEmpty ? name : 'Resource'),
                onTap: () async {
                  if (url.isEmpty) return;
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
              );
            }).toList(),
          );
        },
      );
    }

    if (subjectLabel != null && subjectLabel!.isNotEmpty) {
      // First find the subject document by label, then listen to its resources
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subjects')
            .where('label', isEqualTo: subjectLabel)
            .limit(1)
            .snapshots(),
        builder: (context, subjectSnap) {
          if (!subjectSnap.hasData)
            return Center(child: CircularProgressIndicator());
          if (subjectSnap.data!.docs.isEmpty)
            return Center(child: Text('No resources yet.'));

          final subjectIdFound = subjectSnap.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('subjects')
                .doc(subjectIdFound)
                .collection('resources')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return Center(child: Text('No resources yet.'));
              return ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final url =
                      (data['fileURL'] ?? data['fileUrl'] ?? data['url'] ?? '')
                          .toString();
                  final name =
                      (data['fileName'] ?? data['title'] ?? '').toString();
                  final isLink = (data['fileType'] ?? '')
                              .toString()
                              .toLowerCase() ==
                          'link' ||
                      (data['type'] ?? '').toString().toLowerCase() == 'link';

                  return ListTile(
                    leading: Icon(isLink ? Icons.link : Icons.picture_as_pdf,
                        color: Colors.red),
                    title: Text(name.isNotEmpty ? name : 'Resource'),
                    onTap: () async {
                      if (url.isEmpty) return;
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      );
    }

    return Center(child: Text('No subject specified.'));
  }
}
