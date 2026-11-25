import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_system.dart';
import 'intro_store.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.store,
    required this.homeBuilder,
    this.minimumSplash = const Duration(milliseconds: 700),
  });
  final IntroStore store;
  final WidgetBuilder homeBuilder;
  final Duration minimumSplash;
  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _loading = true, _done = false, _readFailed = false;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final pause = Future<void>.delayed(widget.minimumSplash);
    bool done = false, failed = false;
    try {
      done = await widget.store.completed().timeout(const Duration(seconds: 5));
    } catch (_) {
      failed = true;
    }
    await pause;
    if (mounted)
      setState(() {
        _done = done;
        _readFailed = failed;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const FishSplash();
    if (_done) return widget.homeBuilder(context);
    return FishIntroduction(
      store: widget.store,
      readFailed: _readFailed,
      onFinished: () => setState(() => _done = true),
    );
  }
}

class FishMascot extends StatelessWidget {
  const FishMascot({super.key, this.size = 240});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFFD5F0E7), FishCareDesign.background],
        ),
      ),
      child: Image.asset(
        'assets/branding/mascot.png',
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        cacheWidth: 640,
      ),
    ),
  );
}

class FishSplash extends StatelessWidget {
  const FishSplash({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight, minWidth: box.maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FishMascot(size: math.min(260, box.maxWidth - 48)),
                  const SizedBox(height: 20),
                  const Text(
                    'FishCare',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kelola kolam, pantau pakan',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  Semantics(
                    label: 'Membuka FishCare',
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

const _pages = [
  (
    image: 'ponds',
    title: 'Semua kolam,\nlebih tertata',
    description:
        'Catat kolam dan pantau perkembangan ikan dalam satu aplikasi.',
  ),
  (
    image: 'feed',
    title: 'Pakan lebih\nterencana',
    description: 'Lihat jadwal, catat pemberian, dan pantau stok pakan.',
  ),
  (
    image: 'reports',
    title: 'Catatan jadi\nlebih jelas',
    description:
        'Tinjau biaya pakan dan hasil panen, lalu ekspor laporan ke Excel.',
  ),
];

class FishIntroduction extends StatefulWidget {
  const FishIntroduction({
    super.key,
    required this.store,
    required this.onFinished,
    this.readFailed = false,
  });
  final IntroStore store;
  final VoidCallback onFinished;
  final bool readFailed;
  @override
  State<FishIntroduction> createState() => _FishIntroductionState();
}

class _FishIntroductionState extends State<FishIntroduction> {
  final _controller = PageController();
  int _page = 0;
  bool _saving = false, _leaving = false;
  String? _error;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enter() {
    if (_leaving) return;
    _leaving = true;
    widget.onFinished();
  }

  Future<void> _finish() async {
    if (_saving || _leaving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.complete().timeout(const Duration(seconds: 5));
      if (mounted) _enter();
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'Pilihan belum tersimpan. Coba lagi atau lanjut; perkenalan mungkin muncul kembali saat aplikasi dibuka.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (_saving || _leaving) return;
    if (_page == _pages.length - 1) {
      unawaited(_finish());
      return;
    }
    _controller.animateToPage(
      _page + 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving && _page == 0,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !_saving && _page > 0)
        _controller.previousPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
    },
    child: Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
                child: Row(
                  children: [
                    const Text(
                      'FishCare',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: FishCareDesign.green,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : _finish,
                      child: const Text('Lewati'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  physics: _saving
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        key: PageStorageKey('intro-$index'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(0, box.maxHeight - 16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/branding/${page.image}.png',
                                height: (box.maxHeight * .5).clamp(
                                  140.0,
                                  310.0,
                                ),
                                width: double.infinity,
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                                cacheWidth: 900,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                page.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                page.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                              if (widget.readFailed)
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Preferensi perkenalan belum dapat dibaca.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Flexible(
                flex: 0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * .45,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            label: 'Halaman ${_page + 1} dari 3',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < 3; i++)
                                  Container(
                                    width: 9,
                                    height: 9,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _page == i
                                          ? FishCareDesign.green
                                          : const Color(0xFFAAD5C8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_error != null) ...[
                            Text(_error!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: _saving ? null : _enter,
                              child: const Text('Lanjut tanpa menyimpan'),
                            ),
                          ],
                          FilledButton(
                            onPressed: _saving
                                ? null
                                : (_error != null ? _finish : _next),
                            child: Text(
                              _saving
                                  ? 'Menyimpan…'
                                  : _error != null
                                  ? 'Coba lagi'
                                  : _page == 2
                                  ? 'Mulai'
                                  : 'Lanjut',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
