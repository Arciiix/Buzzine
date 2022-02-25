import 'package:flutter/material.dart';

class SelectNumberSlider extends StatefulWidget {
  final int min;
  final int max;
  final int init;
  final int? divisions;
  final Function? onSelect;
  const SelectNumberSlider(
      {Key? key,
      required this.min,
      required this.max,
      required this.init,
      this.divisions,
      this.onSelect})
      : super(key: key);

  @override
  _SelectNumberSliderState createState() => _SelectNumberSliderState();
}

class _SelectNumberSliderState extends State<SelectNumberSlider> {
  late int val;
  @override
  void initState() {
    setState(() {
      val = widget.init;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Slider(
            min: widget.min.toDouble(),
            max: widget.max.toDouble(),
            onChanged: (double value) {
              setState(() {
                val = value.floor();
              });
              if (widget.onSelect != null) {
                widget.onSelect!(val);
              }
            },
            value: val.toDouble(),
            divisions: widget.divisions,
          ),
          Text(val.toString())
        ]);
  }
}
