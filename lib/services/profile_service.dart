import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';

class ProfileService {
  final Dio _dio = DioClient.dio;

  /* ================= PROFILE DETAILS ================= */

  Future<Map<String, dynamic>?> getProfileDetails() async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("❌ ProfileService: student/token missing");
      return null;
    }

    try {
      final res = await _dio.post(
        'profile_details',
        data: {
          'user_id': student['id'],
          'api_token': token,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } on DioException catch (e) {
      debugPrint("❌ Profile details Dio error: ${e.type}");
      return null;
    } catch (e) {
      debugPrint("❌ Profile details error: $e");
      return null;
    }
  }

  /* ================= UPDATE ALT MOBILE ================= */

  Future<Map<String, dynamic>?> updateAlternateMobile({
    required String mobile1,
  }) async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("❌ Update mobile: student/token missing");
      return null;
    }

    try {
      final res = await _dio.post(
        'update_profile',
        data: {
          'user_id': student['id'],
          'api_token': token,
          'name': student['name'], // API requires name
          'mobile1': mobile1,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } on DioException catch (e) {
      debugPrint("❌ Update mobile Dio error: ${e.type}");
      return null;
    } catch (e) {
      debugPrint("❌ Update mobile error: $e");
      return null;
    }
  }

  /* ================= UPDATE PROFILE IMAGE ================= */

  /// ⚠️ Image upload should be handled differently on Web
  /// This method should only be called on MOBILE
  Future<Map<String, dynamic>?> updateProfileImage({
    required MultipartFile file,
  }) async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("❌ Update image: student/token missing");
      return null;
    }

    try {
      final formData = FormData.fromMap({
        'user_id': student['id'],
        'api_token': token,
        'profile_image': file,
      });

      final res = await _dio.post(
        'update_profileimage',
        data: formData,
        options: Options(
          headers: {
            'x-api-key': token,
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return res.data;
    } on DioException catch (e) {
      debugPrint("❌ Update image Dio error: ${e.type}");
      return null;
    } catch (e) {
      debugPrint("❌ Update image error: $e");
      return null;
    }
  }

  /* ================= DELETE PROFILE IMAGE ================= */

  Future<Map<String, dynamic>?> deleteProfileImage() async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("❌ Delete image: student/token missing");
      return null;
    }

    try {
      final res = await _dio.post(
        'delete_profileimage',
        data: {
          'user_id': student['id'],
          'api_token': token,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } on DioException catch (e) {
      debugPrint("❌ Delete image Dio error: ${e.type}");
      return null;
    } catch (e) {
      debugPrint("❌ Delete image error: $e");
      return null;
    }
  }

  /* ================= CHANGE PASSWORD ================= */

  Future<Map<String, dynamic>?> changePassword(String newPassword) async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("❌ Change password: student/token missing");
      return null;
    }

    try {
      final res = await _dio.post(
        'profile_change_password',
        data: {
          'user_id': student['id'],
          'api_token': token,
          'new_password': newPassword,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      // 🔁 Update Hive if backend refreshes token
      if (res.data != null &&
          res.data['status'] == 1 &&
          res.data['data'] != null) {
        await box.put('current_student', res.data['data']);
        await box.put('token', res.data['data']['api_token']);
      }

      return res.data;
    } on DioException catch (e) {
      debugPrint("❌ Change password Dio error: ${e.type}");
      return null;
    } catch (e) {
      debugPrint("❌ Change password error: $e");
      return null;
    }
  }
}
