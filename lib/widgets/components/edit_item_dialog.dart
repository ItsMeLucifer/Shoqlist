import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/constants/app_colors.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

/// Prosty dialog edycji nazwy itemu w shopping list. Prefilled TextField +
/// Save. Anulowanie przez tap obok lub system back.
class EditItemDialog extends ConsumerStatefulWidget {
  const EditItemDialog({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  final String initialName;
  final void Function(String newName) onSave;

  @override
  ConsumerState<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends ConsumerState<EditItemDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty || trimmed == widget.initialName) {
      Navigator.of(context).pop();
      return;
    }
    widget.onSave(trimmed);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceGrayWarm,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        context.l10n.editItemTitle,
        style: Theme.of(context).primaryTextTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: context.l10n.itemNameHint,
          filled: true,
          fillColor: AppColors.inputFill,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.dividerSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              width: 1.5,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.no),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(context.l10n.yes),
        ),
      ],
    );
  }
}
