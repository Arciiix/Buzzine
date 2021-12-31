import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;

  const ErrorScreen({Key? key, required this.details}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(children: [
      Row(children: const [Icon(Icons.error, color: Colors.red), Text("Błąd")]),
      Text(details.toString())
    ])));
  }
}
