import 'dart:async';

import 'data_changes.dart';
import 'report_rules.dart';

class ReportController {
  ReportController(this.source, this.filter, {this.onChanged}) {
    _changes = DataChanges.events.listen((_) => unawaited(load()));
  }
  final ReportSource source;
  ReportFilter filter;
  final void Function()? onChanged;
  ReportSnapshot? snapshot;
  Object? error;
  bool loading = false, _disposed = false;
  int _request = 0;
  late final StreamSubscription<void> _changes;
  Future<void> load([ReportFilter? next]) async {
    if (_disposed) return;
    if (next != null) filter = next;
    final request = ++_request, captured = filter;
    loading = true;
    error = null;
    snapshot = null;
    onChanged?.call();
    try {
      final result = await source.load(captured);
      if (_disposed || request != _request) return;
      snapshot = result;
    } catch (e) {
      if (_disposed || request != _request) return;
      error = e;
    } finally {
      if (!_disposed && request == _request) {
        loading = false;
        onChanged?.call();
      }
    }
  }

  void dispose() {
    _disposed = true;
    _request++;
    unawaited(_changes.cancel());
  }
}
