import 'dart:typed_data';
import 'dart:io' show File;
import 'package:dio/dio.dart';
import 'dio_client.dart';

class DocumentService {
  /* =========================================================
   * UPLOAD DOCUMENT (WEB + MOBILE SAFE)
   * ========================================================= */
  static Future<Map<String, dynamic>> uploadDocument({
    required int studentId,
    required int classId,
    required int sectionId,
    required String documentType,
    String? otherDocumentName,

    /// 🔥 MOBILE
    File? file,

    /// 🔥 WEB
    Uint8List? fileBytes,
    String? fileName,

    required Function(double) onProgress,
  }) async {
    try {
      if (file == null && fileBytes == null) {
        return {
          'success': false,
          'message': 'No file selected',
        };
      }

      MultipartFile multipartFile;

      // ================== WEB ==================
      if (fileBytes != null) {
        multipartFile = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName ?? 'document',
        );
      }
      // ================== MOBILE ==================
      else {
        multipartFile = await MultipartFile.fromFile(
          file!.path,
          filename: file.path.split('/').last,
        );
      }

      final formData = FormData.fromMap({
        'student_id': studentId,
        'class_id': classId,
        'section_id': sectionId,
        'document_type': documentType,
        if (documentType == 'other' && otherDocumentName != null)
          'other_document_name': otherDocumentName,
        'document': multipartFile,
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
        return {
          'success': false,
          'message': 'Empty server response',
        };
      }

      if (res.data['status'] != 1) {
        return {
          'success': false,
          'message': res.data['message'] ?? 'Upload failed',
        };
      }

      return {
        'success': true,
        'message': res.data['message'] ?? 'Upload successful',
        'data': res.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data?['message'] ??
            e.message ??
            'Network error',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /* =========================================================
   * GET MY DOCUMENT STATUS
   * ========================================================= */
  static Future<Map<String, dynamic>> getMyDocumentStatus({
    required int userId,
  }) async {
    try {
      final Response res = await DioClient.dio.post(
        'documents/my-status',
        data: {'user_id': userId},
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
            e.response?.data?['message'] ??
            e.message ??
            'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /* =========================================================
   * GET STUDENT DOCUMENT LIST (OPTIONAL)
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
            e.response?.data?['message'] ??
            e.message ??
            'Network error',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
