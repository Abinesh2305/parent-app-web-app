import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dio_client.dart';

class AttendanceService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>?> getAttendance(String monthYear) async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) {
      throw Exception("User not logged in");
    }

    final body = {
      "user_id": user['id'],
      "monthyr": monthYear,
    };

    final response = await _dio.post(
      'attendance',
      data: body,
      options: Options(headers: {'x-api-key': token}),
    );

    if (response.statusCode == 200) {
      final res = response.data;
      if (res['status'] == 1 && res['data'] != null) {
        return res['data'];
      } else {
        throw Exception(res['message'] ?? "Failed to load attendance");
      }
    } else {
      throw Exception("Network error: ${response.statusCode}");
    }
  }
}
