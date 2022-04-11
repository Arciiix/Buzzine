import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/error.dart';
import 'package:buzzine/screens/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
      'resource://drawable/res_app_icon',
      [
        NotificationChannel(
            channelGroupKey: 'alarms',
            channelKey: 'alarms',
            channelName: 'Alarmy',
            channelDescription: 'Notification channel for receiving alarms',
            defaultColor: Color(0xFF0078f2),
            ledColor: Color(0xFF0078f2))
      ],
      debug: true);

  FirebaseApp firebaseApp = await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  ErrorWidget.builder =
      (FlutterErrorDetails details) => ErrorScreen(details: details);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLightModeEnabled = false;

  @override
  void initState() {
    super.initState();
    GlobalData.loadSettings().then((_) {
      setState(() {
        isLightModeEnabled = GlobalData.isLightModeEnabled;
      });
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buzzine',
      theme: isLightModeEnabled ? ThemeData.light() : ThemeData.dark(),
      home: HomePage(),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print("New background message: ${message.messageId}");

  AwesomeNotifications().createNotificationFromJsonData(message.data);
}
