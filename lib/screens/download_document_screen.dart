import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../services/dio_client.dart';
import '../l10n/app_localizations.dart';

class DownloadDocumentScreen extends StatefulWidget {
  const DownloadDocumentScreen({super.key});

  @override
  State<DownloadDocumentScreen> createState() => _DownloadDocumentScreenState();
}

class _DownloadDocumentScreenState extends State<DownloadDocumentScreen> {
  bool _loading = true;
  List<dynamic> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  /* ================= LOAD DOCUMENTS ================= */

  Future<void> _loadDocuments() async {
    try {
      final user = Hive.box('settings').get('user');
      if (user == null) return;

      final res = await DioClient.dio.get(
        'documents/upload',
        queryParameters: {
          'student_id': user['id'],
        },
      );

      setState(() {
        _documents = res.data['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      _loading = false;
      _showSnack("Failed to load documents");
    }
  }

  /* ================= DOWNLOAD FILE ================= */

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/$fileName";

      await Dio().download(url, filePath);

      await OpenFilex.open(filePath);
    } catch (e) {
      _showSnack("Download failed");
    }
  }

  /* ================= IMAGE PREVIEW ================= */

  void _previewImage(String imageUrl) {
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
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white),
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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _isImage(String file) {
    final f = file.toLowerCase();
    return f.endsWith('.jpg') ||
        f.endsWith('.jpeg') ||
        f.endsWith('.png');
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.documents)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? Center(child: Text("No documents found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    final fileUrl = doc['file_url'];
                    final name = doc['document_name'] ?? 'Document';
                    final fileName = fileUrl.split('/').last;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: _isImage(fileName)
                            ? const Icon(Icons.image, color: Colors.green)
                            : const Icon(Icons.picture_as_pdf,
                                color: Colors.red),
                        title: Text(name),
                        subtitle: Text(fileName,
                            overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            if (_isImage(fileName)) {
                              _previewImage(fileUrl);
                            } else {
                              _downloadFile(fileUrl, fileName);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
