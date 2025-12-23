import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dio_client.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final String schoolId = dotenv.env['SCHOOL_ID'] ?? "";

      // 🔹 Firebase removed → Web-safe token
      const String fcmToken = "WEB";

      final Response response = await DioClient.dio.post(
        'login',
        data: {
          'email': email,
          'password': password,
          'fcm_token': fcmToken, // keep key for backend compatibility
          'device_id': 'web_device',
          'device_type': 'WEB',
          'school_id': schoolId,
        },
      );

      if (response.data["status"] == 1) {
        final user = response.data["data"];

        // 🔹 First install → force password change
        if (user["is_app_installed"] == 0) {
          return {
            "success": true,
            "forcePasswordChange": true,
            "userId": user["id"],
            "apiToken": user["api_token"],
          };
        }

        // 🔹 Save to Hive
        final box = Hive.box('settings');
        box.put("user", user);
        box.put("language", user["language"] ?? "en");
        box.put("token", user["api_token"]);

        // 🔹 Firebase topic subscriptions REMOVED
        // Backend should handle notifications by user_id instead

        return {"success": true, "user": user};
      }

      return {
        "success": false,
        "message": response.data["message"] ?? "Login failed"
      };
    } catch (e, stack) {
      print("❌ Login Error: $e");
      print(stack);

      if (e is DioException) {
        return {
          "success": false,
          "message": e.response?.data["message"] ?? "API error",
        };
      }

      return {"success": false, "message": e.toString()};
    }
  }
}
