import 'package:dio/dio.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return "Your internet connection is slow. Please try again.";

        case DioExceptionType.badResponse:
          return "Your internet is slow. Please try again later.";

        case DioExceptionType.connectionError:
          return "Your internet is slow. Please check your connection.";

        case DioExceptionType.cancel:
          return "Your internet is slow. Please try again.";

        default:
          return "Your internet is slow. Please try again.";
      }
    }

    return "Your internet is slow. Please try again.";
  }
}
