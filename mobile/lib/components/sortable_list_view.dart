import 'package:flutter/material.dart';

class SortableListView extends StatefulWidget {
  final List<String> items;
  final String title;
  const SortableListView({Key? key, required this.items, required this.title})
      : super(key: key);

  @override
  State<SortableListView> createState() => _SortableListViewState();
}

class _SortableListViewState extends State<SortableListView> {
  late List<String> items;
  late List<bool> isItemSelected;

  @override
  void initState() {
    super.initState();
    items = widget.items;
    isItemSelected = List.filled(widget.items.length, true, growable: true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      actions: [
        TextButton(
          child: Text("Anuluj"),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
        TextButton(
          child: Text("Wybierz"),
          onPressed: () {
            Navigator.of(context).pop(items
                .where((element) => isItemSelected[items.indexOf(element)])
                .toList());
          },
        ),
      ],
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        width: MediaQuery.of(context).size.width * 0.9,
        child: ReorderableListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ListTile(
                key: ValueKey(index),
                title: Text(items[index]),
                trailing: Icon(Icons.drag_handle),
                leading: Checkbox(
                  value: isItemSelected[index],
                  onChanged: (value) {
                    setState(() {
                      isItemSelected[index] = value ?? true;
                    });
                  },
                ));
          },
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final String item = items.removeAt(oldIndex);
              items.insert(newIndex, item);

              final bool isItemSelected =
                  this.isItemSelected.removeAt(oldIndex);
              this.isItemSelected.insert(newIndex, isItemSelected);
            });
          },
        ),
      ),
    );
  }
}
