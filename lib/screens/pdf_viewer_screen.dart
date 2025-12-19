import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerScreen extends StatefulWidget {
  final File file;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.file,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _loading = true;
  int _pages = 0;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_pages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentPage + 1} / $_pages',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.file.path,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,

            onRender: (pages) {
              setState(() {
                _pages = pages ?? 0;
                _loading = false;
              });
            },

            onViewCreated: (controller) {
              // optional
            },

            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page ?? 0;
              });
            },

            onError: (error) {
              debugPrint('PDF Error: $error');
              _showError(context);
            },

            onPageError: (page, error) {
              debugPrint('Page Error [$page]: $error');
              _showError(context);
            },
          ),

          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _showError(BuildContext context) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open PDF')),
    );
  }
}
