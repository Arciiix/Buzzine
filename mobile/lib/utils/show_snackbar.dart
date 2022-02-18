import "package:flutter/material.dart";

void showSnackbar(
  BuildContext context,
  String content,
) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      content: Text(content,
          style:
              TextStyle(color: Theme.of(context).textTheme.bodyText1!.color)),
      action: SnackBarAction(
          label: "Rozumiem",
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar())));
}
