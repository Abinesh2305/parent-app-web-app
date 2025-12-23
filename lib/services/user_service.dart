import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'dio_client.dart';
import 'package:flutter/foundation.dart';


class UserService {
  Future<List<dynamic>> getMobileScholars() async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      if (user == null || token == null) return [];

      final response = await DioClient.dio.post(
        'getmobilescholars',
        data: {
          "user_id": user['id'],
          "api_token": token,
        },
        options: Options(headers: {
          "x-api-key": token,
        }),
      );

      if (response.data['status'] == 1) {
        return response.data['data'] as List<dynamic>;
      }

      return [];
    } catch (e) {
      debugPrint("❌ getMobileScholars error: $e");
      return [];
    }
  }
}