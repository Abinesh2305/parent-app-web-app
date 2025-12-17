import 'dart:io';
import 'package:dio/dio.dart';
import 'dio_client.dart';

class DocumentService {
  static Future<bool> uploadDocument({
    required int studentId,
    required int classId,
    required int sectionId,
    required String documentType,
    String? otherDocumentName,
    required File file,
    required Function(double) onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'student_id': studentId,
        'class_id': classId,
        'section_id': sectionId,
        'document_type': documentType,
        if (documentType == 'other' && otherDocumentName != null)
          'other_document_name': otherDocumentName,
        'document': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final Response res = await DioClient.dio.post(
        'documents/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (res.data == null || res.data['status'] != 1) {
        throw Exception(res.data?['message'] ?? 'Upload failed');
      }

      return true;
    } on DioException catch (e) {
      print('❌ Upload Dio Error: ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('❌ Upload Error: $e');
      return false;
    }
  }
}
