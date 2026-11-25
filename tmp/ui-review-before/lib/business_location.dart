class BusinessLocation {
  BusinessLocation(
    this.name,
    this.latitude,
    this.longitude, {
    this.approximate = false,
    this.accuracy,
  }) {
    if (name.trim().isEmpty ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        (accuracy != null && (!accuracy!.isFinite || accuracy! < 0)))
      throw const FormatException('Nama/koordinat lokasi tidak valid.');
  }
  final String name;
  final double latitude, longitude;
  final bool approximate;
  final double? accuracy;
  String get key =>
      '${(latitude == 0 ? 0.0 : latitude).toString()},${(longitude == 0 ? 0.0 : longitude).toString()}';
  Map<String, Object?> toMap() => {
    'name': name.trim(),
    'latitude': latitude,
    'longitude': longitude,
    'approximate': approximate ? 1 : 0,
    'accuracy': accuracy,
  };
  factory BusinessLocation.fromMap(Map<String, Object?> p) => BusinessLocation(
    p['name'] as String,
    (p['latitude'] as num).toDouble(),
    (p['longitude'] as num).toDouble(),
    approximate: p['approximate'] == 1,
    accuracy: (p['accuracy'] as num?)?.toDouble(),
  );
}

abstract interface class DeviceLocation {
  Future<BusinessLocation> acquire();
  Future<void> cancel();
}
