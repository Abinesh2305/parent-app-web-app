import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:school_dashboard/services/dio_client.dart';

class SurveyService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>?> fetchSurveys({int page = 0}) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      final res = await _dio.post(
        'postsurveys',
        data: {
          'user_id': user['id'],
          'api_token': token,
          'page_no': page,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } catch (e) {
      print("Survey fetch error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitSurvey({
    required int postId,
    required int respondId,
  }) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      final res = await _dio.post(
        'postsurveyrespond',
        data: {
          'user_id': user['id'],
          'api_token': token,
          'post_id': postId,
          'respond_id': respondId,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } catch (e) {
      print("Survey submit error: $e");
      return null;
    }
  }
}
