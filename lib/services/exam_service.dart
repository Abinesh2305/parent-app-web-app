import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../services/dio_client.dart';

class ExamService {
  final Dio _dio = DioClient.dio;

  Future<List<dynamic>?> getExamList() async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      if (user == null || token == null) {
        throw Exception('User not logged in');
      }

      final response = await _dio.post(
        'examdetails',
        data: {
          'user_id': user['id'].toString(),
          'api_token': token,
          'exam_id': 0,
          'term_id': 0,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      if (response.data != null &&
          response.data['status'] == 1 &&
          response.data['data'] != null) {
        return List<dynamic>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Exam list fetch error: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getExamTimetable(int examId) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      if (user == null || token == null) {
        throw Exception('User not logged in');
      }

      final response = await _dio.post(
        'examtimetable',
        data: {
          'user_id': user['id'].toString(),
          'api_token': token,
          'exam_id': examId.toString(),
          'term_id': 0,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      if (response.data != null &&
          response.data['status'] == 1 &&
          response.data['data'] != null) {
        return List<dynamic>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Exam timetable fetch error: $e');
      return null;
    }
  }

  /// Attempts to fetch marks / results for a specific exam.
  /// Backend may return marks inside examdetails when exam_id is supplied.
  /// This function normalizes multiple possible shapes into List<Map>.
  Future<List<Map<String, dynamic>>?> getExamResult(int examId) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      if (user == null || token == null) {
        throw Exception('User not logged in');
      }

      // Reuse examdetails endpoint (MarksEntry used server-side when exam_id > 0)
      final response = await _dio.post(
        'examdetails',
        data: {
          'user_id': user['id'].toString(),
          'api_token': token,
          'exam_id': examId.toString(),
          'term_id': 0,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      if (response.data == null || response.data['status'] != 1) {
        return null;
      }

      final raw = response.data['data'];
      if (raw == null) return null;

      // If backend returned a list and the first element contains marks
      if (raw is List && raw.isNotEmpty) {
        final first = raw.first;

        // Common case: MarksEntry with marksentryitems
        if (first is Map && first.containsKey('marksentryitems')) {
          final items = first['marksentryitems'];
          if (items is List) {
            return items
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }

        // Alternative: `marks` or `results` field
        if (first is Map &&
            (first.containsKey('marks') || first.containsKey('results'))) {
          final list = first['marks'] ?? first['results'];
          if (list is List) {
            return list
                .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }

        // If each element in raw is itself a subject-mark row (rare)
        if (raw.every((e) => e is Map && e.containsKey('subject'))) {
          return raw
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }

      // If the server returned an object with timetable-like structure that includes marks
      if (raw is Map) {
        // Try to find a plausible list inside the response
        for (final key in ['marksentryitems', 'marks', 'results', 'data']) {
          if (raw.containsKey(key) && raw[key] is List) {
            return (raw[key] as List)
                .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(e),
                )
                .toList();
          }
        }
      }

      return null;
    } catch (e) {
      print('Exam result fetch error: $e');
      return null;
    }
  }
}
