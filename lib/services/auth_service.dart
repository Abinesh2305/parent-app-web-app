import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dio_client.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final String schoolId = dotenv.env['SCHOOL_ID'] ?? '';

      //Web-safe token placeholder
      const String fcmToken = 'WEB';

      // backend endpoint
      final response = await DioClient.dio.post(
        'common_user_login',
        data: {
          'email': email.trim(),
          'password': password,
          'fcm_token': fcmToken,
          'device_id': 'web_device',
          'device_type': 'WEB',
          'school_id': schoolId,
        },
      );

      final data = response.data;

      // ================= SAFETY CHECK =================
      if (data is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': 'Invalid server response',
        };
      }

      // ================= LOGIN SUCCESS =================
      if (data['status'] == 1) {
        final user = data['data'];

        if (user is! Map<String, dynamic>) {
          return {
            'success': false,
            'message': 'Invalid user data',
          };
        }

        // 🔹 Force password change (first login)
        if (user['is_app_installed'] == 0) {
          return {
            'success': true,
            'forcePasswordChange': true,
            'userId': user['id'],
            'apiToken': user['api_token'],
          };
        }

        // 🔹 Save to Hive
        final box = Hive.box('settings');
        await box.put('user', user);
        await box.put('language', user['language'] ?? 'en');
        await box.put('token', user['api_token']);

        return {
          'success': true,
          'user': user,
        };
      }

      // ================= LOGIN FAILED =================
      return {
        'success': false,
        'message': data['message']?.toString() ??
            'Invalid email or password',
      };
    }

    // ================= DIO ERROR =================
    on DioException catch (e) {
      final errData = e.response?.data;

      return {
        'success': false,
        'message': errData is Map<String, dynamic>
            ? errData['message']?.toString() ?? 'API error'
            : 'Server not reachable',
      };
    }

    // ================= UNKNOWN ERROR =================
    catch (_) {
      return {
        'success': false,
        'message': 'Unexpected error occurred',
      };
    }
  }
}
