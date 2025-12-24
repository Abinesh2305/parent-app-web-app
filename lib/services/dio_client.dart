import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../screens/login_screen.dart';
import '../main.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      // 🔥 IMPORTANT: default to /api/ for Firebase Hosting
      baseUrl: dotenv.env['BASE_URL']?.isNotEmpty == true
          ? dotenv.env['BASE_URL']!
          : '/api/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        // ================= REQUEST =================
        onRequest: (options, handler) {
          final box = Hive.box('settings');
          final token = box.get('token');

          if (token != null && token.toString().isNotEmpty) {
            options.headers['x-api-key'] = token;
          }

          return handler.next(options);
        },

        // ================= RESPONSE =================
        onResponse: (response, handler) {
          final data = response.data;

          // ✅ SAFE: only read message if response is Map
          if (data is Map && _isInvalidTokenMessage(data['message']?.toString())) {
            _handleInvalidUser();
            return;
          }

          return handler.next(response);
        },

        // ================= ERROR =================
        onError: (DioException e, handler) {
          final data = e.response?.data;

          // ✅ SAFE: handle only Map responses
          if (data is Map &&
              _isInvalidTokenMessage(data['message']?.toString())) {
            _handleInvalidUser();
            return;
          }

          return handler.next(e);
        },
      ),
    );

  // ================= HELPERS =================

  static bool _isInvalidTokenMessage(String? msg) {
    if (msg == null) return false;

    final lower = msg.toLowerCase();
    return lower.contains('invalid user') ||
        lower.contains('invalid token') ||
        lower.contains('device changed') ||
        lower.contains('unauthorized');
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
