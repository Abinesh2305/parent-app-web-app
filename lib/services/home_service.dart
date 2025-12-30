import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dio_client.dart';

class HomeService {
  static Future<void> syncHomeContents() async {
    try {
      final box = Hive.box('settings');

      // ✅ ALWAYS use current_student (NOT user)
      final student = box.get('current_student');
      final token = box.get('token');

      // 🛑 HARD SAFETY CHECK (prevents web crash)
      if (student == null || token == null) {
        debugPrint("⏸ HomeService skipped (student/token null)");
        return;
      }

      // 🔹 Web-safe placeholder (Android uses real FCM)
      const String fcmToken = "WEB";

      debugPrint(
        "🏠 HomeService → ${student['name']} (${student['id']})",
      );

      final response = await DioClient.dio.post(
        'homecontents',
        data: {
          // backend expects user_id = student id
          'user_id': student['id'],
          'api_token': token,
          'fcm_token': fcmToken,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      debugPrint("✅ HomeContents response: ${response.data}");
    }

    // 🔒 CRITICAL: prevents Flutter Web app exit
    on DioException catch (e) {
      debugPrint(
        "⚠️ HomeService DioException handled: ${e.type}",
      );
    }

    // 🔒 ABSOLUTE SAFETY NET
    catch (e) {
      debugPrint("⚠️ HomeService unknown error handled: $e");
    }
  }
}
