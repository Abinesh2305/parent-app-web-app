import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'dio_client.dart';

class LeaveService {
  final Dio _dio = DioClient.dio;

  Future<Map<String, dynamic>?> applyLeave({
    required String leaveReason,
    required String leaveDate,
    required String leaveType,
    String? leaveEndDate,
    String? attachmentPath,
  }) async {
    try {
      final box = Hive.box('settings');
      final user = box.get('user');
      final token = box.get('token');

      if (user == null || token == null) throw Exception("User not logged in");

      final formData = FormData.fromMap({
        'user_id': user['id'],
        'api_token': token,
        'leave_reason': leaveReason,
        'leave_date': leaveDate,
        'leave_type': leaveType,
        if (leaveEndDate != null) 'leave_end_date': leaveEndDate,
        if (attachmentPath != null)
          'leave_attachment': await MultipartFile.fromFile(attachmentPath),
      });

      final res = await _dio.post(
        'apply_leave',
        data: formData,
        options: Options(headers: {'x-api-key': token}),
      );

      return res.data;
    } catch (e) {
      print("⚠️ applyLeave error: $e");
      return null;
    }
  }

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
      print("⚠️ getAppliedLeaves error: $e");
      return null;
    }
  }

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
      print("⚠️ getUnapprovedLeaves error: $e");
      return null;
    }
  }

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
      print("⚠️ cancelLeave error: $e");
      return null;
    }
  }
}
