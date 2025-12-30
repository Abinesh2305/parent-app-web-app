import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../screens/login_screen.dart';
import '../main.dart';

class DioClient {
  static bool _loggingOut = false; // 🛑 prevent double logout

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL']!,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        /* ================= REQUEST ================= */
        onRequest: (options, handler) {
          try {
            final box = Hive.isBoxOpen('settings')
                ? Hive.box('settings')
                : null;

            final token = box?.get('token');

            if (token != null && token.toString().isNotEmpty) {
              options.headers['x-api-key'] = token;
            }

            debugPrint("➡️ ${options.method} ${options.uri}");
          } catch (_) {
            // silently ignore
          }

          handler.next(options);
        },

        /* ================= RESPONSE ================= */
        onResponse: (response, handler) {
          final data = response.data;

          if (data is Map<String, dynamic> &&
              _isInvalidTokenMessage(data['message']?.toString())) {
            _forceLogoutOnce();
          }

          // ✅ NEVER reject a valid response
          handler.next(response);
        },

        /* ================= ERROR ================= */
        onError: (DioException e, handler) {
          final data = e.response?.data;

          if (data is Map<String, dynamic> &&
              _isInvalidTokenMessage(data['message']?.toString())) {
            _forceLogoutOnce();
          }

          // ✅ pass error to caller (services already catch it)
          handler.next(e);
        },
      ),
    );

  /* ================= HELPERS ================= */

  static bool _isInvalidTokenMessage(String? msg) {
    if (msg == null) return false;

    final m = msg.toLowerCase();
    return m.contains('invalid') ||
        m.contains('unauthorized') ||
        m.contains('token expired') ||
        m.contains('device changed') ||
        m.contains('session expired');
  }

  static Future<void> _forceLogoutOnce() async {
    if (_loggingOut) return;
    _loggingOut = true;

    try {
      if (Hive.isBoxOpen('settings')) {
        await Hive.box('settings').clear();
      }

      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              onToggleTheme: () {},
              onToggleLanguage: () {},
            ),
          ),
          (_) => false,
        );
      }
    } catch (e) {
      debugPrint("⚠️ Force logout failed: $e");
    } finally {
      _loggingOut = false;
    }
  }
}
