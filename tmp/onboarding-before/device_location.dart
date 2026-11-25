import 'package:flutter/services.dart';

import 'business_location.dart';
import 'location_failure.dart';

class AndroidDeviceLocation implements DeviceLocation {
  static const _channel = MethodChannel('fishcare/location');
  @override
  Future<BusinessLocation> acquire() async {
    try {
      final p = await _channel.invokeMapMethod<String, Object?>(
        'getCurrentLocation',
      );
      if (p == null)
        throw const FormatException('Koordinat HP belum tersedia.');
      return BusinessLocation(
        'Lokasi HP',
        (p['latitude'] as num).toDouble(),
        (p['longitude'] as num).toDouble(),
        approximate: p['approximate'] == true,
        accuracy: (p['accuracy'] as num?)?.toDouble(),
      );
    } on PlatformException catch (e) {
      throw LocationFailure(
        e.message ??
            'Pengambilan lokasi gagal. Coba lagi atau pilih lokasi manual.',
      );
    } on MissingPluginException {
      throw const LocationFailure(
        'Pengambilan lokasi HP belum tersedia. Coba lagi atau pilih lokasi manual.',
      );
    }
  }

  @override
  Future<void> cancel() => _channel.invokeMethod<void>('cancel');
}
