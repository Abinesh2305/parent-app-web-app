import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dio_client.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final String schoolId = dotenv.env['SCHOOL_ID'] ?? "";
      final String fcmToken =
          await FirebaseMessaging.instance.getToken() ?? "";

      final Response response = await DioClient.dio.post(
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

      if (response.data["status"] == 1) {
        final user = response.data["data"];

        // 🔹 First install → force password change
        if (user["is_app_installed"] == 0) {
          return {
            "success": true,
            "forcePasswordChange": true,
            "userId": user["id"],
            "apiToken": user["api_token"],
          };
        }

        // 🔹 Save to Hive
        final box = Hive.box('settings');
        box.put("user", user);
        box.put("language", user["language"] ?? "en");
        box.put("token", user["api_token"]);

        // 🔹 SAFE topic values (NULL-SAFE)
        final String className = (user["userdetails"]?["is_class_name"] ?? "")
            .toString()
            .replaceAll(" ", "_");

        final String section = (user["userdetails"]?["is_section_name"] ?? "")
            .toString()
            .replaceAll(" ", "_");

        // 🔹 Firebase topic subscriptions
        await FirebaseMessaging.instance
            .subscribeToTopic("School_Scholars_$schoolId");

        await FirebaseMessaging.instance
            .subscribeToTopic("Scholar_${user["id"]}");

        if (className.isNotEmpty && section.isNotEmpty) {
          await FirebaseMessaging.instance
              .subscribeToTopic("Section_${className}_$section");
        }

        final groups = user["groups"] ?? [];
        for (final g in groups) {
          final gid = g["id"];
          if (gid != null) {
            await FirebaseMessaging.instance.subscribeToTopic("Group_$gid");
          }
        }

        return {"success": true, "user": user};
      }

      return {
        "success": false,
        "message": response.data["message"] ?? "Login failed"
      };
    } catch (e, stack) {
      print("❌ Login Error: $e");
      print(stack);

      if (e is DioException) {
        return {
          "success": false,
          "message": e.response?.data["message"] ?? "API error",
        };
      }

      return {"success": false, "message": e.toString()};
    }
  }
}
