import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';

class AttendanceService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>?> getAttendance(String monthYear) async {
    final box = Hive.box('settings');

    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("❌ Attendance: student or token missing");
      return null;
    }

    debugPrint(
      "📡 Attendance API → ${student['name']} (${student['id']})",
    );

    try {
      final response = await _dio.post(
        'attendance',
        data: {
          "user_id": student['id'], // backend expects this
          "monthyr": monthYear,
        },
        options: Options(
          headers: {'x-api-key': token},

          // 🔒 REQUIRED FOR WEB STABILITY
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['status'] == 1 &&
          response.data['data'] != null) {
        return Map<String, dynamic>.from(response.data['data']);
      }

      debugPrint(
        "❌ Attendance API returned error: ${response.data?['message']}",
      );
      return null;
    } on DioException catch (e) {
      // 🚨 THIS PREVENTS WEB APP EXIT
      debugPrint(
        "❌ Attendance Dio error (handled): ${e.type}",
      );
      return null;
    } catch (e) {
      debugPrint("❌ Attendance unknown error: $e");
      return null;
    }
  }
}
