import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../services/dio_client.dart';

class ProfileService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>?> getProfileDetails() async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');
      if (user == null || token == null) throw Exception('User not logged in');

      final res = await _dio.post(
        'profile_details',
        data: {'user_id': user['id'], 'api_token': token},
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } catch (e) {
      print('⚠️ getProfileDetails error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateAlternateMobile({
    required String mobile1,
  }) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');
      if (user == null || token == null) throw Exception('User not logged in');

      final res = await _dio.post(
        'update_profile',
        data: {
          'user_id': user['id'],
          'api_token': token,
          'name': user['name'], // required field in API
          'mobile1': mobile1,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } catch (e) {
      print('⚠️ updateAlternateMobile error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateProfileImage(File file) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');
      if (user == null || token == null) throw Exception('User not logged in');

      final formData = FormData.fromMap({
        'user_id': user['id'],
        'api_token': token,
        'profile_image': await MultipartFile.fromFile(file.path,
            filename: file.path.split('/').last),
      });

      final res = await _dio.post(
        'update_profileimage',
        data: formData,
        options: Options(headers: {
          'x-api-key': token,
          'Content-Type': 'multipart/form-data'
        }),
      );

      return res.data;
    } catch (e) {
      print('⚠️ updateProfileImage error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> deleteProfileImage() async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');
      if (user == null || token == null) throw Exception('User not logged in');

      final res = await _dio.post(
        'delete_profileimage',
        data: {'user_id': user['id'], 'api_token': token},
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } catch (e) {
      print('⚠️ deleteProfileImage error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> changePassword(String newPassword) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');
      if (user == null || token == null) throw Exception('User not logged in');

      final res = await _dio.post(
        'profile_change_password',
        data: {
          'user_id': user['id'],
          'api_token': token,
          'new_password': newPassword,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      // Update Hive user + token if API sends refreshed data
      if (res.data != null &&
          res.data['status'] == 1 &&
          res.data['data'] != null) {
        final updatedUser = res.data['data'];
        await box.put('user', updatedUser);
        await box.put('token', updatedUser['api_token']);
      }

      return res.data;
    } catch (e) {
      print('⚠️ changePassword error: $e');
      return null;
    }
  }
}
