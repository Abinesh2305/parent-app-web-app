import 'dart:io';
import 'package:dio/dio.dart';
import 'dio_client.dart';

class DocumentService {
  /* =========================================================
   * UPLOAD DOCUMENT
   * ========================================================= */
  static Future<Map<String, dynamic>> uploadDocument({
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
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress(sent / total);
        },
      );

      if (res.data == null) {
        return {'success': false, 'message': 'Empty server response'};
      }

      if (res.data['status'] != 1) {
        return {
          'success': false,
          'message': res.data['message'] ?? 'Upload failed',
        };
      }

      return {
        'success': true,
        'message': res.data['message'] ?? 'Success',
        'data': res.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /* =========================================================
   * ✅ GET MY DOCUMENT STATUS (FIXED)
   * API: POST documents/my-status
   * BODY: { user_id }
   * ========================================================= */
  static Future<Map<String, dynamic>> getMyDocumentStatus({
    required int userId,
  }) async {
    try {
      final Response res = await DioClient.dio.post(
        'documents/my-status',
        data: {
          'user_id': userId, // 🔥 REQUIRED (same as Postman)
        },
      );

      if (res.data == null) {
        return {'success': false, 'message': 'Empty response'};
      }

      if (res.data['status'] != 1) {
        return {
          'success': false,
          'message': res.data['message'] ?? 'Failed to load documents',
        };
      }

      return {
        'success': true,
        'data': res.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /* =========================================================
   * (OPTIONAL) GET STUDENT DOCUMENT LIST
   * ========================================================= */
  static Future<Map<String, dynamic>> getStudentDocuments({
    required int studentId,
  }) async {
    try {
      final Response res = await DioClient.dio.post(
        'documents/list',
        data: {'student_id': studentId},
      );

      if (res.data == null) {
        return {'success': false, 'message': 'Empty response'};
      }

      if (res.data['status'] != 1) {
        return {
          'success': false,
          'message': res.data['message'] ?? 'Failed to load documents',
        };
      }

      return {
        'success': true,
        'data': res.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ?? e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
