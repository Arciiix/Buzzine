import "package:flutter/material.dart";

void showSnackbar(
  BuildContext context,
  String content,
) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(content),
      action: SnackBarAction(
          label: "Rozumiem",
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar())));
}
