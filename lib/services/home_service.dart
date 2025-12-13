import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive/hive.dart';
import 'dio_client.dart';

class HomeService {
  static Future<void> syncHomeContents() async {
    final box = Hive.box('settings');
    final user = box.get('user');
    final token = box.get('token');
    if (user == null) return;

    final fcm = await FirebaseMessaging.instance.getToken();

    final res = await DioClient.dio.post(
      'homecontents',
      data: {
        'user_id': user['id'],
        'api_token': token,
        'fcm_token': fcm,
      },
    );

    print("HomeContents Response: ${res.data}");
  }
}
