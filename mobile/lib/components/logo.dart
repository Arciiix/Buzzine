import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        const Image(
          image: AssetImage('icon/icon-1024-regular.png'),
          width: 48,
          height: 48,
        ),
        Padding(
            padding: EdgeInsets.all(5),
            child: Text("Buzzine",
                style: TextStyle(fontSize: 48, color: Colors.white)))
      ],
    );
  }
}
