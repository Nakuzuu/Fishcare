import 'package:flutter/material.dart';

import 'cycle_rules.dart';
import 'design_system.dart';
import 'feed_repository.dart';
import 'feed_ui.dart' show RecoveryPage;
import 'feeding_day.dart';
import 'feeding_input.dart';
import 'feeding_policy.dart';
import 'master_data.dart';
import 'ui_format.dart';

class FeedCostPreview extends StatelessWidget {
  const FeedCostPreview({
    super.key,
    required this.price,
    required this.rawGrams,
    this.showPrice = true,
  });
  final int price;
  final bool showPrice;
  final String rawGrams;
  @override
  Widget build(BuildContext context) {
    String total;
    try {
      total = uiMoney(feedingCost(parseGrams(rawGrams), price));
    } on ValidationFailure {
      total = 'Isi jumlah aktual yang valid';
    }
    return Column(
      children: [
        if (showPrice) ValueRow('Harga pakan', '${uiMoney(price)}/kg'),
        ValueRow(
          'Total biaya pemberian',
          total,
          valueKey: const ValueKey('feeding-cost-preview'),
        ),
      ],
    );
  }
}

class WaterFeedingForm extends StatefulWidget {
  const WaterFeedingForm({
    super.key,
    required this.repo,
    required this.cycle,
    required this.date,
    required this.minute,
  });
  final FeedRepository repo;
  final String cycle, date;
  final int minute;
  @override
  State<WaterFeedingForm> createState() => _WaterFeedingFormState();
}

