import 'package:hive/hive.dart';
import 'dio_client.dart';

class HomeService {
  static Future<void> syncHomeContents() async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');

    if (user == null || token == null) return;

    // 🔹 Firebase removed → Web-safe placeholder
    const String fcmToken = "WEB";

    final res = await DioClient.dio.post(
      'homecontents',
      data: {
        'user_id': user['id'],
        'api_token': token,
        'fcm_token': fcmToken, // keep key for backend compatibility
      },
    );

    print("HomeContents Response: ${res.data}");
  }
}
