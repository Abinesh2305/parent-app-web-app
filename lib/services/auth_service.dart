import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dio_client.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      String schoolId = dotenv.env['SCHOOL_ID'] ?? "";
      String fcmToken = await FirebaseMessaging.instance.getToken() ?? "";

      Response response = await DioClient.dio.post(
        'login',
        data: {
          'email': email,
          'password': password,
          'fcm_token': fcmToken,
          'device_id': 'device_001',
          'device_type': 'ANDROID',
          'school_id': schoolId,
        },
      );

      print("API Response: ${response.data}");

      if (response.data["status"] == 1) {
        var user = response.data["data"];

        // Save to Hive
        var box = Hive.box('settings');
        box.put("user", user);
        box.put("language", user["language"] ?? "en");
        box.put("token", user["api_token"]);

        // Safe Topic Subscription
        String? className = user["userdetails"]["is_class_name"];
        String? section = user["userdetails"]["is_section_name"];

        if (className != null && section != null) {
          className = className.replaceAll(" ", "_"); // remove spaces
          section = section.replaceAll(" ", "_");

          await FirebaseMessaging.instance
              .subscribeToTopic("School_Scholars_$schoolId");
          await FirebaseMessaging.instance
              .subscribeToTopic("Scholar_${user["id"]}");
          await FirebaseMessaging.instance
              .subscribeToTopic("Section_${className}_$section");

          final groups = user["groups"] ?? [];
          for (var g in groups) {
            final gid = g["id"];
            if (gid != null) {
              await FirebaseMessaging.instance.subscribeToTopic("Group_$gid");
              print("Subscribed to Group_$gid");
            }
          }
        }

        return {"success": true, "user": user};
      }

      return {"success": false, "message": response.data["message"]};
    } catch (e, stack) {
      print("❌ Login Error: $e");
      print(stack);
      if (e is DioException) {
        return {
          'success': false,
          'message': e.response?.data["message"] ?? "API error",
        };
      }
      return {"success": false, "message": e.toString()};
    }
  }
}
