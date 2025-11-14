import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dio_client.dart';

class ResendOtpService {
  Future<Map<String, dynamic>> resendOtp(String mobile) async {
    try {
      String schoolId = dotenv.env['SCHOOL_ID'] ?? "";

      Response response = await DioClient.dio.post(
        'resend_otp',
        data: {
          'mobile': mobile,
          'school_id': schoolId,
        },
      );

      print("✅ Resend OTP API Response: ${response.data}");

      if (response.data["status"] == 1) {
        return {
          "success": true,
          "message": response.data["message"] ?? "OTP sent successfully",
          "data": response.data["data"]
        };
      }

      return {
        "success": false,
        "message": response.data["message"] ?? "Failed to resend OTP"
      };
    } catch (e, stack) {
      print("❌ Resend OTP Error: $e");
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
