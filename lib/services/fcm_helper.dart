import 'package:firebase_messaging/firebase_messaging.dart';

Future<bool> safeSubscribe(String topic) async {
  try {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    print("SUBSCRIBED → $topic");
    return true;
  } catch (e) {
    print("SUBSCRIBE ERROR → $topic → $e");
    return false;
  }
}

Future<bool> safeUnsubscribe(String topic) async {
  try {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    print("UNSUBSCRIBED → $topic");
    return true;
  } catch (e) {
    print("UNSUBSCRIBE ERROR → $topic → $e");
    return false;
  }
}
