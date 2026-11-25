/// Pemformatan tampilan saja; tidak dipakai parser atau perhitungan bisnis.
String uiNumber(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]}.',
);
String uiMoney(int value) => 'Rp${uiNumber(value)}';
String uiDecimal(int scaled) {
  final fraction = (scaled.abs() % 100)
      .toString()
      .padLeft(2, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return '${uiNumber(scaled ~/ 100)}${fraction.isEmpty ? '' : ',$fraction'}';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];
String uiDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

String uiDateTime(DateTime value) =>
    '${uiDate(value.toIso8601String())}, ${value.hour.toString().padLeft(2, '0')}.${value.minute.toString().padLeft(2, '0')}';
