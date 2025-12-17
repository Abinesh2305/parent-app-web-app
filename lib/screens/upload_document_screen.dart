import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/document_service.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  File? _file;
  String? _documentType;
  String? _otherDocumentName;

  bool _uploading = false;
  double _progress = 0;

  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _docTypes = const [
    {'label': 'Aadhaar Certificate', 'value': 'aadhar_certificate'},
    {'label': 'Community Certificate', 'value': 'community_certificate'},
    {'label': 'Birth Certificate', 'value': 'birth_certificate'},
    {'label': 'Income Certificate', 'value': 'income_certificate'},
    {'label': 'Other', 'value': 'other'},
  ];

  /* ================= IMAGE CROP ================= */

  Future<File?> _cropImage(File file) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document',
          toolbarColor: Colors.teal,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Document'),
      ],
    );

    if (cropped == null) return null;
    return File(cropped.path);
  }

  /* ================= IMAGE COMPRESSION ================= */

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    int quality = 70;
    File compressed = file;

    for (int i = 0; i < 6; i++) {
      final targetPath =
          '${dir.path}/doc_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        compressed.path,
        targetPath,
        quality: quality,
        minWidth: 1280,
        minHeight: 1280,
        format: CompressFormat.jpeg,
      );

      if (result == null) break;

      compressed = File(result.path);

      if (compressed.lengthSync() / 1024 <= 500) break;

      quality -= 10;
      if (quality < 30) break;
    }

    return compressed;
  }

  /* ================= FILE PICK ================= */

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.single.path == null) return;

    File file = File(result.files.single.path!);

    if (_isImage(file)) {
      final cropped = await _cropImage(file);
      if (cropped == null) return;

      file = await _compressImage(cropped);
    }

    setState(() => _file = file);
  }

  /* ================= CAMERA ================= */

  Future<void> _openCamera() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (photo == null) return;

    File file = File(photo.path);

    final cropped = await _cropImage(file);
    if (cropped == null) return;

    final compressed = await _compressImage(cropped);

    setState(() => _file = compressed);
  }

  bool _isImage(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png');
  }

  /* ================= UPLOAD ================= */

  Future<void> _upload() async {
    if (_file == null || _documentType == null) {
      _snack('Please select document type and file');
      return;
    }

    final user = Hive.box('settings').get('user');
    if (user == null) {
      _snack('User data missing. Please login again.');
      return; 
    }

    final int? studentId = user['userdetails']?['id'];
    final int? classId = user['userdetails']?['class_id'];
    final int? sectionId = user['userdetails']?['section_id'];

    if (studentId == null || studentId <= 0) {
      _snack('Student ID missing. Please re-login.');
      return;
    }

    if (classId == null || sectionId == null) {
      _snack('Class / Section missing');
      return;
    }

    if (_file!.lengthSync() / 1024 > 500) {
      _snack('File size must be below 500 KB');
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    final success = await DocumentService.uploadDocument(
      studentId: studentId,
      classId: classId,
      sectionId: sectionId,
      documentType: _documentType!,
      otherDocumentName: _otherDocumentName,
      file: _file!,
      onProgress: (v) {
        if (!mounted) return;
        setState(() => _progress = v);
      },
    );

    if (!mounted) return;

    setState(() => _uploading = false);

    if (success) {
      _snack('Document uploaded successfully');
      setState(() {
        _file = null;
        _documentType = null;
        _otherDocumentName = null;
      });
    } else {
      _snack('Upload failed');
    }
  }

  /* ================= UI ================= */

  void _snack(String msg) {
    if (!mounted) return;
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
                    onPressed: _openCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('File'),
                  ),
                ),
              ],
            ),

            if (_file != null) ...[
              const SizedBox(height: 12),
              Text('Selected: ${p.basename(_file!.path)}'),
              const SizedBox(height: 8),

              _isImage(_file!)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _file!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf, size: 80),
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
