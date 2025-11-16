import 'package:in_app_update/in_app_update.dart';

class ForceUpdateService {
  static bool _isChecking = false;

  static Future<void> checkForUpdate() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate().catchError((e) {
            _isChecking = false;
            checkForUpdate();
          });
        }
      }
    } catch (_) {}

    _isChecking = false;
  }
}
