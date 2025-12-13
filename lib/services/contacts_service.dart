import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../services/dio_client.dart';

class ContactsService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>?> getContactsList() async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      final res = await _dio.post(
        'getcontactslist',
        data: {
          'user_id': user['id'],
          'api_token': token,
          'school_id': user['school_college_id'],
        },
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } catch (e) {
      print("Contacts list error: $e");
      return null;
    }
  }
}
