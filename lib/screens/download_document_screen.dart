import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/document_service.dart';
import 'pdf_viewer_screen.dart';

class DownloadDocumentScreen extends StatefulWidget {
  const DownloadDocumentScreen({super.key});

  @override
  State<DownloadDocumentScreen> createState() => _DownloadDocumentScreenState();
}

class _DownloadDocumentScreenState extends State<DownloadDocumentScreen> {
  bool loading = true;

  Map<String, dynamic>? documentsStatus;
  List<dynamic> otherDocuments = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  /* ================= LOAD DOCUMENT STATUS ================= */

  Future<void> _loadDocuments() async {
    setState(() => loading = true);

    final user = Hive.box('settings').get('user');
    if (user == null || user['id'] == null) {
      setState(() => loading = false);
      return;
    }

    final res = await DocumentService.getMyDocumentStatus(
      userId: user['id'], // same as Postman
    );

    if (res['success'] == true && mounted) {
      setState(() {
        documentsStatus =
            Map<String, dynamic>.from(res['data']['documents_status']);
        otherDocuments = List.from(res['data']['other_documents'] ?? []);
      });
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  /* ================= HELPERS ================= */

  Map<String, dynamic>? _doc(String key) => documentsStatus?[key];

  bool _uploaded(String key) => _doc(key)?['uploaded'] == true;

  String? _viewUrl(String key) => _doc(key)?['view_url'];

  bool _isImageDoc(String key) => _doc(key)?['file_type'] == 'image';

  /* ================= IMAGE VIEWER ================= */

  void _previewImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const CircularProgressIndicator(
                      color: Colors.white,
                    );
                  },
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  /* ================= PDF HANDLING ================= */

  Future<File> _downloadPdf(String url) async {
    final dir = await getTemporaryDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
    final path = '${dir.path}/$fileName';

    final res = await Dio().get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    final file = File(path);
    await file.writeAsBytes(res.data);
    return file;
  }

  Future<void> _openPdf(String url, String title) async {
    try {
      final file = await _downloadPdf(url);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            file: file,
            title: title,
          ),
        ),
      );
    } catch (_) {
      _snack('Unable to open document');
    }
  }

  /* ================= UI HELPERS ================= */

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /* ================= TABLE ROW ================= */

  Widget _docRow(String title, String key) {
    final uploaded = _uploaded(key);
    final url = _viewUrl(key);
    final isImage = _isImageDoc(key);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(title, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  uploaded ? Icons.check_circle : Icons.cancel,
                  color: uploaded ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    uploaded ? 'Uploaded' : 'Not Uploaded',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: uploaded && url != null
                  ? TextButton(
                      onPressed: () {
                        if (isImage) {
                          _previewImage(url);
                        } else {
                          _openPdf(url, title);
                        }
                      },
                      child: const Text('View'),
                    )
                  : const Text(
                      'No File',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= BUILD ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Documents')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Document Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _docRow('Aadhaar Certificate', 'aadhar'),
                  _docRow('Birth Certificate', 'birth'),
                  _docRow('Income Certificate', 'income'),
                  _docRow('Community Certificate', 'community'),
                  if (otherDocuments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Other Documents',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    for (final doc in otherDocuments)
                      ListTile(
                        title: Text(doc['document_name'] ?? 'Document'),
                        trailing: TextButton(
                          onPressed: () {
                            final url = doc['view_url'];
                            if (url == null) return;

                            if (doc['file_type'] == 'image') {
                              _previewImage(url);
                            } else {
                              _openPdf(
                                url,
                                doc['document_name'] ?? 'Document',
                              );
                            }
                          },
                          child: const Text('View'),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
