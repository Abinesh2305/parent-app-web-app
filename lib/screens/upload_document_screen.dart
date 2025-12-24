import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/document_service.dart';
import 'download_document_screen.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  // 🔥 FILE DATA
  Uint8List? _fileBytes; // WEB
  File? _file;           // MOBILE
  String? _fileName;

  String? _documentType;
  String? _otherDocumentName;

  bool _uploading = false;
  double _progress = 0;

  final List<Map<String, String>> _docTypes = const [
    {'label': 'Aadhaar Certificate', 'value': 'aadhar_certificate'},
    {'label': 'Community Certificate', 'value': 'community_certificate'},
    {'label': 'Birth Certificate', 'value': 'birth_certificate'},
    {'label': 'Income Certificate', 'value': 'income_certificate'},
    {'label': 'Other', 'value': 'other'},
  ];

  /* ================= PICK FILE (WEB + MOBILE) ================= */

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: kIsWeb, // 🔥 REQUIRED FOR WEB
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null) return;

    final file = result.files.single;

    setState(() {
      _fileName = file.name;

      if (kIsWeb) {
        _fileBytes = file.bytes;
        _file = null;
      } else {
        _file = File(file.path!);
        _fileBytes = null;
      }
    });
  }

  /* ================= UPLOAD ================= */

  Future<void> _upload() async {
    if (_documentType == null ||
        (_file == null && _fileBytes == null)) {
      _snack('Select document type and file');
      return;
    }

    final user = Hive.box('settings').get('user');
    if (user == null) {
      _snack('Please login again');
      return;
    }

    final int studentId = user['userdetails']['id'];
    final int classId = user['userdetails']['class_id'];
    final int sectionId = user['userdetails']['section_id'];

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    final res = await DocumentService.uploadDocument(
      studentId: studentId,
      classId: classId,
      sectionId: sectionId,
      documentType: _documentType!,
      otherDocumentName:
          _documentType == 'other' ? _otherDocumentName : null,
      file: _file,              // MOBILE
      fileBytes: _fileBytes,    // WEB
      fileName: _fileName,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (!mounted) return;

    setState(() => _uploading = false);

    if (res['success'] == true) {
      _snack(res['message'] ?? 'Upload successful');
      setState(() {
        _file = null;
        _fileBytes = null;
        _fileName = null;
        _documentType = null;
        _otherDocumentName = null;
      });
    } else {
      _snack(res['message'] ?? 'Upload failed');
    }
  }

  /* ================= UI ================= */

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _documentType,
              items: _docTypes
                  .map((e) => DropdownMenuItem(
                        value: e['value'],
                        child: Text(e['label']!),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _documentType = v),
              decoration: const InputDecoration(
                labelText: 'Document Type',
                border: OutlineInputBorder(),
              ),
            ),

            if (_documentType == 'other') ...[
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => _otherDocumentName = v,
                decoration: const InputDecoration(
                  labelText: 'Other document name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Choose File'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text('View Documents'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DownloadDocumentScreen(),
                    ),
                  );
                },
              ),
            ),

            if (_fileName != null) ...[
              const SizedBox(height: 12),
              Text('Selected: $_fileName'),
              const SizedBox(height: 8),
              if (_fileName!.toLowerCase().endsWith('.pdf'))
                const Icon(Icons.picture_as_pdf, size: 80)
              else if (kIsWeb && _fileBytes != null)
                Image.memory(_fileBytes!, height: 160, fit: BoxFit.cover)
              else if (_file != null)
                Image.file(_file!, height: 160, fit: BoxFit.cover),
            ],

            const SizedBox(height: 20),

            if (_uploading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 6),
              Text('${(_progress * 100).toStringAsFixed(0)}%'),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _uploading ? null : _upload,
                child: const Text('UPLOAD'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
