import 'package:buzzine/types/Repeat.dart';
import 'package:flutter/material.dart';

Future<List<String>?> showMultipleSelect(
  BuildContext context,
  List<String> items,
  String title,
  List<String>? currentlySelectedItems,
) async {
  List<String>? result = await showDialog(
    context: context,
    builder: (context) {
      return MultipleSelectWidget(
          items: items,
          title: title,
          currentlySelectedItems: currentlySelectedItems ?? []);
    },
  );

  return result;
}

class MultipleSelectWidget extends StatefulWidget {
  final List<String> items;
  final String title;
  final List<String> currentlySelectedItems;

  const MultipleSelectWidget(
      {Key? key,
      required this.items,
      required this.title,
      required this.currentlySelectedItems})
      : super(key: key);

  @override
  _MultipleSelectWidgetState createState() => _MultipleSelectWidgetState();
}

class _MultipleSelectWidgetState extends State<MultipleSelectWidget> {
  late Map<String, bool> itemsMap;

  List<String> getSelectedItems() {
    List<String> result = [];
    itemsMap.forEach((key, value) {
      if (value) {
        result.add(key);
      }
    });
    return result;
  }

  @override
  void initState() {
    super.initState();
    itemsMap = {
      for (String item in widget.items)
        item: widget.currentlySelectedItems.contains(item)
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
            child: Container(
                width: double.infinity,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextButton(
                      child: const Text("Wybierz wszystkie"),
                      onPressed: () => setState(() {
                            itemsMap.forEach((key, value) {
                              itemsMap[key] = true;
                            });
                          })),
                  ...widget.items
                      .map((value) => CheckboxListTile(
                          title: Text(value),
                          value: itemsMap[value],
                          onChanged: (bool? isSelected) => setState(() {
                                itemsMap[value] = isSelected ?? false;
                              })))
                      .toList(),
                  TextButton(
                      child: const Text("Zatwierdź"),
                      onPressed: () =>
                          Navigator.of(context).pop(getSelectedItems())),
                ]))));
  }
}
