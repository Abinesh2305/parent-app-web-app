import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dio_client.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final Dio _dio = DioClient.dio;

  Future<List<dynamic>> getPostCommunications({
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

    int typeValue = 0; // 0 = all, 1 = post, 2 = sms
    if (type == "post") typeValue = 1;
    if (type == "sms") typeValue = 2;

    final body = {
      "user_id": user['id'],
      "api_token": token,
      "page_no": 0,
      "category_id": category != null ? category['id'] ?? 0 : 0,
      "search": search ?? "",
      "from_date": fromDate != null
          ? "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}"
          : "",
      "to_date": toDate != null
          ? "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}"
          : "",
      "type": typeValue,
    };

    final response = await _dio.post(
      'postCommunications',
      data: body,
      options: Options(headers: {'x-api-key': token}),
    );

    if (response.statusCode == 200) {
      final res = response.data;

      // When backend returns "No Posts", just return an empty list
      if (res['status'] == 0 &&
          (res['message'] == "No Posts" || res['data'] == null)) {
        return [];
      }

      if (res['status'] == 1 && res['data'] is List) {
        return res['data'];
      }

      throw Exception(res['message'] ?? "Failed to load notifications");
    } else {
      throw Exception("Network error: ${response.statusCode}");
    }
  }

  Future<bool> acknowledgePost(int postId) async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) {
      debugPrint("[acknowledgePost] User not logged in");
      return false;
    }

    final body = {
      "user_id": user['id'],
      "api_token": token,
      "post_id": postId,
    };

    debugPrint(
        "[acknowledgePost] Sending request to admin/communication/acknowledge");
    debugPrint("[acknowledgePost] Body: $body");

    try {
      final response = await _dio.post(
        'admin/communication/acknowledge',
        data: body,
        options: Options(headers: {'x-api-key': token}),
      );

      debugPrint("[acknowledgePost] Status Code: ${response.statusCode}");
      debugPrint("[acknowledgePost] Response Data: ${response.data}");

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['status'] == 1) {
        return true;
      } else {
        debugPrint("[acknowledgePost] API returned failure: ${response.data}");
        return false;
      }
    } catch (e, stack) {
      debugPrint("[acknowledgePost] Exception: $e\n$stack");
      return false;
    }
  }

  Future<List<dynamic>> getCategories() async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) {
      throw Exception("User not logged in");
    }

    final details = user['userdetails'];

    final body = {
      "user_id": user['id'],
      "api_token": token,
      "school_id": details['school_id'] ??
          details['school_college_id'] ??
          details['institute_id'] ??
          details['school'] ??
          details['schoolId'],
    };

    final response = await _dio.post(
      'admin/categories', // full and correct route path
      data: body,
      options: Options(headers: {'x-api-key': token}),
    );

    debugPrint("Available user keys: ${user.keys}");

    if (response.statusCode == 200 && response.data['status'] == 1) {
      final data = response.data['data'];
      if (data is List) {
        return data;
      } else {
        throw Exception("Unexpected response format");
      }
    } else {
      throw Exception(response.data['message'] ?? "Failed to load categories");
    }
  }

  // NotificationService.markAsRead
  Future<bool> markAsRead(int postId) async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) {
      debugPrint("[markAsRead] User not logged in");
      return false;
    }

    final body = {
      "user_id": user['id'],
      "api_token": token,
      "post_id": postId,
    };

    debugPrint("[markAsRead] Sending request to admin/communication/mark-read");
    debugPrint("[markAsRead] Body: $body");

    try {
      final response = await _dio.post(
        'admin/communication/mark-read',
        data: body,
        options: Options(headers: {'x-api-key': token}),
      );

      debugPrint("[markAsRead] Status Code: ${response.statusCode}");
      debugPrint("[markAsRead] Response Data: ${response.data}");

      if (response.statusCode == 200 && response.data['status'] == 1) {
        return true;
      } else {
        debugPrint("[markAsRead] API returned failure: ${response.data}");
        return false;
      }
    } catch (e, stack) {
      debugPrint("[markAsRead] Exception: $e\n$stack");
      return false;
    }
  }

  Future<bool> saveBatchRead(List<dynamic> postIds) async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) return false;

    final body = {
      "user_id": user['id'],
      "api_token": token,
      "post_ids": postIds,
    };

    final response = await _dio.post(
      "admin/communication/batch-mark-read",
      data: body,
      options: Options(headers: {'x-api-key': token}),
    );

    return response.statusCode == 200 && response.data['status'] == 1;
  }

  Future<bool> syncReadStatus(Map<String, String> pendingReads) async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) return false;

    final postIds = pendingReads.keys.toList();

    final body = {
      "user_id": user['id'],
      "api_token": token,
      "post_ids": postIds,
    };

    final response = await _dio.post(
      'admin/communication/batch-mark-read',
      data: body,
      options: Options(headers: {'x-api-key': token}),
    );

    return response.statusCode == 200 && response.data['status'] == 1;
  }
}
