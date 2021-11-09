import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';

class Tools extends ChangeNotifier {
  Color getImportanceColor(Importance importance) {
    switch (importance) {
      case Importance.important:
        return Colors.orange[200];
      case Importance.urgent:
        return Colors.red[300];
      default:
        return Colors.green[200];
    }
  }
}
