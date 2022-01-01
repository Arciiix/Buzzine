import 'package:buzzine/screens/error.dart';
import 'package:buzzine/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder =
      (FlutterErrorDetails details) => ErrorScreen(details: details);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buzzine',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF00283F),
      ),
      home: ErrorScreen(
        details: FlutterErrorDetails(exception: "test"),
      ),
    );
  }
}
