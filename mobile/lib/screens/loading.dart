import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  final bool? showText;

  const Loading({Key? key, this.showText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 10),
          Text(showText == true ? "Ładowanie..." : "",
              style: const TextStyle(color: Colors.white, fontSize: 32))
        ])));
  }
}
