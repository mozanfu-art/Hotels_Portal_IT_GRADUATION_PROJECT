import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'web_notifications.dart';

Future<void> showNotification(
  String title,
  String body,
  FlutterLocalNotificationsPlugin notifications,
) async {
  if (kIsWeb) {
    showWebNotification(title, body);
    return;
  }

  if (Platform.isAndroid) {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
    );
  }

  // Windows notifications not supported by flutter_local_notifications
  // TODO: Implement alternative notification method for Windows if needed
}
