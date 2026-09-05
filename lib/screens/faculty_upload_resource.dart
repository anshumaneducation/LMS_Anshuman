// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:io';

// class FacultyUploadResource extends StatelessWidget {
//   final Map<String, dynamic> subject;
//   const FacultyUploadResource({required this.subject});

//   Future<void> _uploadPDF(BuildContext context) async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
//     if (result != null && result.files.single.path != null) {
//       final file = File(result.files.single.path!);
//       final fileName = result.files.single.name;

//       // Upload to Firebase Storage
//       final ref = FirebaseStorage.instance.ref('resources/${subject['label']}/$fileName');
//       await ref.putFile(file);
//       final url = await ref.getDownloadURL();

//       // Save metadata to Firestore
//       await FirebaseFirestore.instance.collection('resources').add({
//         'subject': subject['label'],
//         'fileName': fileName,
//         'url': url,
//         'uploadedAt': Timestamp.now(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF uploaded successfully!')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Upload Resource - ${subject['label']}"),
//         backgroundColor: subject['color'],
//       ),
//       body: ListView(
//         padding: EdgeInsets.all(24),
//         children: [
//           ListTile(
//             leading: Icon(Icons.picture_as_pdf, color: subject['color']),
//             title: Text("Upload PDF"),
//             onTap: () => _uploadPDF(context),
//           ),
//         ],
//       ),
//     );
//   }
// }

//---------------------------MSTELA------------------------------

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FacultyUploadResource extends StatefulWidget {
  final Map<String, dynamic> subject;

  const FacultyUploadResource({
    super.key,
    required this.subject,
  });

  @override
  State<FacultyUploadResource> createState() => _FacultyUploadResourceState();
}

class _FacultyUploadResourceState extends State<FacultyUploadResource> {
  bool _isUploading = false;
  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _urlController = TextEditingController();

  Future<void> _uploadPDFs(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'PDF'],
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isUploading = true;
      });

      int uploadedCount = 0;
      int duplicateCount = 0;

      List<String> duplicateFiles = [];

      for (final pickedFile in result.files) {
        // Validate PDF
        final extension = pickedFile.extension?.toLowerCase();

        if (extension != 'pdf') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${pickedFile.name} is not a supported PDF file',
              ),
              backgroundColor: Colors.red,
            ),
          );
          continue;
        }

        final originalFileName = pickedFile.name;
        final String subjectId =
            widget.subject['id'] ?? widget.subject['value'] ?? '';

        if (subjectId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Subject ID not found'),
              backgroundColor: Colors.red,
            ),
          );
          continue;
        }

        // Storage Path
        final storagePath = 'subjects/$subjectId/resources/$originalFileName';

        final ref = FirebaseStorage.instance.ref().child(storagePath);

        // Check Duplicate
        bool fileAlreadyExists = false;

        try {
          await ref.getMetadata();
          fileAlreadyExists = true;
        } catch (e) {
          fileAlreadyExists = false;
        }

        String finalFileName = originalFileName;

        // Rename duplicate automatically
        if (fileAlreadyExists) {
          duplicateCount++;
          duplicateFiles.add(originalFileName);

          final timestamp = DateTime.now().millisecondsSinceEpoch;

          finalFileName = '${timestamp}_$originalFileName';
        }

        final finalRef = FirebaseStorage.instance.ref().child(
              'subjects/$subjectId/resources/$finalFileName',
            );

        // UNIVERSAL Upload
        if (pickedFile.bytes != null) {
          await finalRef.putData(
            pickedFile.bytes!,
          );
        } else if (pickedFile.path != null) {
          await finalRef.putFile(
            File(pickedFile.path!),
          );
        }

        final url = await finalRef.getDownloadURL();

        // Save metadata to Firestore (store both keys for backwards compatibility)
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(subjectId)
            .collection('resources')
            .add({
          'title': finalFileName,
          'description': '',
          'fileName': originalFileName,
          'fileUrl': url,
          'fileURL': url,
          'fileType': 'pdf',
          'type': 'file',
          'uploadedBy': widget.subject['facultyName'] ?? '',
          'createdAt': Timestamp.now(),
        });

        uploadedCount++;
      }

      setState(() {
        _isUploading = false;
      });

      // Success Dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Upload Complete"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$uploadedCount file(s) uploaded successfully.",
                ),
                if (duplicateCount > 0) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "Duplicate files detected:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...duplicateFiles.map(
                    (file) => Text("• $file"),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Action Taken:\nDuplicate files were renamed automatically.",
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadLinkResource(BuildContext context) async {
    try {
      final subjectId = widget.subject['id'] ?? widget.subject['value'] ?? '';

      if (subjectId.isEmpty) return;

      if (_titleController.text.trim().isEmpty ||
          _urlController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Title and Link are required'),
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectId)
          .collection('resources')
          .add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fileUrl': _urlController.text.trim(),
        'fileURL': _urlController.text.trim(),
        'fileType': 'link',
        'type': 'link',
        'uploadedBy': widget.subject['facultyName'] ?? '',
        'createdAt': Timestamp.now(),
      });

      _titleController.clear();
      _descriptionController.clear();
      _urlController.clear();

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link resource uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = widget.subject['color'] as Color;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Upload Resource - ${widget.subject['label']}",
        ),
        backgroundColor: themeColor,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    Icons.picture_as_pdf,
                    color: themeColor,
                    size: 36,
                  ),
                  title: const Text(
                    "Upload PDF Resources",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    "Upload one or multiple PDF files",
                  ),
                  trailing: const Icon(
                    Icons.upload_file,
                  ),
                  onTap: _isUploading ? null : () => _uploadPDFs(context),
                ),
              ),

              //     const SizedBox(height: 16),
              //     Card(
              //       elevation: 4,
              //       child: ListTile(
              //         contentPadding: const EdgeInsets.all(16),
              //         leading: Icon(
              //           Icons.link,
              //           color: themeColor,
              //           size: 36,
              //         ),
              //         title: const Text(
              //           "Add External Resource Link",
              //           style: TextStyle(
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //         subtitle: const Text(
              //           "Google Drive, YouTube, GitHub, Website etc.",
              //         ),
              //         trailing: const Icon(
              //           Icons.open_in_new,
              //         ),
              //         onTap:
              //
              //           _isUploading ? null : () => _showAddLinkDialog(context),

              // ),
              // ),
              const SizedBox(height: 20),

              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: themeColor,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Upload Online Resource Link",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Resource Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Google Drive / YouTube / Website URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading
                              ? null
                              : () => _uploadLinkResource(context),
                          icon: const Icon(Icons.upload),
                          label: const Text("Upload Link Resource"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Loading Overlay
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Uploading files...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
