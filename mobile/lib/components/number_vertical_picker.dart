import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class NumberVerticalPicker extends StatefulWidget {
  final int initValue;
  final int minValue;
  final int maxValue;
  final Function onChanged;
  final Function? validator;
  final String? propertyName;
  const NumberVerticalPicker(
      {Key? key,
      required this.onChanged,
      this.propertyName,
      required this.initValue,
      required this.minValue,
      required this.maxValue,
      this.validator})
      : super(key: key);

  @override
  _NumberVerticalPickerState createState() => _NumberVerticalPickerState();
}

class _NumberVerticalPickerState extends State<NumberVerticalPicker> {
  late int currentValue;

  Future<int?> getValueFromUserInput(int currentValue, String unit) async {
    TextEditingController _inputController = TextEditingController()
      ..text = currentValue.toString();
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(unit),
          content: TextField(
            controller: _inputController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: unit),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () async {
                  Navigator.of(context)
                      .pop(int.tryParse(_inputController.text));
                },
                child: const Text("Zmień")),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    currentValue = widget.initValue;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        int? newValue = await getValueFromUserInput(
            currentValue, widget.propertyName ?? "Wartość");
        if (newValue != null) {
          if (widget.validator != null) {
            if (!widget.validator!(newValue)) return;
          }

          widget.onChanged(newValue);
          setState(() {
            currentValue = newValue;
          });
        }
      },
      child: NumberPicker(
        value: currentValue,
        minValue: widget.minValue,
        maxValue: widget.maxValue,
        zeroPad: true,
        onChanged: (value) {
          if (widget.validator != null) {
            if (!widget.validator!(value)) return;
          }

          widget.onChanged(value);
          setState(() {
            currentValue = value;
          });
        },
      ),
    );
  }
}
