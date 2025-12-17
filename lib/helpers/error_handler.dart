import 'package:dio/dio.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return "505 Your internet connection is slow. Please try again.";

        case DioExceptionType.badResponse:
          return " 507 Your internet is slow. Please try again later.";

        case DioExceptionType.connectionError:
          return "509 Your internet is slow. Please check your connection.";

        case DioExceptionType.cancel:
          return "500 Your internet is slow. Please try again.";

        default:
          return "508 Your internet is slow. Please try again.";
      }
    }

    return "507 Your internet is slow. Please try again.";
  }
}
