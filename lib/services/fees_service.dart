import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dio_client.dart';

class FeesService {
  final Dio _dio = DioClient.dio;

  /* ================= FEES SUMMARY ================= */

  Future<Map<String, dynamic>?> getScholarFeesPayments(String batch) async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) {
      throw Exception('User not logged in');
    }

    final response = await _dio.post(
      'getscholarfeespayments',
      data: {
        'user_id': user['id'],
        'api_token': token,
        'batch': batch,
      },
      options: Options(headers: {'x-api-key': token}),
    );

    if (response.data['status'] == 1) {
      return response.data;
    } else {
      throw Exception(response.data['message']);
    }
  }

  /* ================= FEES TRANSACTIONS ================= */

  Future<Map<String, dynamic>?> getScholarFeesTransactions(String batch) async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) {
      throw Exception('User not logged in');
    }

    final response = await _dio.post(
      'getscholarfeestransactions',
      data: {
        'user_id': user['id'],
        'api_token': token,
        'batch': batch,
      },
      options: Options(headers: {'x-api-key': token}),
    );

    if (response.data['status'] == 1) {
      return response.data;
    } else {
      throw Exception(response.data['message']);
    }
  }

  /* ================= BANK DETAILS ================= */
  /// API: getBanksList
  Future<List<dynamic>> getBanksList() async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) {
      throw Exception('User not logged in');
    }

    final response = await _dio.post(
      'getbankslist', // 🔁 change only if backend route name differs
      data: {
        'user_id': user['id'],
        'api_token': token,
      },
      options: Options(headers: {'x-api-key': token}),
    );

    if (response.data['status'] == 1) {
      return List<dynamic>.from(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Banks not available');
    }
  }
}
