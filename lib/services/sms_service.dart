import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dio_client.dart';

class SmsService {
  final Dio _dio = DioClient.dio;

  Future<List<dynamic>> getSMSCommunications({
    DateTime? fromDate,
    DateTime? toDate,
    dynamic category,
    String? type,
    String? search,
  }) async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) {
      throw Exception("User not logged in");
    }

    final body = {
      "user_id": user['id'],
      "api_token": token,
      "page_no": 0, // default 15
      "search": search ?? "",
      "sms_type": type ?? "",
      "category_id": category != null ? category['id'] ?? 0 : 0,
      "from_date": fromDate != null
          ? "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}"
          : "",
      "to_date": toDate != null
          ? "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}"
          : "",
    };

    final response = await _dio.post(
      'getSMSCommunications',
      data: body,
      options: Options(headers: {'x-api-key': token}),
    );

    if (response.statusCode == 200) {
      final res = response.data;

      if (res['status'] == 0) return [];

      if (res['status'] == 1 && res['data'] is List) {
        return res['data'];
      }
    }

    throw Exception("Failed to load SMS communications");
  }
}
