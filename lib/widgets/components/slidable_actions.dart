import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';

/// Helpery budujące spójne ActionPane dla edit (start, niebieski) i delete
/// (end, czerwony). Pattern: pełny swipe przez próg → akcja wywoływana od razu.
/// Lekki swipe → tile snapuje z powrotem do pozycji 0 (action button nigdy nie
/// "wisi" otwarty — `openThreshold: 1.0`).
///
/// Edit (non-destructive) używa `confirmDismiss` zwracającego `false` — akcja
/// odpalona, ale widget pozostaje w drzewie (tile zjeżdża z powrotem
/// animacyjnie). Delete (destructive) zwraca `true` — widget animuje dismiss,
/// a dane są już usunięte z VM więc ListView rebuilduje bez tego tile.
class SlidableActions {
  SlidableActions._();

  /// Start pane (swipe right) → edit. Nie usuwa tile z drzewa.
  /// [dismissThreshold] — 0.3 dla częstych akcji (shopping list items),
  /// 0.5 dla rzadkich (lista list).
  static ActionPane editPane({
    required VoidCallback onEdit,
    double dismissThreshold = 0.5,
    double extentRatio = 0.25,
  }) {
    return ActionPane(
      motion: const BehindMotion(),
      extentRatio: extentRatio,
      openThreshold: 0.99,
      dismissible: DismissiblePane(
        onDismissed: () {},
        confirmDismiss: () async {
          onEdit();
          return false;
        },
        dismissThreshold: dismissThreshold,
        closeOnCancel: true,
      ),
      children: [
        SlidableAction(
          onPressed: (_) => onEdit(),
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          icon: Icons.edit,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  /// End pane (swipe left) → delete. Dane usuwane w [onDelete]; widget
  /// znika razem z ListView rebuildem.
  /// [confirm] opcjonalny dialog potwierdzenia — gdy zwróci `false`, swipe
  /// jest cofany.
  static ActionPane deletePane({
    required VoidCallback onDelete,
    Future<bool> Function()? confirm,
    double dismissThreshold = 0.5,
    double extentRatio = 0.25,
    IconData icon = Icons.delete,
    String? label,
  }) {
    return ActionPane(
      motion: const BehindMotion(),
      extentRatio: extentRatio,
      openThreshold: 0.99,
      dismissible: DismissiblePane(
        onDismissed: () {},
        confirmDismiss: () async {
          if (confirm != null) {
            final ok = await confirm();
            if (!ok) return false;
          }
          onDelete();
          return true;
        },
        dismissThreshold: dismissThreshold,
        closeOnCancel: true,
      ),
      children: [
        SlidableAction(
          onPressed: (_) async {
            if (confirm != null) {
              final ok = await confirm();
              if (!ok) return;
            }
            onDelete();
          },
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          icon: icon,
          label: label,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  /// Wyświetla YesNoDialog i zwraca `true` gdy user zaakceptował.
  static Future<bool> confirmDialog(
      BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => YesNoDialog(
        (dialogCtx, _) => Navigator.of(dialogCtx).pop(true),
        message,
        (dialogCtx, _) => Navigator.of(dialogCtx).pop(false),
      ),
    );
    return result ?? false;
  }
}
