import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

import '../services/document_service.dart';
import 'pdf_viewer_screen.dart';

class DownloadDocumentScreen extends StatefulWidget {
  const DownloadDocumentScreen({super.key});

  @override
  State<DownloadDocumentScreen> createState() =>
      _DownloadDocumentScreenState();
}

class _DownloadDocumentScreenState
    extends State<DownloadDocumentScreen> {
  bool loading = true;

  Map<String, dynamic> documentsStatus = {};
  List<Map<String, dynamic>> otherDocuments = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  /* ================= LOAD DOCUMENT STATUS ================= */

  Future<void> _loadDocuments() async {
    setState(() => loading = true);

    final rawUser = Hive.box('settings').get('user');
    final user =
        rawUser is Map ? Map<String, dynamic>.from(rawUser) : null;

    if (user == null || user['id'] == null) {
      setState(() => loading = false);
      return;
    }

    final res =
        await DocumentService.getMyDocumentStatus(userId: user['id']);

    if (!mounted) return;

    if (res['success'] == true) {
      final data = res['data'] ?? {};

      setState(() {
        documentsStatus = data['documents_status'] is Map
            ? Map<String, dynamic>.from(data['documents_status'])
            : {};

        otherDocuments = (data['other_documents'] is List)
            ? (data['other_documents'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
      });
    }

    setState(() => loading = false);
  }

  /* ================= HELPERS ================= */

  Map<String, dynamic>? _doc(String key) => documentsStatus[key];

  bool _uploaded(String key) => _doc(key)?['uploaded'] == true;

  String? _viewUrl(String key) {
    final doc = _doc(key);
    if (doc == null) return null;
    return doc['view_url'] ?? doc['download_url'];
  }

  bool _isImage(String key) => _doc(key)?['file_type'] == 'image';

  /* ================= IMAGE PREVIEW ================= */

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
                        color: Colors.white);
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
                icon: const Icon(Icons.close,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= PDF OPEN ================= */

  Future<void> _openPdf(String url, String title) async {
    // 🌐 WEB → open in new tab
    if (kIsWeb) {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri,
          mode: LaunchMode.externalApplication)) {
        _snack('Unable to open PDF');
      }
      return;
    }

    // 📱 MOBILE → download & open inside app
    try {
      final response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.length < 4) {
        throw Exception('Invalid PDF');
      }

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/doc_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            file: file, // ✅ FIXED
            title: title,
          ),
        ),
      );
    } catch (_) {
      _snack('Unable to open PDF');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /* ================= ROWS ================= */

  Widget _docRow(String title, String key) {
    final uploaded = _uploaded(key);
    final url = _viewUrl(key);
    final isImage = _isImage(key);

    return _row(
      title: title,
      uploaded: uploaded,
      onView: uploaded && url != null
          ? () => isImage
              ? _previewImage(url)
              : _openPdf(url, title)
          : null,
    );
  }

  Widget _otherDocRow(Map<String, dynamic> doc) {
    final title = doc['name'] ?? 'Other Document';
    final url = doc['view_url'] ?? doc['download_url'];
    final type = doc['file_type'] ?? 'pdf';

    return _row(
      title: title,
      uploaded: url != null,
      onView: url == null
          ? null
          : () => type == 'image'
              ? _previewImage(url)
              : _openPdf(url, title),
    );
  }

  Widget _row({
    required String title,
    required bool uploaded,
    VoidCallback? onView,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(title)),
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
                Text(
                  uploaded ? 'Uploaded' : 'Not Uploaded',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: onView != null
                  ? TextButton(
                      onPressed: onView,
                      child: const Text('View'),
                    )
                  : const Text(
                      'No File',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey),
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    ...otherDocuments.map(_otherDocRow),
                  ],
                ],
              ),
            ),
    );
  }
}
