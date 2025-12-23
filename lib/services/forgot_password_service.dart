import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dio_client.dart';

class ForgotPasswordService {
  Future<Map<String, dynamic>> sendForgotPassword(String mobile) async {
    try {
      // 🔹 Load env variables
      final String schoolId = dotenv.env['SCHOOL_ID'] ?? "";

      // 🔹 Firebase removed → Web-safe placeholder
      const String fcmToken = "WEB";

      // 🔹 API request
      final Response response = await DioClient.dio.post(
        'forgot_password',
        data: {
          'mobile': mobile,
          'school_id': schoolId,
          'fcm_token': fcmToken, // keep key for backend compatibility
          'device_id': 'web_device',
          'device_type': 'WEB',
        },
      );

      print("✅ Forgot Password API Response: ${response.data}");

      // 🔹 Success
      if (response.data["status"] == 1) {
        return {
          "success": true,
          "message": response.data["message"] ?? "OTP sent successfully",
          "data": response.data["data"]
        };
      }

      // 🔹 Failure
      return {
        "success": false,
        "message": response.data["message"] ?? "Failed to send OTP"
      };
    } catch (e, stack) {
      print("❌ Forgot Password Error: $e");
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
