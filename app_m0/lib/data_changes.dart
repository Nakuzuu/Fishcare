import 'dart:async';

/// Sinyal setelah commit; bukan pengganti hasil persisten ActionJournal.
class DataChanges {
  static final _events = StreamController<void>.broadcast();
  static Stream<void> get events => _events.stream;
  static void committed() => _events.add(null);
}
