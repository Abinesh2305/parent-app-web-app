import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';

class AuthService {
  /* =========================================================
   * NORMAL LOGIN (Parent / First Student)
   * ======================================================= */
  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await DioClient.dio.post(
        'common_user_login',
        data: {
          'email': email.trim(),
          'password': password,
          'device_id': kIsWeb ? 'web_device' : 'mobile_device',
          'device_type': kIsWeb ? 'WEB' : 'ANDROID',
          'fcm_token': '', // web-safe
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': 'Invalid server response',
        };
      }

      if (data['status'] != 1 || data['data'] == null) {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }

      final user = Map<String, dynamic>.from(data['data']);
      final box = Hive.box('settings');

      // ================= SAVE BASE DATA =================
      await box.put('user', user);

      // first student = current student
      await box.put('current_student', user);

      // token for APIs
      await box.put('token', user['api_token']);

      // language (optional)
      await box.put('language', user['language'] ?? 'en');

      // 🔑 REQUIRED FOR STUDENT SWITCH (THIS FIXES YOUR ISSUE)
      await box.put('parent_email', email.trim());
      await box.put('parent_password', password);

      debugPrint("✅ Login success → ${user['name']}");

      return {
        'success': true,
        'user': user,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data?['message']?.toString() ??
            'Server not reachable',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error occurred',
      };
    }
  }

  /* =========================================================
   * 🔁 STUDENT SWITCH RE-AUTH (CRITICAL FOR WEB)
   * ======================================================= */
  Future<bool> switchStudentLogin({
    required String parentEmail,
    required String password,
    required String studentUsername,
  }) async {
    try {
      final response = await DioClient.dio.post(
        'common_user_login',
        data: {
          'email': parentEmail.trim(),
          'password': password,
          'student_username': studentUsername,
          'device_id': kIsWeb ? 'web_device' : 'mobile_device',
          'device_type': kIsWeb ? 'WEB' : 'ANDROID',
          'fcm_token': '',
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) return false;
      if (data['status'] != 1 || data['data'] == null) return false;

      final student = Map<String, dynamic>.from(data['data']);
      final box = Hive.box('settings');

      // 🔁 IMPORTANT: UPDATE BOTH STUDENT + TOKEN
      await box.put('current_student', student);
      await box.put('token', student['api_token']);

      debugPrint(
        "🔁 Student switched → ${student['name']} (${student['id']})",
      );

      return true;
    } on DioException catch (e) {
      debugPrint(
        "❌ Switch student Dio error: ${e.response?.data}",
      );
      return false;
    } catch (e) {
      debugPrint("❌ Switch student error: $e");
      return false;
    }
  }

  /* =========================================================
   * LOGOUT
   * ======================================================= */
  Future<void> logout() async {
    final box = Hive.box('settings');
    await box.clear();
  }
}
