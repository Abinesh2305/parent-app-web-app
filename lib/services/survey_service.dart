import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:school_dashboard/services/dio_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SurveyService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>?> fetchSurveys({int page = 0}) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      final schoolId = int.parse(dotenv.env['SCHOOL_ID'] ?? '0');

      final response = await _dio.post(
        'postsurveys',
        data: {
          'user_id': user['id'],
          'api_token': token,
          'page_no': page,
          'school_id': schoolId,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      print("Survey API result: ${response.data}");
      return response.data;
    } catch (e) {
      print("Survey fetch error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitSurvey({
    required int surveyId,
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
          'survey_id': surveyId,
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
