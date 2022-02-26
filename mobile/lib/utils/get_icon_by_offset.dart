import 'package:flutter/material.dart';

IconData getIconByOffset(double offset) {
  if (offset < 0) {
    return Icons.arrow_downward;
  } else if (offset > 0) {
    return Icons.arrow_upward;
  } else {
    return Icons.import_export;
  }
}
