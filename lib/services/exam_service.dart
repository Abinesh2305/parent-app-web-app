import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../services/dio_client.dart';

class ExamService {
  final Dio _dio = DioClient.dio;

  /* ================= EXAM LIST ================= */

  Future<List<dynamic>?> getExamList() async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("❌ ExamService: student/token missing (list)");
      return null;
    }

    try {
      final response = await _dio.post(
        'examdetails',
        data: {
          'user_id': student['id'].toString(),
          'api_token': token,
          'exam_id': 0,
          'term_id': 0,
        },
        options: Options(
          headers: {'x-api-key': token},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.data != null &&
          response.data['status'] == 1 &&
          response.data['data'] != null) {
        return List<dynamic>.from(response.data['data']);
      }

      return null;
    } on DioException catch (e) {
      // 🔒 REQUIRED FOR FLUTTER WEB
      debugPrint("❌ Exam list Dio error (handled): ${e.type}");
      return null;
    } catch (e) {
      debugPrint("❌ Exam list unknown error: $e");
      return null;
    }
  }

  /* ================= EXAM TIMETABLE ================= */

  Future<List<dynamic>?> getExamTimetable(int examId) async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("❌ ExamService: student/token missing (timetable)");
      return null;
    }

    try {
      final response = await _dio.post(
        'examtimetable',
        data: {
          'user_id': student['id'].toString(),
          'api_token': token,
          'exam_id': examId.toString(),
          'term_id': 0,
        },
        options: Options(
          headers: {'x-api-key': token},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.data != null &&
          response.data['status'] == 1 &&
          response.data['data'] != null) {
        return List<dynamic>.from(response.data['data']);
      }

      return null;
    } on DioException catch (e) {
      debugPrint("❌ Exam timetable Dio error (handled): ${e.type}");
      return null;
    } catch (e) {
      debugPrint("❌ Exam timetable unknown error: $e");
      return null;
    }
  }

  /* ================= EXAM RESULT ================= */

  Future<List<Map<String, dynamic>>?> getExamResult(int examId) async {
    final box = Hive.box('settings');
    final student = box.get('current_student');
    final token = box.get('token');

    if (student == null || token == null) {
      debugPrint("❌ ExamService: student/token missing (result)");
      return null;
    }

    try {
      final response = await _dio.post(
        'examdetails',
        data: {
          'user_id': student['id'].toString(),
          'api_token': token,
          'exam_id': examId.toString(),
          'term_id': 0,
        },
        options: Options(
          headers: {'x-api-key': token},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.data == null || response.data['status'] != 1) {
        return null;
      }

      final raw = response.data['data'];
      if (raw == null) return null;

      // ---- normalize shapes ----

      if (raw is List && raw.isNotEmpty) {
        final first = raw.first;

        if (first is Map && first.containsKey('marksentryitems')) {
          final items = first['marksentryitems'];
          if (items is List) {
            return items
                .map<Map<String, dynamic>>(
                    (e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }

        if (first is Map &&
            (first.containsKey('marks') ||
                first.containsKey('results'))) {
          final list = first['marks'] ?? first['results'];
          if (list is List) {
            return list
                .map<Map<String, dynamic>>(
                    (e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }

        if (raw.every((e) => e is Map && e.containsKey('subject'))) {
          return raw
              .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }

      if (raw is Map) {
        for (final key in ['marksentryitems', 'marks', 'results', 'data']) {
          if (raw.containsKey(key) && raw[key] is List) {
            return (raw[key] as List)
                .map<Map<String, dynamic>>(
                    (e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
      }

      return null;
    } on DioException catch (e) {
      debugPrint("❌ Exam result Dio error (handled): ${e.type}");
      return null;
    } catch (e) {
      debugPrint("❌ Exam result unknown error: $e");
      return null;
    }
  }
}