class _WaterFeedingFormState extends State<WaterFeedingForm> {
  final _form = GlobalKey<FormState>();
  final _temperature = TextEditingController(),
      _ph = TextEditingController(),
      _amount = TextEditingController();
  late Future<Map<String, Object?>> _load;
  int? _recordedAt;
  bool _busy = false, _unknown = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load = _read();
  }

  Future<Map<String, Object?>> _read() =>
      widget.repo.contextFor(widget.cycle, widget.date, widget.minute);
  @override
  void dispose() {
    _temperature.dispose();
    _ph.dispose();
    _amount.dispose();
    super.dispose();
  }

  FeedingWaterReading? _reading() {
    if (_recordedAt == null) return null;
    try {
      return FeedingWaterReading(
        temperatureDeciC: parseWaterNumber(_temperature.text, ph: false),
        phHundredths: parseWaterNumber(_ph.text, ph: true),
        recordedAtMs: _recordedAt!,
      );
    } on ValidationFailure {
      return null;
    }
  }

  void _waterChanged(String _) => setState(
    () => _recordedAt = widget.repo.cycles.clock().millisecondsSinceEpoch,
  );
  String? _validateWater(String? text, bool ph) {
    try {
      parseWaterNumber(text ?? '', ph: ph);
      return null;
    } on ValidationFailure catch (e) {
      return e.message;
    }
  }

  SlotRecommendation? _recommend(Map<String, Object?> data) {
    final day = data['day'] as FeedingDayPlan?;
    return day == null || day.states[widget.minute] != FeedingSlotState.pending
        ? null
        : day.recommend(widget.minute, _reading());
  }

  Future<void> _save(Map<String, Object?> opened) async {
    if (_busy || _unknown || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? id;
    try {
      final latest = await _read();
      if (latest['expected_context'] != opened['expected_context']) {
        setState(() => _load = Future.value(latest));
        throw const ValidationFailure(
          'Rincian ikan, harga atau jadwal berubah. Periksa rekomendasi dan biaya baru lalu tinjau lagi.',
        );
      }
      final reading = _reading();
      if (reading == null)
        throw const ValidationFailure(
          'Suhu air dan pH wajib diisi untuk pemberian ini.',
        );
      final grams = parseGrams(_amount.text);
      final day = latest['day'] as FeedingDayPlan?;
      final recommendation = _recommend(latest);
      final extra = day != null
          ? day
                .reviewActual(
                  minute: widget.minute,
                  grams: grams,
                  reading: reading,
                )
                .requiresExtraConfirmation
          : grams > (latest['remaining'] as int);
      final payload = <String, Object?>{
        'cycle': widget.cycle,
        'date': widget.date,
        'minute': widget.minute,
        'grams': grams,
        'price': latest['price'],
        'rate': latest['rate'],
        'policy_version': latest['policy_version'],
        'expected_context': latest['expected_context'],
        'allow_excess': extra,
        ...reading.toSnapshot(),
      };
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      final yes = await reviewAction(
        context,
        title: 'Konfirmasi pemberian',
        backLabel: 'Kembali mengubah',
        summary:
            '${latest['feed_name']} · ${widget.date} ${timeText(widget.minute)}\n'
            'Suhu air ${_temperature.text} °C · pH ${_ph.text}\n'
            '${recommendation == null
                ? 'Aturan manual lama'
                : recommendation.recommendedGrams == null
                ? 'Peringatan: rekomendasi otomatis tidak tersedia'
                : 'Rekomendasi ${recommendation.recommendedGrams} g'}\n'
            'Aktual $grams g\nHarga ${uiMoney(latest['price'] as int)}/kg\n'
            'Total biaya ${uiMoney(feedingCost(grams, latest['price'] as int))}\n'
            '${extra ? 'PERHATIAN: aktual melebihi rekomendasi, porsi normal atau kebutuhan harian. Konfirmasikan jumlah ini hanya jika sesuai pemberian nyata.' : ''}',
      );
      if (yes != true || !mounted) return;
      id = newMasterId();
      await widget.repo.run(id, 'feeding', payload);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pemberian tersimpan.')));
        Navigator.pop(context);
      }
    } catch (e) {
      var unknown = e is! ValidationFailure;
      if (id != null) {
        try {
          final state = (await widget.repo.journal.inspect(id))['state'];
          unknown = state == 'prepared' || state == 'committed';
        } catch (_) {
          unknown = true;
        }
      }
      if (mounted)
        setState(() {
          _unknown = unknown;
          _error = unknown
              ? 'Hasil belum pasti. Periksa Pemulihan tindakan sebelum retry.'
              : e is ValidationFailure
              ? e.message
              : 'Pemberian belum tersimpan.';
          if (!unknown) _load = _read();
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FishAppBar(title: Text('Pemberian ${timeText(widget.minute)}')),
    body: SafeArea(
      child: FutureBuilder<Map<String, Object?>>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Notice(
                    snapshot.error is ValidationFailure
                        ? (snapshot.error as ValidationFailure).message
                        : 'Rincian pakan gagal dimuat. Kembali atau coba lagi.',
                    warning: true,
                  ),
                  TextButton(
                    onPressed: () => setState(() => _load = _read()),
                    child: const Text('Rincian gagal dimuat — coba lagi'),
                  ),
                ],
              ),
            );
          final data = snapshot.data!;
          final auto = data['automatic'] == true;
          final recommendation = _recommend(data);
          final reading = _reading();
          final conditions = reading == null ? null : waterConditions(reading);
          final unavailable = auto && data['day'] == null;
          return Form(
            key: _form,
            child: FormList(
              controllers: [_temperature, _ph, _amount],
              busy: _busy,
              children: [
                FishCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('${data['feed_name']}'),
                      ValueRow(
                        'Tanggal dan jam',
                        '${uiDate(widget.date)} · ${timeText(widget.minute)}',
                      ),
                      ValueRow(
                        'Stok bersama saat dimuat',
                        '${data['stock']} g',
                      ),
                      ValueRow(
                        auto ? 'Porsi normal slot' : 'Porsi rencana lama',
                        data['plan'] == null
                            ? 'Belum bisa dihitung'
                            : '${data['plan']} g',
                      ),
                      ValueRow(
                        'Harga pakan',
                        '${uiMoney(data['price'] as int)}/kg',
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Ukur air kolam sebelum setiap pemberian. Suhu cuaca bukan suhu air.',
                ),
                TextFormField(
                  key: const ValueKey('water-temperature'),
                  controller: _temperature,
                  enabled: !_busy && !_unknown,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Suhu air kolam',
                    suffixText: '°C',
                    helperText: 'Contoh 27,5; maksimal satu desimal',
                  ),
                  onChanged: _waterChanged,
                  validator: (s) => _validateWater(s, false),
                ),
                TextFormField(
                  key: const ValueKey('water-ph'),
                  controller: _ph,
                  enabled: !_busy && !_unknown,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'pH air kolam',
                    helperText: 'Contoh 7,25; maksimal dua desimal',
                  ),
                  onChanged: _waterChanged,
                  validator: (s) => _validateWater(s, true),
                ),
                if (conditions != null && auto) ...[
                  Text(
                    'Suhu: ${switch (conditions.temperature) {
                      TemperatureCondition.normal => 'Dalam rentang 25–30 °C',
                      TemperatureCondition.cold => 'Di bawah 24 °C — porsi 80% bila pH sesuai',
                      TemperatureCondition.noRule => '24–<25 °C — aturan rekomendasi belum tersedia',
                      TemperatureCondition.high => 'Di atas 30 °C — di luar acuan',
                    }}',
                  ),
                  Text(
                    'pH: ${conditions.ph == PhCondition.normal ? 'Dalam rentang 6,5–8' : 'Di luar rentang 6,5–8'}',
                  ),
                ],
                if (data['state'] != 'pending')
                  const Notice(
                    'Slot ini tidak lagi menunggu. Kembali dan muat ulang.',
                    warning: true,
                  )
                else if (unavailable)
                  const Notice(
                    'Bobot/rate belum memiliki acuan yang lengkap. Rekomendasi belum tersedia, bukan nol.',
                    warning: true,
                  )
                else if (auto) ...[
                  Notice(
                    recommendation?.reason ??
                        'Rekomendasi pemberian: ${recommendation?.recommendedGrams} g',
                    warning:
                        recommendation?.status !=
                        SlotRecommendationStatus.recommended,
                  ),
                  if (recommendation?.permitsActualEntry == true &&
                      recommendation?.recommendedGrams != null)
                    OutlinedButton(
                      onPressed: _busy || _unknown
                          ? null
                          : () => setState(
                              () => _amount.text =
                                  '${recommendation!.recommendedGrams}',
                            ),
                      child: const Text('Gunakan jumlah rekomendasi'),
                    ),
                ] else
                  const Notice(
                    'Siklus ini memakai rate manual lama. Penyesuaian otomatis suhu hanya untuk siklus lele dengan aturan baru.',
                  ),
                TextFormField(
                  key: const ValueKey('actual-feed'),
                  controller: _amount,
                  enabled: !_busy && !_unknown,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah pakan aktual',
                    suffixText: 'g',
                    helperText: 'Gram bulat tanpa pemisah ribuan, contoh 1125',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (s) {
                    try {
                      parseGrams(s ?? '');
                      return null;
                    } on ValidationFailure catch (e) {
                      return e.message;
                    }
                  },
                ),
                FeedCostPreview(
                  price: data['price'] as int,
                  rawGrams: _amount.text,
                  showPrice: false,
                ),
                if (_error != null) Notice(_error!, warning: true),
                if (_busy) const LinearProgressIndicator(),
                FilledButton(
                  onPressed:
                      _busy ||
                          _unknown ||
                          unavailable ||
                          data['state'] != 'pending'
                      ? null
                      : () => _save(data),
                  child: const Text('Tinjau dan simpan'),
                ),
                if (_unknown)
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => RecoveryPage(repo: widget.repo),
                      ),
                    ),
                    child: const Text('Pemulihan tindakan'),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
