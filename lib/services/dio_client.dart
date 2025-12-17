import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../screens/login_screen.dart';
import '../main.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? "",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        // ✅ ADD TOKEN HERE
        onRequest: (options, handler) {
          final box = Hive.box('settings');
          final token = box.get('token'); // 🔑 CORRECT KEY

          if (token != null) {
            options.headers['x-api-key'] = token;
          }

          return handler.next(options);
        },

        onResponse: (response, handler) {
          final msg = response.data?['message']?.toString() ?? '';

          if (_isInvalidTokenMessage(msg)) {
            _handleInvalidUser();
            return;
          }
          return handler.next(response);
        },

        onError: (DioException e, handler) {
          final msg = e.response?.data?['message']?.toString() ?? '';

          if (_isInvalidTokenMessage(msg)) {
            _handleInvalidUser();
            return;
          }
          return handler.next(e);
        },
      ),
    );

  static bool _isInvalidTokenMessage(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('invalid user') ||
        lower.contains('token') ||
        lower.contains('device changed');
  }

  static Future<void> _handleInvalidUser() async {
    try {
      final box = Hive.box('settings');
      await box.clear();

      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Navigator.of(ctx).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              onToggleTheme: () {},
              onToggleLanguage: () {},
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("⚠️ Logout redirect error: $e");
    }
  }
}
