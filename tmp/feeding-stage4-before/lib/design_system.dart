import 'dart:async';

import 'package:flutter/material.dart';

/// Token visual lokal; tidak memerlukan font atau aset dari jaringan.
abstract final class FishCareDesign {
  static const green = Color(0xFF12685D);
  static const background = Color(0xFFF6F8F4);
  static const ink = Color(0xFF173C39);
  static const muted = Color(0xFF58716D);
  static const line = Color(0xFFD8E4DE);
  static const mint = Color(0xFFE4F3EC);
  static const margin = 18.0;

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(seedColor: green).copyWith(
      primary: green,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: line,
      primaryContainer: mint,
      onPrimaryContainer: green,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final button = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      shape: WidgetStatePropertyAll(shape),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme
          .apply(bodyColor: ink, displayColor: ink)
          .copyWith(
            bodyMedium: const TextStyle(fontSize: 15, height: 1.5, color: ink),
            bodySmall: const TextStyle(fontSize: 13, height: 1.5, color: muted),
            titleLarge: const TextStyle(
              fontSize: 23,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 18,
        toolbarHeight: 72,
        titleTextStyle: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: button),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: button.copyWith(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          side: const WidgetStatePropertyAll(BorderSide(color: line)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: button),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          foregroundColor: const WidgetStatePropertyAll(ink),
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(shape),
          side: const WidgetStatePropertyAll(BorderSide(color: line)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.all(16),
        helperMaxLines: 4,
        errorMaxLines: 4,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: green, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: mint,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            color: states.contains(WidgetState.selected) ? green : muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: line,
        space: 24,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: green),
    );
  }
}

class FishAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FishAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });
  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;
  @override
  Size get preferredSize => const Size.fromHeight(88);
  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 88,
    leading: leading,
    actions: actions,
    title: DefaultTextStyle.merge(maxLines: 2, softWrap: true, child: title),
  );
}

/// Jarak form konsisten; ikut mengecil saat inset keyboard berubah.
class FormList extends StatefulWidget {
  const FormList({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(18),
    this.controllers = const [],
    this.additionalDirty,
    this.busy = false,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final List<TextEditingController> controllers;
  final bool Function()? additionalDirty;
  final bool busy;
  @override
  State<FormList> createState() => _FormListState();
}

class _FormListState extends State<FormList> {
  late final Map<TextEditingController, String> _initial;
  bool _allowExit = false, _asking = false;
  @override
  void initState() {
    super.initState();
    _initial = {for (final c in widget.controllers) c: c.text};
    for (final c in widget.controllers) {
      c.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  bool get _dirty =>
      _initial.entries.any((e) => e.key.text != e.value) ||
      (widget.additionalDirty?.call() ?? false);
  Future<void> _leave() async {
    if (_asking || widget.busy) return;
    _asking = true;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buang perubahan?'),
        content: const Text(
          'Keluar dari form ini? Input yang belum dikonfirmasi akan dibuang. Hasil tindakan yang sudah dikirim tetap dapat diperiksa melalui Pemulihan tindakan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tetap mengisi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    _asking = false;
    if (yes == true && mounted) {
      setState(() => _allowExit = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _initial.keys) {
      c.removeListener(_changed);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.busy && (_allowExit || !_dirty),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        unawaited(_leave());
      }
    },
    child: ListView(
      padding: widget.padding,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        for (var i = 0; i < widget.children.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          widget.children[i],
        ],
      ],
    ),
  );
}

class FishCard extends StatelessWidget {
  const FishCard({super.key, required this.child, this.emphasis = false});
  final Widget child;
  final bool emphasis;
  @override
  Widget build(BuildContext context) => Card(
    color: emphasis ? FishCareDesign.green : null,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: emphasis
          ? Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme
                    .apply(bodyColor: Colors.white, displayColor: Colors.white),
              ),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white),
                child: child,
              ),
            )
          : child,
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 12),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.warning = false});
  final String label;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF0D3) : FishCareDesign.mint,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: warning ? const Color(0xFF80530D) : FishCareDesign.green,
      ),
    ),
  );
}

class ValueRow extends StatelessWidget {
  const ValueRow(this.label, this.value, {super.key, this.valueKey});
  final String label, value;
  final Key? valueKey;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final name = Text(label, style: Theme.of(context).textTheme.bodySmall);
        final amount = Text(
          value,
          key: valueKey,
          style: const TextStyle(fontWeight: FontWeight.w700),
          textAlign: TextAlign.end,
        );
        final painter = TextPainter(
          text: TextSpan(
            text: value,
            style: DefaultTextStyle.of(context).style
                .copyWith(fontWeight: FontWeight.w700),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final valueWidth = painter.width.ceilToDouble() + 1;
        painter.dispose();
        final stacked = valueWidth > constraints.maxWidth * .58;
        return stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [name, amount],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: name),
                  const SizedBox(width: 12),
                  SizedBox(width: valueWidth, child: amount),
                ],
              );
      },
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.message, {super.key, this.warning = false});
  final String message;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF0D3) : FishCareDesign.mint,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(message),
  );
}

/// Konfirmasi layar penuh: ringkasan panjang tetap terjangkau pada teks besar.
Future<bool?> reviewAction(
  BuildContext context, {
  required String title,
  required String summary,
  String confirmLabel = 'Konfirmasi simpan',
  String backLabel = 'Kembali mengubah',
}) => Navigator.of(context).push<bool>(
  MaterialPageRoute(
    builder: (context) => _ActionReviewPage(
      title: title,
      summary: summary,
      confirmLabel: confirmLabel,
      backLabel: backLabel,
    ),
  ),
);

class _ActionReviewPage extends StatefulWidget {
  const _ActionReviewPage({
    required this.title,
    required this.summary,
    required this.confirmLabel,
    required this.backLabel,
  });
  final String title, summary, confirmLabel, backLabel;
  @override
  State<_ActionReviewPage> createState() => _ActionReviewPageState();
}

class _ActionReviewPageState extends State<_ActionReviewPage> {
  bool _leaving = false;
  void _finish(bool value) {
    if (_leaving) return;
    setState(() => _leaving = true);
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FishAppBar(title: Text(widget.title)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          FishCard(child: Text(widget.summary)),
          const Notice(
            'Periksa rincian sebelum menyimpan. Data akan divalidasi kembali saat pencatatan.',
          ),
          FilledButton(
            key: const ValueKey('confirm-action'),
            onPressed: _leaving ? null : () => _finish(true),
            child: Text(widget.confirmLabel),
          ),
          TextButton(
            onPressed: _leaving ? null : () => _finish(false),
            child: Text(widget.backLabel),
          ),
        ],
      ),
    ),
  );
}
