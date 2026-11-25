import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'report_rules.dart';
import 'master_data.dart';

// A small, stored ZIP writer: only the XML parts needed by SpreadsheetML.
// Text is always inline text, never a formula; large integers remain exact text.
Uint8List reportXlsx(ReportSnapshot snapshot) {
  final rows = snapshot.rows.where(snapshot.filter.includes).toList();
  if (rows.length >= 1048576) {
    throw const ValidationFailure(
      'Terlalu banyak baris; pilih periode yang lebih pendek.',
    );
  }
  final totals = reportTotals(rows);
  final pond = snapshot.filter.pondId == null
      ? 'Semua kolam (termasuk arsip)'
      : snapshot.ponds
                .where((p) => p['id'] == snapshot.filter.pondId)
                .map((p) => '${p['name']}')
                .firstOrNull ??
            snapshot.filter.pondId!;
  Object scaled(Map<String, Object?> r, String key, int divisor) =>
      r[key] == null ? 'Tidak tercatat' : (r[key] as int) / divisor;
  final sheets = <String, List<List<Object?>>>{
    'Ringkasan': [
      ['FishCare — laporan periode'],
      ['Mulai (inklusif)', snapshot.filter.start],
      ['Akhir (inklusif)', snapshot.filter.end],
      ['Kolam', pond],
      ['Transaksi batal dikecualikan dari total.'],
      ['Metrik', 'Jumlah', 'Satuan'],
      for (final m in reportMetrics.entries)
        [m.value, totals[m.key], metricUnit(m.key)],
      if (rows.isEmpty) ['Belum ada transaksi pada filter ini.'],
      ['Kondisi saat ini dan seluruh siklus tidak termasuk total periode ini.'],
    ],
    'Transaksi': [
      [
        'ID',
        'Tanggal',
        'Kolam',
        'Siklus',
        'Kegiatan',
        'Status',
        'Jumlah',
        'Satuan',
        'Harga pakan Rp per kg',
        'Biaya pakan Rp',
        'Suhu air C',
        'pH',
        'Porsi normal g',
        'Rekomendasi g',
        'Status rekomendasi',
        'Alasan',
        'Bobot grading g per ikan',
        'Nomor grading',
        'Nilai panen Rp',
        'Alasan batal',
        'Rate persen',
        'Waktu ukur (UTC)',
        'Aturan pakan',
      ],
      for (final r in rows)
        [
          r['id'],
          r['business_date'],
          r['pond_name'],
          r['cycle_id'],
          switch (r['kind']) {
            'sampling' => 'Grading',
            'feeding' => 'Pemberian pakan',
            'death' => 'Kematian',
            'partial' => 'Panen sebagian',
            'final' => 'Panen akhir',
            _ => r['kind'],
          },
          r['cancel_action_id'] == null ? 'Sah' : 'Batal',
          r['quantity'],
          r['kind'] == 'feeding'
              ? 'g'
              : r['kind'] == 'sampling'
              ? ''
              : 'ekor',
          r['price_snapshot'],
          r['cost_snapshot'],
          if (r['kind'] == 'feeding')
            scaled(r, 'water_temperature_deci_c', 10)
          else
            null,
          if (r['kind'] == 'feeding')
            scaled(r, 'water_ph_hundredths', 100)
          else
            null,
          r['planned_snapshot_g'],
          r['recommended_g'] ??
              (r['kind'] == 'feeding'
                  ? 'Tidak tersedia / tidak tercatat'
                  : null),
          r['recommendation_status'],
          r['recommendation_reason'],
          if (r['kind'] == 'sampling')
            scaled(r, 'after_weight_cg', 100)
          else
            null,
          r['grading_number'],
          r['value_rp'],
          r['cancel_reason'],
          if (r['kind'] == 'feeding') scaled(r, 'rate_snapshot', 100) else null,
          r['water_recorded_at_ms'] == null
              ? (r['kind'] == 'feeding' ? 'Tidak tercatat' : null)
              : DateTime.fromMillisecondsSinceEpoch(
                  r['water_recorded_at_ms'] as int,
                  isUtc: true,
                ).toIso8601String(),
          r['policy_version'],
        ],
    ],
  };
  String xml(Object? v) {
    if ('$v'.length > 32767) {
      throw const ValidationFailure('Teks laporan melebihi batas Excel.');
    }
    return '$v'
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  const ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  const rel =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  final files = <String, String>{
    '[Content_Types].xml':
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>${List.generate(sheets.length, (i) => '<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>').join()}</Types>',
    '_rels/.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="$rel/officeDocument" Target="xl/workbook.xml"/></Relationships>',
    'xl/workbook.xml':
        '<workbook xmlns="$ns" xmlns:r="$rel"><sheets>${sheets.keys.indexed.map((s) => '<sheet name="${xml(s.$2)}" sheetId="${s.$1 + 1}" r:id="rId${s.$1 + 1}"/>').join()}</sheets></workbook>',
    'xl/_rels/workbook.xml.rels':
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="styles" Type="$rel/styles" Target="styles.xml"/>${List.generate(sheets.length, (i) => '<Relationship Id="rId${i + 1}" Type="$rel/worksheet" Target="worksheets/sheet${i + 1}.xml"/>').join()}</Relationships>',
    'xl/styles.xml':
        '<styleSheet xmlns="$ns"><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Calibri"/></font></fonts><fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF146B60"/><bgColor indexed="64"/></patternFill></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>',
  };
  for (final sheet in sheets.values.indexed) {
    files['xl/worksheets/sheet${sheet.$1 + 1}.xml'] =
        '<worksheet xmlns="$ns"><sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><cols><col min="1" max="23" width="24" customWidth="1"/></cols><sheetData>${sheet.$2.indexed.map((row) => '<row r="${row.$1 + 1}">${row.$2.map((v) => v == null
            ? '<c/>'
            : v is num && (v is! int || v.abs() < 1000000000000000)
            ? '<c t="n"><v>$v</v></c>'
            : '<c s="${row.$1 == 0 || (sheet.$1 == 0 && row.$1 == 5) ? 1 : 0}" t="inlineStr"><is><t xml:space="preserve">${xml(v)}</t></is></c>').join()}</row>').join()}</sheetData></worksheet>';
  }
  return _zip(files);
}

Uint8List _zip(Map<String, String> files) {
  final body = BytesBuilder(), central = BytesBuilder();
  void n(BytesBuilder b, int value, int size) {
    for (var i = 0; i < size; i++) {
      b.addByte((value >> (8 * i)) & 255);
    }
  }

  for (final file in files.entries) {
    final name = utf8.encode(file.key), data = utf8.encode(file.value);
    var crc = 0xffffffff;
    for (final byte in data) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xedb88320 : 0);
      }
    }
    crc ^= 0xffffffff;
    final offset = body.length;
    n(body, 0x04034b50, 4);
    n(body, 20, 2);
    n(body, 0, 2);
    n(body, 0, 2);
    n(body, 0, 2);
    n(body, 33, 2);
    n(body, crc, 4);
    n(body, data.length, 4);
    n(body, data.length, 4);
    n(body, name.length, 2);
    n(body, 0, 2);
    body.add(name);
    body.add(data);
    n(central, 0x02014b50, 4);
    n(central, 20, 2);
    n(central, 20, 2);
    n(central, 0, 2);
    n(central, 0, 2);
    n(central, 0, 2);
    n(central, 33, 2);
    n(central, crc, 4);
    n(central, data.length, 4);
    n(central, data.length, 4);
    n(central, name.length, 2);
    n(central, 0, 2);
    n(central, 0, 2);
    n(central, 0, 2);
    n(central, 0, 2);
    n(central, 0, 4);
    n(central, offset, 4);
    central.add(name);
  }
  final offset = body.length, length = central.length;
  body.add(central.takeBytes());
  n(body, 0x06054b50, 4);
  n(body, 0, 2);
  n(body, 0, 2);
  n(body, files.length, 2);
  n(body, files.length, 2);
  n(body, length, 4);
  n(body, offset, 4);
  n(body, 0, 2);
  return body.takeBytes();
}

class ReportFileSaver {
  const ReportFileSaver();
  Future<bool> save(Uint8List bytes, String name) async =>
      await const MethodChannel('fishcare/report_export')
          .invokeMethod<bool>('save', {'bytes': bytes, 'name': name}) ??
      false;
}
