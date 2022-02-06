import 'package:buzzine/globalData.dart';
import 'package:flutter/material.dart';

class AudioWidget extends StatelessWidget {
  const AudioWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 170,
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(GlobalData.audios.length.toString(),
                    style: const TextStyle(fontSize: 52)),
                const Icon(Icons.tag),
                const Text(
                  "Ilość\naudio",
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                )
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    GlobalData.alarms
                        .where((element) => element.sound?.audioId != "default")
                        .length
                        .toString(),
                    style: const TextStyle(fontSize: 52)),
                const Icon(Icons.alarm),
                const Text(
                  "Powiązane\nalarmy",
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ],
        ));
  }
}
