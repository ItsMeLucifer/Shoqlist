import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeleteNotification extends ConsumerWidget {
  Function _onPressed;
  String nameOfComponentToDelete;
  BuildContext context;
  DeleteNotification(
      this._onPressed, this.nameOfComponentToDelete, this.context);
  void _onPressDelete() {
    _onPressed(context);
  }

  Widget build(BuildContext context, ScopedReader watch) {
    return AlertDialog(
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
            child: Text("Delete " + nameOfComponentToDelete,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)),
      ),
      actions: [
        FlatButton(
          onPressed: _onPressDelete,
          child: Text('Yes'),
        ),
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('No'),
        )
      ],
    );
  }
}
