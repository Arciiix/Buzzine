import 'package:buzzine/screens/settings.dart';
import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  final bool? showText;
  final bool? isInitLoading;
  String? currentStage;

  Loading({Key? key, this.showText, this.isInitLoading, this.currentStage})
      : super(key: key);

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  void navigateToSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const Settings()));
  }

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
          Text(widget.showText == true ? "Ładowanie..." : "",
              style: const TextStyle(color: Colors.white, fontSize: 32)),
          Text(widget.currentStage ?? "",
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          //Settings button for the first time settings, such as server ip address
          TextButton(
              onPressed: navigateToSettings,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.isInitLoading == true
                    ? [Icon(Icons.settings), Text("Ustawienia")]
                    : [],
              ))
        ])));
  }
}
