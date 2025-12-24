import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dio_client.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final String schoolId = dotenv.env['SCHOOL_ID'] ?? "";

      const String fcmToken = "WEB";

      final response = await DioClient.dio.post(
        'login',
        data: {
          'email': email,
          'password': password,
          'fcm_token': fcmToken,
          'device_id': 'web_device',
          'device_type': 'WEB',
          'school_id': schoolId,
        },
      );

      final data = response.data;

      // ✅ VERY IMPORTANT CHECK
      if (data is! Map<String, dynamic>) {
        return {
          "success": false,
          "message": "Invalid server response"
        };
      }

      if (data['status'] == 1) {
        final user = data['data'];

        if (user is! Map) {
          return {
            "success": false,
            "message": "Invalid user data"
          };
        }

        // 🔹 First install → force password change
        if (user['is_app_installed'] == 0) {
          return {
            "success": true,
            "forcePasswordChange": true,
            "userId": user['id'],
            "apiToken": user['api_token'],
          };
        }

        // 🔹 Save to Hive
        final box = Hive.box('settings');
        box.put("user", user);
        box.put("language", user["language"] ?? "en");
        box.put("token", user["api_token"]);

        return {
          "success": true,
          "user": user
        };
      }

      // ❌ Login failed (status != 1)
      return {
        "success": false,
        "message": data['message'] ?? "Invalid email or password"
      };
    } on DioException catch (e) {
      // ✅ SAFE Dio error handling
      final errData = e.response?.data;

      return {
        "success": false,
        "message": errData is Map
            ? errData['message'] ?? "API error"
            : "Server not reachable"
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Unexpected error occurred"
      };
    }
  }
}

