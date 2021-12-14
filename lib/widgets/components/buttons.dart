import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoyaltyCardButton extends ConsumerWidget {
  String cardName;
  bool isFavorite;
  Color color;
  LoyaltyCardButton(this.cardName, this.isFavorite, this.color);
  Widget build(BuildContext context, ScopedReader watch) {
    return Card(
      color: color,
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: Stack(
            children: <Widget>[
              Text(cardName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 2
                        ..color = Colors.black)),
              Text(cardName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isFavorite ? Colors.yellow : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  )),
            ],
          ))),
    );
  }
}
