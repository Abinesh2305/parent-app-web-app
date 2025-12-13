import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dio_client.dart';

class ForgotPasswordService {
  Future<Map<String, dynamic>> sendForgotPassword(String mobile) async {
    try {
      // Load env variables
      String schoolId = dotenv.env['SCHOOL_ID'] ?? "";
      String fcmToken = await FirebaseMessaging.instance.getToken() ?? "";

      // Perform API request using the global DioClient
      Response response = await DioClient.dio.post(
        'forgot_password',
        data: {
          'mobile': mobile,
          'school_id': schoolId,
          'fcm_token': fcmToken,
          'device_id': 'device_001',
          'device_type': 'ANDROID',
        },
      );

      print("✅ Forgot Password API Response: ${response.data}");

      // Success response (status = 1)
      if (response.data["status"] == 1) {
        return {
          "success": true,
          "message": response.data["message"] ?? "OTP sent successfully",
          "data": response.data["data"]
        };
      }

      // Failure (status != 1)
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
