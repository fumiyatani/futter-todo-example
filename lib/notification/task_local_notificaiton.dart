import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TaskLocalNotificationManager {
  static final String body = 'TODOの期日です。';

  final StreamController<String> selectNotificationSubject =
      StreamController<String>();
  NotificationAppLaunchDetails notificationAppLaunchDetails;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 初期化
  Future<void> initializeSettings(bool isInitializedInMainFunc) async {
    print('初期化する');
    if (isInitializedInMainFunc) {
      WidgetsFlutterBinding.ensureInitialized();
    }

    notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    var initializationSettingsAndroid =
        const AndroidInitializationSettings('mipmap/ic_launcher');

    var initializationSettingsIOS = const IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    var initializationSettings = InitializationSettings(
      initializationSettingsAndroid,
      initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (String payload) async {
        if (payload != null) {
          debugPrint('notification payload: ' + payload);
        }
        selectNotificationSubject.add(payload);
      },
    );
  }

  // iOS端末で通知機能を使用する際に通知の許諾を取得する。
  void requestIOSPermission() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // 通知をタップした際にどうするか
  void configureSelectNotificationSubject(Function(String) onListenPayload) {
    selectNotificationSubject.stream.listen((String payload) async {
      onListenPayload(payload);
    });
  }

  // Stream を閉じる
  void closeNotificationStream() {
    selectNotificationSubject.close();
  }

  Future<void> showNotification(
    String title, {
    String payload = '',
  }) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');

    var iOSPlatformChannelSpecifics = IOSNotificationDetails();

    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> scheduleNotification(
    String title,
    DateTime notifyingDateTime, {
    String payload = '',
  }) async {
    print('title : $title');
    print('notifyingDateTime : $notifyingDateTime');

    var scheduledNotificationDateTime =
        DateTime.now().add(const Duration(seconds: 5));

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('your other channel id',
            'your other channel name', 'your other channel description',
            icon: 'secondary_icon',
            sound: 'slow_spring_board',
            largeIcon: 'sample_large_icon',
            largeIconBitmapSource: BitmapSource.Drawable,
            enableLights: true,
            color: const Color.fromARGB(255, 255, 0, 0),
            ledColor: const Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500);

    IOSNotificationDetails iOSPlatformChannelSpecifics =
        IOSNotificationDetails(sound: 'slow_spring_board.aiff');

    NotificationDetails platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.schedule(
      0,
      title,
      body,
      scheduledNotificationDateTime,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
