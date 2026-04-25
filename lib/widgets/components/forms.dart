import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/constants/app_colors.dart';

class BasicForm extends ConsumerWidget {
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? hintText;
  final void Function(BuildContext, WidgetRef)? onChanged;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final void Function(WidgetRef, String)? onSubmitted;
  final bool enableBorder;
  final bool focusedBorder;
  final double? width;
  final InputDecoration? decoration;
  final TextStyle? style;
  final FocusNode? focusNode;

  const BasicForm({
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
    this.decoration,
    this.style,
    this.focusNode,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    return SizedBox(
      width: width ?? screenSize.width * 0.6,
      height: 50,
      child: TextFormField(
        keyboardType: keyboardType,
        autofocus: false,
        obscureText: obscureText,
        controller: controller,
        onChanged: (value) => onChanged?.call(context, ref),
        onFieldSubmitted: (value) => onSubmitted?.call(ref, value),
        style: style ?? Theme.of(context).primaryTextTheme.bodyLarge,
        textAlignVertical: TextAlignVertical.center,
        focusNode: focusNode,
        decoration: decoration ??
            InputDecoration(
              hintText: hintText,
              hintStyle: Theme.of(context).primaryTextTheme.bodyMedium,
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: Theme.of(context).disabledColor,
                    )
                  : null,
              suffixIcon: suffixIcon,
              focusColor: Theme.of(context).colorScheme.secondary,
              filled: true,
              fillColor: AppColors.inputFill,
              enabledBorder: enableBorder
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          width: 1, color: AppColors.dividerSoft))
                  : null,
              focusedBorder: focusedBorder
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          width: 1.5,
                          color: Theme.of(context).colorScheme.secondary))
                  : null,
              contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
            ),
      ),
    );
  }
}
