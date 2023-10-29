import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';

class ColorPicker extends ConsumerWidget {
  final double _colorPickerWidth;
  final double _colorPickerHeight;
  ColorPicker(this._colorPickerWidth, this._colorPickerHeight);

  Widget build(BuildContext context, WidgetRef ref) {
    final loyaltyCardsVM = ref.watch(loyaltyCardsProvider);
    final toolsVM = ref.watch(toolsProvider);
    return Container(
      height: _colorPickerHeight,
      width: _colorPickerWidth,
      child: GridView.builder(
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
          shrinkWrap: false,
          itemCount: loyaltyCardsVM.loyaltyCardsColorsToPick.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(2.0),
              child: GestureDetector(
                onTap: () {
                  toolsVM.newLoyaltyCardColor =
                      loyaltyCardsVM.loyaltyCardsColorsToPick[index];
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                      color: loyaltyCardsVM.loyaltyCardsColorsToPick[index],
                      border: Border.all(
                          color: toolsVM.newLoyaltyCardColor !=
                                  loyaltyCardsVM.loyaltyCardsColorsToPick[index]
                              ? loyaltyCardsVM.loyaltyCardsColorsToPick[index]
                              : Color.lerp(
                                  loyaltyCardsVM
                                      .loyaltyCardsColorsToPick[index],
                                  Colors.black,
                                  0.5)!,
                          width: 4),
                      borderRadius: BorderRadius.circular(5)),
                ),
              ),
            );
          }),
    );
  }
}
