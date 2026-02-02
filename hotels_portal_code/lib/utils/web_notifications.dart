// web_notifications.dart
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show debugPrint;

void showWebNotification(String title, String body) async {
  if (html.Notification.supported) {
    if (html.Notification.permission == 'granted') {
      html.Notification(title, body: body);
    } else if (html.Notification.permission != 'denied') {
      final permission = await html.Notification.requestPermission();
      if (permission == 'granted') {
        html.Notification(title, body: body);
      } else {
        debugPrint('Web notification permission denied');
      }
    }
  } else {
    debugPrint('Web notifications not supported');
  }
}
