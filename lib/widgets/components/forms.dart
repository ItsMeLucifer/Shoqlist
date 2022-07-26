import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BasicForm extends ConsumerWidget {
  final TextInputType keyboardType;
  final TextEditingController controller;
  final String hintText;
  final Function onChanged;
  final IconData prefixIcon;
  final Widget suffixIcon;
  final bool obscureText;
  final Function onSubmitted;
  final bool enableBorder;
  final bool focusedBorder;
  final double width;
  BasicForm({
    this.keyboardType,
    this.controller,
    this.hintText,
    this.onChanged,
    this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
    this.enableBorder = true,
    this.focusedBorder = true,
    this.width,
  });
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    return Container(
      width: width ?? screenSize.width * 0.6,
      height: 50,
      child: TextFormField(
          keyboardType: keyboardType,
          autofocus: false,
          obscureText: obscureText,
          controller: controller,
          onChanged: (value) {
            if (onChanged != null) {
              onChanged(context, ref);
            }
          },
          onFieldSubmitted: (value) {
            if (onSubmitted != null) {
              onSubmitted(ref, value);
            }
          },
          style: Theme.of(context).primaryTextTheme.bodyText1,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
              hintText: hintText,
              hintStyle: Theme.of(context).primaryTextTheme.bodyText2,
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: Theme.of(context).disabledColor,
                    )
                  : null,
              suffixIcon: suffixIcon,
              focusColor: Theme.of(context).colorScheme.secondary,
              enabledBorder: enableBorder
                  ? OutlineInputBorder(
                      borderSide: BorderSide(
                          width: 1, color: Theme.of(context).primaryColorDark))
                  : null,
              focusedBorder: focusedBorder
                  ? OutlineInputBorder(
                      borderSide: BorderSide(
                          width: 1,
                          color: Theme.of(context).colorScheme.secondary))
                  : null,
              contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10))),
    );
  }
}
