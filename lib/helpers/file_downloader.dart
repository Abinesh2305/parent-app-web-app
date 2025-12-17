import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';

class FileDownloader {
  static Future<void> download(BuildContext context, String url) async {
    try {
      Directory? dir;

      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      // ✅ NULL CHECK (IMPORTANT)
      if (dir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage not available")),
        );
        return;
      }

      final fileName = url.split('/').last;
      final filePath = "${dir.path}/$fileName";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloading $fileName...")),
      );

      await Dio().download(url, filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved in: ${dir.path}")),
      );

      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }
}
