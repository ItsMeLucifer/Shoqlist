import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/forms.dart';
import '../../main.dart';
import '../color_picker.dart';
import 'package:shoqlist/widgets/components/barcode_scanner_page.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

class YesNoDialog extends ConsumerWidget {
  final Function _onAccepted;
  final String _titleToDisplay;
  final Function? _onDeclined;
  const YesNoDialog(
    this._onAccepted,
    this._titleToDisplay, [
    this._onDeclined,
    Key? key,
  ]) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
        child: Text(_titleToDisplay,
            style: Theme.of(context).primaryTextTheme.titleLarge,
            textAlign: TextAlign.center),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_onDeclined == null) {
              return Navigator.of(context).pop();
            }
            _onDeclined(context, ref);
          },
          child: Text(_onDeclined == null
              ? context.l10n.no
              : context.l10n.decline),
        ),
        TextButton(
          onPressed: () {
            _onAccepted(context, ref);
          },
          child: Text(_onDeclined == null
              ? context.l10n.yes
              : context.l10n.accept),
        ),
      ],
    );
  }
}

class PutShoppingListData extends ConsumerWidget {
  final Function _onPressedSave;
  final Function? _onPressedDelete;
  final BuildContext context;
  final String _deleteNotificationTitle;
  const PutShoppingListData(
    this._onPressedSave,
    this.context, [
    this._deleteNotificationTitle = '',
    this._onPressedDelete,
    Key? key,
  ]) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    return SimpleDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        children: [
          const SizedBox(height: 10.0),
          SizedBox(
            height: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _onPressedDelete == null
                      ? context.l10n.newListTitle
                      : context.l10n.editListTitle,
                  style: Theme.of(context).primaryTextTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 210,
                      child: BasicForm(
                        key: toolsVM.newListNameFormFieldKey,
                        keyboardType: TextInputType.name,
                        controller: toolsVM.newListNameController,
                        hintText: context.l10n.listName,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      "${context.l10n.importance}:",
                      style: Theme.of(context).primaryTextTheme.titleLarge,
                    ),
                    DropdownButton<Importance>(
                      value: toolsVM.newListImportance,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      focusColor: Theme.of(context).disabledColor,
                      icon:
                          Icon(Icons.keyboard_arrow_down, color: Colors.black),
                      iconSize: 24,
                      elevation: 16,
                      underline: Container(
                        height: 2,
                        color: Colors.white,
                      ),
                      onChanged: (Importance? imp) {
                        if (imp == null) return;
                        toolsVM.newListImportance = imp;
                      },
                      items: <Importance>[
                        Importance.low,
                        Importance.normal,
                        Importance.important,
                        Importance.urgent
                      ].map<DropdownMenuItem<Importance>>((Importance value) {
                        return DropdownMenuItem<Importance>(
                          value: value,
                          child: Text(
                              toolsVM.getTranslatedImportanceLabel(
                                  context, value),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: toolsVM.getImportanceColor(value)),
                              textAlign: TextAlign.center),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: _onPressedDelete != null
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
                  children: [
                    _onPressedDelete != null
                        ? Card(
                            color: Theme.of(context)
                                .buttonTheme
                                .colorScheme
                                ?.surface,
                            child: TextButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return YesNoDialog(_onPressedDelete,
                                          _deleteNotificationTitle);
                                    });
                              },
                              child: Text(
                                context.l10n.remove,
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .bodyLarge,
                              ),
                            ),
                          )
                        : SizedBox(),
                    Card(
                      color:
                          Theme.of(context).buttonTheme.colorScheme!.surface,
                      child: TextButton(
                        onPressed: () {
                          _onPressedSave(context, ref);
                          Navigator.of(context).pop();
                        },
                        child: Text(context.l10n.save,
                            style:
                                Theme.of(context).primaryTextTheme.bodyLarge),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ]);
  }
}

class ChangeName extends ConsumerWidget {
  final Function _onAccepted;
  final String _titleToDisplay;

  const ChangeName(this._onAccepted, this._titleToDisplay, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    final screenSize = MediaQuery.of(context).size;
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: screenSize.height * 0.15,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _titleToDisplay,
                style: Theme.of(context).primaryTextTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              BasicForm(
                keyboardType: TextInputType.name,
                controller: toolsVM.newNicknameController,
                hintText: context.l10n.nickname,
                onChanged: (BuildContext context, WidgetRef ref) => {},
                prefixIcon: Icons.person,
              )
            ],
          ),
        ),
      ),
      actions: [
        Padding(
            padding: const EdgeInsets.only(bottom: 8.0, right: 8),
            child: BasicButton(
                _onAccepted, context.l10n.save, .2)),
      ],
    );
  }
}

class PutLoyaltyCardsData extends ConsumerWidget {
  final Function _onPressed;
  final String _title;
  final Function? _onDestroy;
  final String? _removeTitle;

  const PutLoyaltyCardsData(
    this._onPressed,
    this._title, [
    this._onDestroy,
    this._removeTitle,
    Key? key,
  ]) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    const double alertDialogWidth = 250;
    const double dividerHeight = 15;
    Widget suffixIcon = GestureDetector(
      onTap: () async {
        final scanned = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
        );
        if (scanned != null && scanned.isNotEmpty) {
          toolsVM.loyaltyCardBarCodeController.text = scanned;
        }
      },
      child:
          Icon(Icons.qr_code, color: Theme.of(context).colorScheme.secondary),
    );
    return SimpleDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: dividerHeight * 2),
                BasicForm(
                  keyboardType: TextInputType.name,
                  controller: toolsVM.loyaltyCardNameController,
                  hintText: context.l10n.cardName,
                ),
                SizedBox(height: dividerHeight),
                ColorPicker(alertDialogWidth, 100),
                SizedBox(height: dividerHeight),
                BasicForm(
                  keyboardType: TextInputType.text,
                  controller: toolsVM.loyaltyCardBarCodeController,
                  hintText: context.l10n.cardCode,
                  suffixIcon: suffixIcon,
                ),
                SizedBox(height: dividerHeight),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _onDestroy != null
                        ? Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Card(
                              color: Theme.of(context)
                                  .buttonTheme
                                  .colorScheme
                                  ?.surface,
                              child: TextButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return YesNoDialog(
                                          _onDestroy,
                                          _removeTitle!,
                                        );
                                      });
                                },
                                child: Text(
                                  context.l10n.remove,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyLarge,
                                ),
                              ),
                            ),
                          )
                        : Container(),
                    Card(
                      color:
                          Theme.of(context).buttonTheme.colorScheme?.surface,
                      child: TextButton(
                          onPressed: () {
                            _onPressed(context, ref);
                          },
                          child: Text(
                            _onDestroy != null
                                ? context.l10n.save
                                : context.l10n.add,
                            style: Theme.of(context).primaryTextTheme.bodyLarge,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]);
  }
}
