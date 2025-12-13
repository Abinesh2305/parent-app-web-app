import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../services/dio_client.dart';

class GalleryService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>?> getGallery({int page = 0}) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      final res = await _dio.post(
        'getgallerylist',
        data: {'user_id': user['id'], 'api_token': token, 'page_no': page},
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } catch (e) {
      print("Gallery error: $e");
      return null;
    }
  }
}
