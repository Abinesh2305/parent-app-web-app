import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dio_client.dart';

class ResetPasswordService {
  Future<Map<String, dynamic>> resetPassword({
    required String mobile,
    required String otp,
    required String newPassword,
  }) async {
    try {
      String schoolId = dotenv.env['SCHOOL_ID'] ?? "";

      Response response = await DioClient.dio.post(
        'reset_password',
        data: {
          'mobile': mobile,
          'school_id': schoolId,
          'otp': otp,
          'new_password': newPassword,
        },
      );

      print("✅ Reset Password API Response: ${response.data}");

      if (response.data["status"] == 1) {
        return {
          "success": true,
          "message": response.data["message"] ?? "Password reset successfully"
        };
      }

      return {
        "success": false,
        "message": response.data["message"] ?? "Failed to reset password"
      };
    } catch (e, stack) {
      print("❌ Reset Password Error: $e");
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
