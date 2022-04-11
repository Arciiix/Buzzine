import 'dart:async';

import 'package:buzzine/screens/settings.dart';
import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  final bool? showText;
  final bool? isInitLoading;
  String? currentStage;
  Function? reloadFunction;

  Loading(
      {Key? key,
      this.showText,
      this.isInitLoading,
      this.currentStage,
      this.reloadFunction})
      : super(key: key);

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  Timer? _tryAgainTimer;
  bool showTryAgainButton = false;

  void navigateToSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const Settings()));
  }

  void setTryAgainTimer() {
    setState(() {
      showTryAgainButton = false;
    });
    _tryAgainTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        showTryAgainButton = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.reloadFunction != null) {
      setTryAgainTimer();
    }
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
              )),
          if (showTryAgainButton)
            TextButton(
                onPressed: () {
                  if (showTryAgainButton) {
                    widget.reloadFunction!();
                    setTryAgainTimer();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: showTryAgainButton
                      ? [Icon(Icons.refresh), Text("Spróbuj ponownie")]
                      : [],
                )),
        ])));
  }

  @override
  void dispose() {
    _tryAgainTimer?.cancel();
    super.dispose();
  }
}
