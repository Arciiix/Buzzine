import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;

  const ErrorScreen({Key? key, required this.details}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.red,
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.error, color: Colors.white, size: 48),
                Text("Błąd",
                    style: TextStyle(color: Colors.white, fontSize: 32))
              ]),
              Text(details.toString(),
                  style: const TextStyle(color: Colors.white))
            ])));
  }
}
