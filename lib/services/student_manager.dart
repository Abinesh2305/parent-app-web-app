import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class StudentManager {
  static final _box = Hive.box('settings');

  /// 🔁 SAFE STUDENT SWITCH (WEB FIX)
  static Future<bool> switchStudent({
    required String parentEmail,
    required String password,
    required Map<String, dynamic> student,
    required String studentUsername, // ✅ ADD THIS
  }) async {
    debugPrint("🔁 Switching to ${student['name']}");

    final ok = await AuthService().switchStudentLogin(
      parentEmail: parentEmail,
      password: password,
      studentUsername: studentUsername,
    );

    if (!ok) {
      debugPrint("❌ Student switch failed");
      return false;
    }

    debugPrint("✅ Student switched successfully");
    return true;
  }

  static Map<String, dynamic>? get currentStudent =>
      _box.get('current_student');
}
