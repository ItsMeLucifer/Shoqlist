import 'dart:async';

/// Tracks inflight Firestore mutations so that pull-to-refresh awaits them
/// before reading, and so the snapshot-merge layer can skip items with a
/// locally-pending write (avoiding flicker/data-loss when a stale snapshot
/// races an optimistic update).
///
/// Dwa widoki na ten sam stan:
///  - `_inflight[listId]` — Future'y w locie per lista; `flushAll` / `flushList`
///    czeka aż się rozliczą. To jest tarcza dla ręcznego refresh'u.
///  - `_touchedItems` — itemy niedawno mutowane lokalnie. Clear tylko explicit
///    (w `flushAll` / `flushList`). Snapshot-merge używa `hasPendingFor` żeby
///    NIE nadpisać świeżego optymistycznego stanu echem z serwera.
class PendingWritesTracker {
  final Map<String, List<Future<void>>> _inflight = {};
  final Set<String> _touchedItems = {};

  Future<T> track<T>({
    required String listId,
    String? itemId,
    required Future<T> Function() op,
  }) {
    final itemKey = itemId == null ? null : '$listId:$itemId';
    if (itemKey != null) _touchedItems.add(itemKey);
    final completer = Completer<void>();
    final bucket = _inflight.putIfAbsent(listId, () => <Future<void>>[]);
    bucket.add(completer.future);

    Future<T> run() async {
      try {
        return await op();
      } finally {
        completer.complete();
        bucket.remove(completer.future);
        if (bucket.isEmpty) _inflight.remove(listId);
        // Clear touched item entry po commit/error. Shield był potrzebny
        // tylko dopóki nasz write był "in flight" albo serwer jeszcze nie
        // dał echo. Po commit kolejny snapshot z właściwą wartością
        // (stateUpdatedAt ≥ lokalny) bezpiecznie wygrywa per-field merge.
        if (itemKey != null) _touchedItems.remove(itemKey);
      }
    }

    return run();
  }

  bool hasPendingFor(String listId, String itemId) =>
      _touchedItems.contains('$listId:$itemId');

  Future<void> flushAll() async {
    while (_inflight.isNotEmpty) {
      final snapshot = _inflight.values.expand((f) => f).toList(growable: false);
      if (snapshot.isEmpty) break;
      await Future.wait(snapshot, eagerError: false).catchError((_) => <void>[]);
    }
    _touchedItems.clear();
  }

  Future<void> flushList(String listId) async {
    while (_inflight[listId] != null && _inflight[listId]!.isNotEmpty) {
      final snapshot = List<Future<void>>.from(_inflight[listId]!);
      await Future.wait(snapshot, eagerError: false).catchError((_) => <void>[]);
    }
    _touchedItems.removeWhere((k) => k.startsWith('$listId:'));
  }

  /// Wipe for sign-out / tests.
  void reset() {
    _inflight.clear();
    _touchedItems.clear();
  }
}
