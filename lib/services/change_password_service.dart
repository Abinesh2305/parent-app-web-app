import 'package:dio/dio.dart';
import 'dio_client.dart';

class ChangePasswordService {
  Future<Map<String, dynamic>> changePassword({
    required int userId,
    required String apiToken,
    required String newPassword,
  }) async {
    try {
      Response response = await DioClient.dio.post(
        'change_password',
        data: {
          'user_id': userId,
          'api_token': apiToken,
          'new_password': newPassword,
        },
        options: Options(headers: {
          'x-api-key': apiToken,
        }),
      );

      return response.data;
    } catch (e) {
      return {
        "status": 0,
        "message": "Failed to update password",
        "error": e.toString(),
      };
    }
  }
}
