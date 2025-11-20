import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dio_client.dart';

class HomeworkService {
  final Dio _dio = DioClient.dio;

  /// Fetch homework list for a given date (defaults to today)
  Future<List<dynamic>> getHomeworks({DateTime? date}) async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) {
      throw Exception("User not logged in");
    }

    final formattedDate =
        "${(date ?? DateTime.now()).year}-${(date ?? DateTime.now()).month.toString().padLeft(2, '0')}-${(date ?? DateTime.now()).day.toString().padLeft(2, '0')}";

    final body = {
      "user_id": user['id'],
      "api_token": token,
      "date": formattedDate,
    };

    final response = await _dio.post(
      'homeworks',
      data: body,
      options: Options(headers: {'x-api-key': token}),
    );

    if (response.statusCode == 200) {
      final res = response.data;

      // Handle "No Homework" or empty response gracefully
      if (res['status'] == 0 &&
          (res['message'] == "No Homework" || res['data'] == null)) {
        return [];
      }

      if (res['status'] == 1 && res['data'] is List) {
        final List<dynamic> list = res['data'];
        // Normalize the data to a consistent structure
        return list.map((hw) {
          final map = Map<String, dynamic>.from(hw);
          return {
            "id": map["main_ref_no"],
            "subject": map["is_subject_name"] ?? "",
            "description": map["hw_description"] ?? "",
            "date": map["is_hw_date"] ?? "",
            "submissionDate": map["is_hw_submission_date"] ?? "",
            "attachments": (map["is_file_attachments"] ?? [])
                .map((a) => a["img"].toString())
                .toList(),

            // new fields from backend
            "read_status": map["read_status"] ?? "UNREAD",
            "ack_status": map["ack_status"] ?? "PENDING",
            "ack_required": map["ack_required"] ?? 0,
          };
        }).toList();
      }

      throw Exception(res['message'] ?? "Failed to load homeworks");
    } else {
      throw Exception("Network error: ${response.statusCode}");
    }
  }

  /// Get homeworks over a date range (like last N days)
  Future<List<dynamic>> getHomeworksWithDate({
    required DateTime date,
    int days = 0,
  }) async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) {
      throw Exception("User not logged in");
    }

    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final body = {
      "user_id": user['main_ref_no'],
      "api_token": token,
      "date": formattedDate,
      "cnt": days,
    };

    final response = await _dio.post(
      'homeworkswithdate',
      data: body,
      options: Options(headers: {'x-api-key': token}),
    );

    if (response.statusCode == 200) {
      final res = response.data;
      if (res['status'] == 0) return [];

      if (res['status'] == 1 && res['data'] is List) {
        final List<dynamic> list = res['data'];
        return list.map((hw) {
          final map = Map<String, dynamic>.from(hw);
          return {
            "id": map["id"],
            "subject": map["is_subject_name"] ?? "",
            "description": map["hw_description"] ?? "",
            "date": map["is_hw_date"] ?? "",
            "submissionDate": map["is_hw_submission_date"] ?? "",
            "attachments": (map["is_file_attachments"] ?? [])
                .map((a) => a["img"].toString())
                .toList(),
          };
        }).toList();
      }

      throw Exception(res['message'] ?? "Failed to load homeworks");
    } else {
      throw Exception("Network error: ${response.statusCode}");
    }
  }

  Future<void> markAsRead(int homeworkId) async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    await _dio.post(
      "homework-read",
      data: {
        "user_id": user['id'],
        "school_id": user['school_college_id'],
        "homework_id": homeworkId,
      },
      options: Options(headers: {"x-api-key": token}),
    );
  }

  Future<void> acknowledge(int homeworkId) async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    await _dio.post(
      "admin/homework-ack",
      data: {
        "user_id": user['id'],
        "school_id": user['school_college_id'],
        "homework_id": homeworkId,
      },
      options: Options(headers: {"x-api-key": token}),
    );
  }
}
