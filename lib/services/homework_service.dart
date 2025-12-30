import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';

class HomeworkService {
  final Dio _dio = DioClient.dio;

  /* ================= GET HOMEWORKS ================= */

  Future<List<dynamic>> getHomeworks({DateTime? date}) async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("⏸ Homework skipped (student/token null)");
      return [];
    }

    try {
      debugPrint(
        "📚 Homework → ${student['name']} (${student['id']})",
      );

      final d = date ?? DateTime.now();
      final formattedDate =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      final response = await _dio.post(
        'homeworks',
        data: {
          "user_id": student['id'],
          "date": formattedDate,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      if (response.statusCode != 200) return [];

      final res = response.data;

      if (res['status'] == 0 &&
          (res['message'] == "No Homework" || res['data'] == null)) {
        return [];
      }

      if (res['status'] == 1 && res['data'] is List) {
        return (res['data'] as List).map((hw) {
          final map = Map<String, dynamic>.from(hw);
          return {
            "id": map["id"],
            "main_ref_no": map["main_ref_no"],
            "subject": map["is_subject_name"] ?? "",
            "description": map["hw_description"] ?? "",
            "date": map["is_hw_date"] ?? "",
            "submissionDate": map["is_hw_submission_date"] ?? "",
            "attachments": (map["is_file_attachments"] ?? [])
                .map((a) => a["img"].toString())
                .toList(),
            "read_status": map["read_status"] ?? "UNREAD",
            "ack_status": map["ack_status"] ?? "PENDING",
            "ack_required": map["ack_required"] ?? 0,
          };
        }).toList();
      }

      return [];
    } on DioException catch (e) {
      debugPrint("❌ Homework Dio error (handled): ${e.type}");
      return [];
    } catch (e) {
      debugPrint("❌ Homework unknown error: $e");
      return [];
    }
  }

  /* ================= GET HOMEWORKS WITH DATE RANGE ================= */

  Future<List<dynamic>> getHomeworksWithDate({
    required DateTime date,
    int days = 0,
  }) async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) return [];

    try {
      final formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final response = await _dio.post(
        'homeworkswithdate',
        data: {
          "user_id": student['id'],
          "date": formattedDate,
          "cnt": days,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      if (response.statusCode != 200) return [];

      final res = response.data;
      if (res['status'] != 1 || res['data'] is! List) return [];

      return (res['data'] as List).map((hw) {
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
    } on DioException catch (e) {
      debugPrint("❌ Homework range Dio error: ${e.type}");
      return [];
    } catch (e) {
      debugPrint("❌ Homework range error: $e");
      return [];
    }
  }

  /* ================= MARK AS READ ================= */

  Future<void> markAsRead(String homeworkRef) async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) return;

    try {
      await _dio.post(
        "homework-read",
        data: {
          "user_id": student['id'],
          "school_id":
              student['school_id'] ?? student['school_college_id'],
          "homework_id": homeworkRef,
        },
        options: Options(headers: {"x-api-key": token}),
      );
    } catch (_) {
      // intentionally ignored
    }
  }

  /* ================= BATCH MARK AS READ ================= */

  Future<bool> batchMarkAsRead(List<String> homeworkIds) async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) return false;

    try {
      final response = await _dio.post(
        "homework-batch-read",
        data: {
          "user_id": student['id'],
          "school_id":
              student['school_id'] ?? student['school_college_id'],
          "homework_ids": homeworkIds,
        },
        options: Options(headers: {"x-api-key": token}),
      );

      return response.statusCode == 200 &&
          response.data['status'] == 1;
    } catch (_) {
      return false;
    }
  }

  /* ================= ACKNOWLEDGE ================= */

  Future<void> acknowledge(String homeworkRef) async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) return;

    try {
      await _dio.post(
        "homework-ack",
        data: {
          "user_id": student['id'],
          "school_id":
              student['school_id'] ?? student['school_college_id'],
          "homework_id": homeworkRef,
        },
        options: Options(headers: {"x-api-key": token}),
      );
    } catch (_) {
      // ignore
    }
  }
}
