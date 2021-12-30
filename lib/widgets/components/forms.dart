import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BasicForm extends ConsumerWidget {
  final TextInputType _keyboardType;
  final TextEditingController _controller;
  final String _hintText;
  final Function _onChanged;
  final IconData _prefixIcon;
  final Widget _suffixIcon;
  final bool _obsureText;
  final Function _onSubmitted;
  BasicForm(this._keyboardType, this._controller, this._hintText,
      this._onChanged, this._prefixIcon, this._obsureText,
      [this._suffixIcon, this._onSubmitted]);
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    return Container(
      width: screenSize.width * 0.6,
      height: 50,
      child: TextFormField(
          keyboardType: _keyboardType,
          autofocus: false,
          obscureText: _obsureText,
          controller: _controller,
          onChanged: (value) {
            _onChanged(context);
          },
          onFieldSubmitted: (value) {
            if (_onSubmitted != null) {
              _onSubmitted(context, value);
            }
          },
          style: Theme.of(context).primaryTextTheme.bodyText1,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
              hintText: _hintText,
              hintStyle: Theme.of(context).primaryTextTheme.bodyText2,
              prefixIcon: _prefixIcon != null
                  ? Icon(
                      _prefixIcon,
                      color: Theme.of(context).disabledColor,
                    )
                  : null,
              suffixIcon: _suffixIcon,
              focusColor: Theme.of(context).colorScheme.secondary,
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      width: 1, color: Theme.of(context).primaryColorDark)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      width: 1,
                      color: Theme.of(context).colorScheme.secondary)),
              contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10))),
    );
  }
}
