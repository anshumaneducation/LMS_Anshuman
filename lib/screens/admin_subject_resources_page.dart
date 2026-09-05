import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stela_app/constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminSubjectResourcesPage extends StatefulWidget {
  final String subjectId;
  final Map<String, dynamic> subjectData;

  const AdminSubjectResourcesPage({
    super.key,
    required this.subjectId,
    required this.subjectData,
  });

  @override
  State<AdminSubjectResourcesPage> createState() =>
      _AdminSubjectResourcesPageState();
}

class _AdminSubjectResourcesPageState extends State<AdminSubjectResourcesPage> {
  Future<void> _showAddResourceDialog() async {
    final parentContext = context;
    final pdfTitleController = TextEditingController();
    final pdfDescriptionController = TextEditingController();
    final linkTitleController = TextEditingController();
    final linkDescriptionController = TextEditingController();
    final linkUrlController = TextEditingController();

    PlatformFile? selectedPdf;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final inputDecoration = InputDecoration(
              labelStyle: theme.textTheme.bodyMedium,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.dividerColor.withAlpha((0.85 * 255).round()),
                  width: 1.1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: primaryButton,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              isDense: true,
            );

            return AlertDialog(
              title: const Text('Manage Resources'),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
              contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload PDF Resource',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: pdfTitleController,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Resource Title',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: pdfDescriptionController,
                        minLines: 2,
                        maxLines: 2,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                              withData: true,
                            );

                            if (result != null && result.files.isNotEmpty) {
                              setDialogState(() {
                                selectedPdf = result.files.first;
                              });
                            }
                          },
                          hoverColor:
                              primaryButton.withAlpha((0.08 * 255).round()),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: primaryButton
                                    .withAlpha((0.75 * 255).round()),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                  size: 42,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  selectedPdf == null
                                      ? 'Tap to select PDF'
                                      : selectedPdf!.name,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                          onPressed: () async {
                            if (pdfTitleController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Resource title is required'),
                                ),
                              );
                              return;
                            }

                            if (selectedPdf == null) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a PDF file'),
                                ),
                              );
                              return;
                            }

                            try {
                              final fileName = selectedPdf!.name;
                              final storagePath =
                                  'subjects/${widget.subjectId}/resources/$fileName';
                              final storageRef = FirebaseStorage.instance
                                  .ref()
                                  .child(storagePath);

                              if (selectedPdf!.bytes != null) {
                                await storageRef.putData(
                                  selectedPdf!.bytes!,
                                  SettableMetadata(
                                      contentType: 'application/pdf'),
                                );
                              } else if (selectedPdf!.path != null) {
                                await storageRef.putFile(
                                  File(selectedPdf!.path!),
                                );
                              }

                              final downloadUrl =
                                  await storageRef.getDownloadURL();

                              await FirebaseFirestore.instance
                                  .collection('subjects')
                                  .doc(widget.subjectId)
                                  .collection('resources')
                                  .add({
                                'title': pdfTitleController.text.trim(),
                                'description':
                                    pdfDescriptionController.text.trim(),
                                'fileUrl': downloadUrl,
                                'fileURL': downloadUrl,
                                'fileType': 'pdf',
                                'type': 'file',
                                'uploadedBy':
                                    widget.subjectData['facultyName'] ??
                                        widget.subjectData['faculty'] ??
                                        '',
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text('PDF uploaded successfully'),
                                  behavior: SnackBarBehavior.fixed,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text('Upload failed: $e'),
                                  behavior: SnackBarBehavior.fixed,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload PDF Resource'),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Divider(
                          color:
                              theme.dividerColor.withAlpha((0.8 * 255).round()),
                          thickness: 1),
                      const SizedBox(height: 18),
                      Text(
                        'Upload Online Resource Link',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: linkTitleController,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Title',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: linkDescriptionController,
                        minLines: 2,
                        maxLines: 2,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: linkUrlController,
                        decoration: inputDecoration.copyWith(
                          labelText: 'URL',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                          onPressed: () async {
                            final title = linkTitleController.text.trim();
                            final url = linkUrlController.text.trim();

                            if (title.isEmpty) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Title is required'),
                                ),
                              );
                              return;
                            }

                            if (!_isValidUrl(url)) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid URL'),
                                ),
                              );
                              return;
                            }

                            try {
                              await FirebaseFirestore.instance
                                  .collection('subjects')
                                  .doc(widget.subjectId)
                                  .collection('resources')
                                  .add({
                                'title': title,
                                'description':
                                    linkDescriptionController.text.trim(),
                                'fileUrl': url,
                                'fileURL': url,
                                'fileType': 'link',
                                'type': 'link',
                                'uploadedBy':
                                    widget.subjectData['facultyName'] ??
                                        widget.subjectData['faculty'] ??
                                        '',
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              linkTitleController.clear();
                              linkDescriptionController.clear();
                              linkUrlController.clear();

                              if (!mounted) return;
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Link resource uploaded successfully'),
                                  behavior: SnackBarBehavior.fixed,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text('Upload failed: $e'),
                                  behavior: SnackBarBehavior.fixed,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.link),
                          label: const Text('Upload Link Resource'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddAssignmentDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDueDate;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Assignment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Assignment Title',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDueDate == null
                                ? 'No due date set'
                                : DateFormat('MMM dd, yyyy hh:mm a')
                                    .format(selectedDueDate!),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 3650)),
                            );
                            if (date == null) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            final picked = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time?.hour ?? 0,
                              time?.minute ?? 0,
                            );
                            setDialogState(() {
                              selectedDueDate = picked;
                            });
                          },
                          icon: const Icon(Icons.event),
                          label: const Text('Set due date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('subjects')
                        .doc(widget.subjectId)
                        .collection('assessments')
                        .add({
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'dueDate': selectedDueDate != null
                          ? Timestamp.fromDate(selectedDueDate!)
                          : null,
                      'attachmentUrl': null,
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                      'facultyUID': widget.subjectData['facultyUID'] ?? '',
                      'status': 'active',
                      'subjectCategory':
                          widget.subjectData['subjectCategory'] ??
                              widget.subjectData['category'] ??
                              'core',
                      'subjectColor': widget.subjectData['subjectColor'] ??
                          widget.subjectData['color'] ??
                          0,
                      'subjectLabel': widget.subjectData['subjectLabel'] ??
                          widget.subjectData['label'] ??
                          widget.subjectData['name'] ??
                          '',
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'));
  }

  Future<void> _openResource(String? fileUrl, String? fileType) async {
    if (fileUrl == null || fileUrl.isEmpty) return;
    final uri = Uri.parse(fileUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(fileType == 'pdf'
                ? 'Could not open the PDF'
                : 'Could not open the link')),
      );
    }
  }

  Future<void> _showAssignmentDetailsDialog(Map<String, dynamic> data) async {
    final attachmentUrl = (data['attachmentUrl'] ?? '').toString();
    String? formattedDueDate;

    final dueDate = data['dueDate'];
    if (dueDate is Timestamp) {
      formattedDueDate =
          DateFormat('MMM dd, yyyy hh:mm a').format(dueDate.toDate());
    } else if (dueDate is String && dueDate.isNotEmpty) {
      formattedDueDate = dueDate;
    }

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(data['title'] ?? 'Assignment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((data['description'] ?? '').toString().isNotEmpty) ...[
                Text(data['description'] ?? ''),
                const SizedBox(height: 12),
              ],
              if (formattedDueDate != null && formattedDueDate.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.event, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Due: $formattedDueDate')),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (attachmentUrl.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _openResource(attachmentUrl, 'attachment'),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Open Attachment'),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
          ],
        );
      },
    );
  }

  Future<void> _deleteResource(
    String id,
    String? fileUrl,
  ) async {
    Exception? deleteError;
    // Only attempt Storage deletion for Firebase Storage URLs (or gs://)
    final isStorageUrl = fileUrl != null &&
        fileUrl.isNotEmpty &&
        (fileUrl.contains('firebasestorage.googleapis.com') ||
            fileUrl.startsWith('gs://') ||
            fileUrl.contains('storage.googleapis.com'));

    if (isStorageUrl) {
      try {
        await FirebaseStorage.instance.refFromURL(fileUrl).delete();
      } catch (e) {
        // Log but don't prevent Firestore deletion
        deleteError = Exception('Storage delete failed: $e');
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('resources')
          .doc(id)
          .delete();

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(deleteError == null
              ? 'Resource deleted successfully'
              : 'Resource deleted (storage error)'),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectName = widget.subjectData['label'];

    return Scaffold(
      backgroundColor: primaryWhite,
      appBar: AppBar(
        backgroundColor: primaryBar,
        title: Text(
          '$subjectName Resources',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'resource',
            backgroundColor: const Color.fromARGB(255, 35, 68, 92),
            foregroundColor: Colors.white,
            onPressed: _showAddResourceDialog,
            icon: const Icon(Icons.upload_file),
            label: const Text('Add Resource'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'assignment',
            backgroundColor: primaryButton,
            foregroundColor: Colors.white,
            onPressed: _showAddAssignmentDialog,
            icon: const Icon(Icons.assignment),
            label: const Text('Add Assignment'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: primaryBar,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.menu_book,
                      color: primaryBar,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subjectData['faculty'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('subjects')
                    .doc(widget.subjectId)
                    .collection('resources')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No resources added'),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final fileType =
                          (data['fileType'] ?? '').toString().toLowerCase();
                      final isPdf = fileType == 'pdf';
                      final fileUrl =
                          (data['fileUrl'] ?? data['fileURL'] ?? '').toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => _openResource(fileUrl, fileType),
                          leading: Icon(
                            isPdf ? Icons.picture_as_pdf : Icons.link,
                            color: isPdf ? Colors.red : Colors.blue,
                          ),
                          title: Text(data['title'] ?? ''),
                          subtitle: Text(
                            isPdf ? 'PDF resource' : 'External resource link',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                onPressed: () =>
                                    _openResource(fileUrl, fileType),
                                icon: Icon(
                                    isPdf ? Icons.download : Icons.open_in_new),
                                label: Text(isPdf ? 'Download' : 'Open Link'),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteResource(
                                  doc.id,
                                  fileUrl,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Assignments',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('subjects')
                    .doc(widget.subjectId)
                    .collection('assessments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No assignments added'));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => _showAssignmentDetailsDialog(data),
                          leading:
                              const Icon(Icons.assignment, color: Colors.blue),
                          title: Text(data['title'] ?? ''),
                          subtitle: Text(data['description'] ?? ''),
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
