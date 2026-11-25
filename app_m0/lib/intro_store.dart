import 'package:flutter/services.dart';

/// Preferensi UI saja; terpisah dari database budidaya.
abstract interface class IntroStore {
  Future<bool> completed();
  Future<void> complete();
}

class AndroidIntroStore implements IntroStore {
  const AndroidIntroStore();
  static const channel = MethodChannel('fishcare/introduction');
  @override
  Future<bool> completed() async =>
      await channel.invokeMethod<bool>('completed') ?? false;
  @override
  Future<void> complete() async {
    final saved = await channel.invokeMethod<bool>('complete');
    if (saved != true) throw StateError('Preferensi belum tersimpan.');
  }
}
