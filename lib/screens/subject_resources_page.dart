import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectResourcesPage extends StatelessWidget {
  final String subjectId;
  final String subjectName;

  const SubjectResourcesPage({
    Key? key,
    required this.subjectId,
    required this.subjectName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subjectName),
            const Text(
              "Resources & Assessments",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// RESOURCES SECTION
                const SectionHeader(title: "Resources"),

                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('subjects')
                      .doc(subjectId)
                      .collection('resources')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const EmptyStateWidget(
                        message: "No resources uploaded",
                      );
                    }

                    final resources = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: resources.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final doc = resources[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final fileUrlVal =
                            (data['fileURL'] ?? data['fileUrl'] ?? '')
                                .toString();
                        final fileTypeVal = (data['fileType'] ?? '').toString();
                        final inferredType = fileTypeVal.toLowerCase() == 'link'
                            ? 'link'
                            : (data['type'] ?? 'file').toString();
                        final externalUrlVal = inferredType == 'link'
                            ? fileUrlVal
                            : (data['externalUrl'] ?? '').toString();

                        return ResourceTile(
                          title: data['title'] ?? '',
                          description: data['description'] ?? '',
                          fileUrl: fileUrlVal,
                          externalUrl: externalUrlVal,
                          fileType: fileTypeVal,
                          type: inferredType,
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 30),

                /// ASSESSMENTS SECTION
                const SectionHeader(title: "Assessments"),

                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('subjects')
                      .doc(subjectId)
                      .collection('assessments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const EmptyStateWidget(
                        message: "No assessments available",
                      );
                    }

                    final assessments = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: assessments.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final data = assessments[index];

                        return AssessmentTile(
                          title: data['title'] ?? '',
                          description: data['description'] ?? '',
                          dueDate: data['dueDate'] is Timestamp
                              ? (data['dueDate'] as Timestamp)
                                  .toDate()
                                  .toString()
                              : (data['dueDate']?.toString() ?? ''),
                          attachmentUrl: data['attachmentUrl'] ?? '',
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// SECTION HEADER

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// EMPTY STATE WIDGET
class EmptyStateWidget extends StatelessWidget {
  final String message;

  const EmptyStateWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

/// RESOURCE TILE

class ResourceTile extends StatelessWidget {
  final String title;
  final String description;
  final String fileUrl;
  final String externalUrl;
  final String fileType;
  final String type;

  const ResourceTile({
    Key? key,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.externalUrl,
    required this.fileType,
    required this.type,
  }) : super(key: key);

  Future<void> openResource() async {
    final targetUrl = type == 'link' ? externalUrl : fileUrl;

    if (targetUrl.isEmpty) return;

    final uri = Uri.parse(targetUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  IconData getFileIcon() {
    if (type == 'link') {
      if (externalUrl.contains('youtube')) {
        return Icons.play_circle_fill;
      }

      if (externalUrl.contains('drive.google')) {
        return Icons.cloud;
      }

      return Icons.link;
    }

    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;

      case 'ppt':
      case 'pptx':
        return Icons.slideshow;

      case 'doc':
      case 'docx':
        return Icons.description;

      default:
        return Icons.insert_drive_file;
    }
  }

  String getButtonText() {
    return type == 'link' ? 'Open Link' : 'Download';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                getFileIcon(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (type == 'link')
                    Text(
                      externalUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: openResource,
                    icon: Icon(
                      type == 'link' ? Icons.open_in_new : Icons.download,
                    ),
                    label: Text(getButtonText()),
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

/// ASSESSMENT TILE

class AssessmentTile extends StatelessWidget {
  final String title;
  final String description;
  final String dueDate;
  final String attachmentUrl;

  const AssessmentTile({
    Key? key,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.attachmentUrl,
  }) : super(key: key);

  Future<void> openAttachment() async {
    if (attachmentUrl.isEmpty) return;

    final uri = Uri.parse(attachmentUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

// --- NEW: METHOD TO SHOW THE DETAIL DIALOG ---
  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Due Date Label
                Text(
                  "Due Date:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                Text(dueDate, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),

                /// Description Label
                Text(
                  "Description:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            /// Optional Attachment button inside dialog
            if (attachmentUrl.isNotEmpty)
              TextButton.icon(
                onPressed: openAttachment,
                icon: const Icon(Icons.attach_file),
                label: const Text("Open Attachment"),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with InkWell for a nice ripple effect on tap
    return InkWell(
      onTap: () => _showDetailsDialog(context),
      borderRadius: BorderRadius.circular(14),
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TITLE
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              /// DESCRIPTION
              Text(
                description,
                maxLines:
                    2, // Optional: Truncate on tile, show full text in dialog
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 12),

              /// DUE DATE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Due: $dueDate",
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (attachmentUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  // Flutter handles nested buttons perfectly—this won't trigger the parent dialog tap!
                  onPressed: openAttachment,
                  icon: const Icon(Icons.attach_file),
                  label: const Text("Open Attachment"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
