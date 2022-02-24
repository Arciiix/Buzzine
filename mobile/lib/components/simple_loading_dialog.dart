import 'package:flutter/material.dart';

class SimpleLoadingDialog extends StatelessWidget {
  final String? details;
  const SimpleLoadingDialog(this.details, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Czekaj..."),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          ),
          Text(
            details ?? "",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
