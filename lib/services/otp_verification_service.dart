import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dio_client.dart';

class OtpVerificationService {
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    try {
      String schoolId = dotenv.env['SCHOOL_ID'] ?? "";

      Response response = await DioClient.dio.post(
        'verify_otp',
        data: {
          'mobile': mobile,
          'otp': otp,
          'school_id': schoolId,
        },
      );

      print("✅ OTP Verify API Response: ${response.data}");

      if (response.data["status"] == 1) {
        return {
          "success": true,
          "message": response.data["message"] ?? "OTP verified successfully",
          "data": response.data["data"]
        };
      }

      return {
        "success": false,
        "message": response.data["message"] ?? "Invalid OTP"
      };
    } catch (e, stack) {
      print("❌ OTP Verification Error: $e");
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
