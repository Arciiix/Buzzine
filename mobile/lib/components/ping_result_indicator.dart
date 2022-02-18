import 'package:flutter/material.dart';

class PingResultIndicator extends StatefulWidget {
  final bool? isSuccess;
  final String serviceName;
  final int? delay;
  final int? apiDelay;
  const PingResultIndicator(
      {Key? key,
      this.isSuccess,
      required this.serviceName,
      this.delay,
      this.apiDelay})
      : super(key: key);

  @override
  State<PingResultIndicator> createState() => _PingResultIndicatorState();
}

class _PingResultIndicatorState extends State<PingResultIndicator> {
  Widget getWidget() {
    if (this.widget.isSuccess == null) {
      return const CircularProgressIndicator(color: Colors.white);
    } else if (this.widget.isSuccess!) {
      return const Icon(Icons.check);
    } else {
      return const Icon(Icons.close, color: Colors.red);
    }
  }

  String getDelayString() {
    if (this.widget.delay == null || this.widget.apiDelay == null) {
      return "Nieznane";
    }
    return "${(this.widget.apiDelay! + this.widget.delay!).toString()} ms (${this.widget.delay.toString()} ms)";
  }

  void displayDetailsDialog() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text("Szczegóły pingu: ${this.widget.serviceName}"),
              content: Text("Opóźnienie: ${getDelayString()}"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: this.widget.isSuccess == true ? displayDetailsDialog : null,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(height: 14, width: 14, child: getWidget()),
      ),
    );
  }
}
