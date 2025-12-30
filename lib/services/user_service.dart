import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';

class UserService {
  /// ================= GET STUDENT LIST =================
  Future<List<Map<String, dynamic>>> getMobileScholars() async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      if (user == null || token == null) return [];

      final response = await DioClient.dio.post(
        'getmobilescholars',
        data: {
          "user_id": user['id'],
        },
        options: Options(
          headers: {"x-api-key": token},
        ),
      );

      if (response.data != null && response.data['status'] == 1) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }

      return [];
    } catch (e) {
      debugPrint("❌ getMobileScholars error: $e");
      return [];
    }
  }
}
