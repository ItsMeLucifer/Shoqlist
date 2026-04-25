import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/constants/app_colors.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/forms.dart';
import '../../main.dart';
import '../color_picker.dart';
import 'package:shoqlist/widgets/components/barcode_scanner_page.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

/// Spójny shape + flat tło dla wszystkich dialogów aplikacji. Material default
/// daje subtle elevation shadow który "wypycha" dialog z tła — niespójne
/// z flat designem. Plus 16px corners zamiast Material default 4px.
RoundedRectangleBorder get _dialogShape =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

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
      backgroundColor: AppColors.surfaceGrayWarm,
      elevation: 0,
      shape: _dialogShape,
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
    // Domyślnie SimpleDialog używa `insetPadding: EdgeInsets.symmetric(h:40,v:24)`
    // → karta zajmuje ~85% szerokości. Zwężamy do 80% przez explicit insetPadding,
    // a wewnątrz wszystkie kontrolki rozciągamy do 100% (text field, save button).
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogHorizontalInset = screenWidth * 0.10; // 10% z każdej strony = 80%
    return SimpleDialog(
        backgroundColor: AppColors.surfaceGrayWarm,
        elevation: 0,
        shape: _dialogShape,
        insetPadding: EdgeInsets.symmetric(
          horizontal: dialogHorizontalInset,
          vertical: 24,
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        children: [
          Text(
            _onPressedDelete == null
                ? context.l10n.newListTitle
                : context.l10n.editListTitle,
            style: Theme.of(context).primaryTextTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Pole listName 100% szerokości — BasicForm respektuje `width`,
          // więc null pozwala mu rozciągnąć się do parent'a (LayoutBuilder
          // / SizedBox.expand). Wrap'ujemy w SizedBox.expand-like pattern.
          BasicForm(
            key: toolsVM.newListNameFormFieldKey,
            keyboardType: TextInputType.name,
            controller: toolsVM.newListNameController,
            hintText: context.l10n.listName,
            width: double.infinity,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${context.l10n.importance}:",
                style: Theme.of(context).primaryTextTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              DropdownButton<Importance>(
                value: toolsVM.newListImportance,
                dropdownColor: AppColors.surfaceGrayWarm,
                focusColor: Theme.of(context).disabledColor,
                icon: Icon(Icons.keyboard_arrow_down,
                    color: toolsVM.getImportanceColor(toolsVM.newListImportance)),
                iconSize: 24,
                elevation: 0,
                // Underline:0 zamiast białego container'a — czysto, flat.
                underline: const SizedBox.shrink(),
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
                        toolsVM.getTranslatedImportanceLabel(context, value),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: toolsVM.getImportanceColor(value)),
                        textAlign: TextAlign.center),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_onPressedDelete != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surfaceGray,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (_) => YesNoDialog(
                            _onPressedDelete, _deleteNotificationTitle));
                  },
                  child: Text(
                    context.l10n.remove,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.dangerSoft),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.surfaceGray,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                _onPressedSave(context, ref);
                Navigator.of(context).pop();
              },
              child: Text(
                context.l10n.save,
                style: Theme.of(context).primaryTextTheme.bodyLarge,
              ),
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
      backgroundColor: AppColors.surfaceGrayWarm,
      elevation: 0,
      shape: _dialogShape,
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
        backgroundColor: AppColors.surfaceGrayWarm,
        elevation: 0,
        shape: _dialogShape,
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
                              elevation: 0,
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
                      elevation: 0,
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
