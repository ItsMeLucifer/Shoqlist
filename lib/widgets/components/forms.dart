import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthenticationPageForm extends ConsumerWidget {
  final TextInputType _keyboardType;
  final TextEditingController _controller;
  final String _hintText;
  final Function _onChanged;
  final IconData _prefixIcon;
  final Widget _suffixIcon;
  final bool _obsureText;
  AuthenticationPageForm(this._keyboardType, this._controller, this._hintText,
      this._onChanged, this._prefixIcon, this._obsureText,
      [this._suffixIcon]);
  Widget build(BuildContext context, ScopedReader watch) {
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
          style: Theme.of(context).primaryTextTheme.bodyText1,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
              hintText: _hintText,
              hintStyle: Theme.of(context).primaryTextTheme.bodyText2,
              prefixIcon: Icon(
                _prefixIcon,
                color: Theme.of(context).disabledColor,
              ),
              suffixIcon: _suffixIcon,
              focusColor: Theme.of(context).accentColor,
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      width: 1, color: Theme.of(context).primaryColorDark)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      width: 1, color: Theme.of(context).accentColor)),
              contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10))),
    );
  }
}
