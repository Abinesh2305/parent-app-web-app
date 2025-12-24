import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dio_client.dart';

class LeaveService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>?> applyLeave({
    required String leaveReason,
    required String leaveDate,
    required String leaveType,
    String? leaveEndDate,

    // 🔽 NEW (optional, safe)
    String? audioPath,            // mobile
    Uint8List? audioBytes,        // web
    String? audioFileName,        // both
  }) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      if (user == null || token == null) {
        throw Exception("User not logged in");
      }

      final formData = FormData.fromMap({
        'user_id': user['id'],
        'api_token': token,
        'leave_reason': leaveReason,
        'leave_date': leaveDate,
        'leave_type': leaveType,
        if (leaveEndDate != null) 'leave_end_date': leaveEndDate,

        // ================= AUDIO =================
        if (audioBytes != null && audioFileName != null)
          'leave_attachment': MultipartFile.fromBytes(
            audioBytes,
            filename: audioFileName,
          )
        else if (audioPath != null)
          'leave_attachment': await MultipartFile.fromFile(
            audioPath,
            filename: audioPath.split('/').last,
          ),
      });

      final res = await _dio.post(
        'apply_leave',
        data: formData,
        options: Options(
          headers: {'x-api-key': token},
          contentType: 'multipart/form-data',
        ),
      );

      return res.data;
    } catch (e, s) {
      debugPrint("⚠️ applyLeave error: $e");
      debugPrintStack(stackTrace: s);
      return null;
    }
  }

  // ================= APPLIED LEAVES =================

  Future<Map<String, dynamic>?> getAppliedLeaves({int type = 1}) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      final monthYear =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

      final res = await _dio.post(
        'applied_leave',
        data: {
          'user_id': user['id'],
          'api_token': token,
          'monthyr': monthYear,
          'type': type,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } catch (e) {
      debugPrint("⚠️ getAppliedLeaves error: $e");
      return null;
    }
  }

  // ================= UNAPPROVED LEAVES =================

  Future<Map<String, dynamic>?> getUnapprovedLeaves() async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      final res = await _dio.post(
        'unapproved_leaves',
        data: {
          'user_id': user['id'],
          'api_token': token,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } catch (e) {
      debugPrint("⚠️ getUnapprovedLeaves error: $e");
      return null;
    }
  }

  // ================= CANCEL LEAVE =================

  Future<Map<String, dynamic>?> cancelLeave(int leaveId) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      final res = await _dio.post(
        'cancel_leave',
        data: {
          'user_id': user['id'],
          'api_token': token,
          'leave_id': leaveId,
        },
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } catch (e) {
      debugPrint("⚠️ cancelLeave error: $e");
      return null;
    }
  }
}
