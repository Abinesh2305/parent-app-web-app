import 'package:flutter/foundation.dart';

/// Global notifier that tracks the currently active user ID.
class GlobalUserNotifier {
  static final ValueNotifier<String?> currentUserId = ValueNotifier(null);
}
