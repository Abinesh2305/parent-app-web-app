import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';

class FeesService {
  final Dio _dio = DioClient.dio;

  /* ================= FEES SUMMARY ================= */

  Future<Map<String, dynamic>?> getScholarFeesPayments(String batch) async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("❌ FeesService: student/token missing (payments)");
      return null;
    }

    try {
      final response = await _dio.post(
        'getscholarfeespayments',
        data: {
          'user_id': student['id'],
          'api_token': token,
          'batch': batch,
        },
        options: Options(
          headers: {'x-api-key': token},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.data != null && response.data['status'] == 1) {
        return Map<String, dynamic>.from(response.data);
      }

      debugPrint(
        "❌ Fees payments API error: ${response.data?['message']}",
      );
      return null;
    } on DioException catch (e) {
      debugPrint("❌ Fees payments Dio error (handled): ${e.type}");
      return null;
    } catch (e) {
      debugPrint("❌ Fees payments unknown error: $e");
      return null;
    }
  }

  /* ================= FEES TRANSACTIONS ================= */

  Future<Map<String, dynamic>?> getScholarFeesTransactions(String batch) async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("❌ FeesService: student/token missing (transactions)");
      return null;
    }

    try {
      final response = await _dio.post(
        'getscholarfeestransactions',
        data: {
          'user_id': student['id'],
          'api_token': token,
          'batch': batch,
        },
        options: Options(
          headers: {'x-api-key': token},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.data != null && response.data['status'] == 1) {
        return Map<String, dynamic>.from(response.data);
      }

      debugPrint(
        "❌ Fees transactions API error: ${response.data?['message']}",
      );
      return null;
    } on DioException catch (e) {
      debugPrint("❌ Fees transactions Dio error (handled): ${e.type}");
      return null;
    } catch (e) {
      debugPrint("❌ Fees transactions unknown error: $e");
      return null;
    }
  }

  /* ================= BANK DETAILS ================= */

  Future<List<dynamic>?> getBanksList() async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("❌ FeesService: student/token missing (banks)");
      return null;
    }

    try {
      final response = await _dio.post(
        'getbankslist',
        data: {
          'user_id': student['id'],
          'api_token': token,
        },
        options: Options(
          headers: {'x-api-key': token},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.data != null && response.data['status'] == 1) {
        return List<dynamic>.from(response.data['data']);
      }

      debugPrint(
        "❌ Banks list API error: ${response.data?['message']}",
      );
      return null;
    } on DioException catch (e) {
      debugPrint("❌ Banks list Dio error (handled): ${e.type}");
      return null;
    } catch (e) {
      debugPrint("❌ Banks list unknown error: $e");
      return null;
    }
  }
}
