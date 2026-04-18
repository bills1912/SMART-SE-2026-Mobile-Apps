import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/chat_models.dart';
import '../../../core/services/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChartNarrativeWidget
//
// Menampilkan interpretasi AI di bawah setiap chart di VisualizationCard.
//
// Cara kerja:
//   1. Bangun ringkasan teks dari data chart (VisualizationConfig)
//   2. Kirim ke /api/chat backend Railway — Gemini yang menjawab
//   3. Ambil field 'message' dari response
//   4. Cache per visualization.id agar tidak re-fetch saat rebuild
//   5. Tampilkan dengan efek typewriter + blinking cursor
//
// Kenapa pakai /api/chat, bukan Anthropic langsung?
//   Backend sudah pakai Gemini (gemini-2.5-flash di Railway).
//   Memanggil /api/chat konsisten, tidak butuh API key baru di Flutter,
//   dan model yang dipakai selalu sama dengan analisis utama.
// ─────────────────────────────────────────────────────────────────────────────

/// In-memory cache: visualization.id → narasi
final Map<String, String> _narrativeCache = {};

class ChartNarrativeWidget extends StatefulWidget {
  final VisualizationConfig visualization;

  /// Isi pesan AI yang menghasilkan chart ini — dikirim sebagai konteks.
  final String? parentMessageContext;

  const ChartNarrativeWidget({
    super.key,
    required this.visualization,
    this.parentMessageContext,
  });

  @override
  State<ChartNarrativeWidget> createState() => _ChartNarrativeWidgetState();
}

class _ChartNarrativeWidgetState extends State<ChartNarrativeWidget> {
  _NarrativeState _state = _NarrativeState.idle;
  String _narrative = '';
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadNarrative();
  }

  @override
  void didUpdateWidget(ChartNarrativeWidget old) {
    super.didUpdateWidget(old);
    if (old.visualization.id != widget.visualization.id) {
      _loadNarrative();
    }
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _loadNarrative() async {
    final cached = _narrativeCache[widget.visualization.id];
    if (cached != null && cached.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _narrative = cached;
        _state = _NarrativeState.success;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _state = _NarrativeState.loading);

    try {
      final result = await _fetchFromBackend();
      if (!mounted) return;
      _narrativeCache[widget.visualization.id] = result;
      setState(() {
        _narrative = result;
        _state = _NarrativeState.success;
      });
    } catch (e) {
      debugPrint('[ChartNarrative] Error: $e');
      if (!mounted) return;
      setState(() => _state = _NarrativeState.error);
    }
  }

  // ── Backend Call ──────────────────────────────────────────────────────────

  Future<String> _fetchFromBackend() async {
    const backendUrl =
        'https://smart-se26-agentic-ai-production.up.railway.app/api';

    final token = await StorageService.getSecure('session_token');

    final dio = Dio(BaseOptions(
      baseUrl: backendUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));

    final prompt = _buildPrompt();

    // POST ke /api/chat — Gemini di backend yang menjawab
    final response = await dio.post('/chat', data: {
      'message': prompt,
      // Tidak kirim session_id → session ephemeral, tidak masuk riwayat user
      'include_visualizations': false,
      'include_insights': false,
      'include_policies': false,
    });

    if (response.statusCode != 200) {
      throw Exception('Backend returned ${response.statusCode}');
    }

    final message = (response.data['message'] as String?)?.trim() ?? '';
    if (message.isEmpty) throw Exception('Empty message from backend');

    return message;
  }

  // ── Prompt ────────────────────────────────────────────────────────────────

  String _buildPrompt() {
    final summary = _buildChartSummary();

    // Potong konteks agar tidak terlalu panjang
    final ctx = widget.parentMessageContext;
    final ctxPart = (ctx != null && ctx.isNotEmpty)
        ? '\n\nKonteks analisis sebelumnya:\n${ctx.substring(0, ctx.length > 400 ? 400 : ctx.length)}'
        : '';

    return '''Kamu adalah analis data Sensus Ekonomi Indonesia (BPS).
Tugas SATU-SATUNYA: tulis interpretasi singkat dari data chart berikut.

Data chart:
$summary$ctxPart

Aturan WAJIB:
- Tulis 2-3 kalimat saja, tidak lebih
- Mulai LANGSUNG dengan temuan utama (jangan awali dengan "Chart ini" atau "Berdasarkan data")
- Wajib menyebut angka atau nama spesifik dari data
- Bahasa Indonesia yang mudah dipahami orang awam
- Sertakan satu hal yang perlu diperhatikan atau implikasi singkat
- JANGAN tambahkan heading, bullet, bold, atau formatting apapun

Contoh yang benar:
"Jawa Timur memimpin dengan 4,6 juta unit usaha, hampir dua kali lipat DKI Jakarta. Tiga provinsi teratas menguasai 47% dari total nasional, menandakan konsentrasi ekonomi yang tinggi di Pulau Jawa."

Tulis interpretasimu:''';
  }

  // ── Chart Summary Builder ─────────────────────────────────────────────────

  String _buildChartSummary() {
    final chartData = widget.visualization.chartData;
    final config = widget.visualization.config;

    if (chartData.isEmpty) return 'Data tidak tersedia.';

    final buf = StringBuffer();
    buf.writeln('Judul  : ${widget.visualization.title}');
    buf.writeln('Tipe   : ${widget.visualization.chartType}');
    buf.writeln('Jumlah data poin: ${chartData.length}');
    buf.writeln();

    // Statistik dasar
    final values = chartData
        .map((d) => (d['value'] ?? d['y'] ?? 0))
        .whereType<num>()
        .map((v) => v.toDouble())
        .toList();

    if (values.isNotEmpty) {
      final sorted = [...values]..sort();
      final total = values.fold(0.0, (s, v) => s + v);
      buf.writeln('Statistik:');
      buf.writeln('  Total    : ${_fmt(total.toInt())}');
      buf.writeln('  Tertinggi: ${_fmt(sorted.last.toInt())}');
      buf.writeln('  Terendah : ${_fmt(sorted.first.toInt())}');
      buf.writeln('  Rata-rata: ${_fmt((total / values.length).toInt())}');
      buf.writeln();

      // Top 10 sorted descending
      final sorted2 = [...chartData]..sort((a, b) {
        final va = (a['value'] ?? a['y'] ?? 0) is num
            ? (a['value'] ?? a['y'] ?? 0) as num
            : 0;
        final vb = (b['value'] ?? b['y'] ?? 0) is num
            ? (b['value'] ?? b['y'] ?? 0) as num
            : 0;
        return vb.compareTo(va);
      });

      buf.writeln(
          'Data ${chartData.length > 10 ? "(10 teratas)" : "(semua)"}:');
      for (int i = 0; i < sorted2.length && i < 10; i++) {
        final item = sorted2[i];
        final label =
            item['label'] ?? item['name'] ?? item['x'] ?? 'Item ${i + 1}';
        final val = (item['value'] ?? item['y'] ?? 0) as num;
        final pct =
        total > 0 ? (val / total * 100).toStringAsFixed(1) : '0';
        buf.writeln('  ${i + 1}. $label: ${_fmt(val.toInt())} ($pct%)');
      }
    }

    // Nama sumbu dari ECharts config
    final xName = config['xAxis'] is Map
        ? (config['xAxis'] as Map)['name']?.toString()
        : null;
    final yName = config['yAxis'] is Map
        ? (config['yAxis'] as Map)['name']?.toString()
        : null;
    if (xName != null) buf.writeln('Sumbu X: $xName');
    if (yName != null) buf.writeln('Sumbu Y: $yName');

    return buf.toString();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: switch (_state) {
        _NarrativeState.idle => const SizedBox.shrink(),
        _NarrativeState.loading => _buildLoading(isDark),
        _NarrativeState.success => _buildSuccess(isDark),
        _NarrativeState.error => _buildError(isDark),
      },
    );
  }

  Widget _buildLoading(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _deco(isDark),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Gemini sedang menganalisis chart...',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primaryOrange,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSuccess(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: _deco(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.primaryGradient.createShader(b),
                    child: const Icon(Icons.auto_awesome_rounded,
                        size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Interpretasi AI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryOrange,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _refresh,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.refresh_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            Divider(height: 1, color: AppColors.primaryOrange.withOpacity(0.15)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: _TypewriterText(
                text: _narrative,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  height: 1.65,
                  fontSize: 12.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _buildKeyTakeaway(isDark),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, curve: Curves.easeOutCubic);
  }

  Widget _buildKeyTakeaway(bool isDark) {
    final sentences = _narrative.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.isEmpty) return const SizedBox.shrink();
    final key = sentences.firstWhere(
          (s) => RegExp(r'\d').hasMatch(s),
      orElse: () => sentences.first,
    );
    if (key.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.push_pin_rounded, size: 11, color: AppColors.primaryOrange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              key.trim(),
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Gagal memuat interpretasi.',
                style: TextStyle(fontSize: 11, color: AppColors.error)),
          ),
          GestureDetector(
            onTap: _refresh,
            child: Text('Coba lagi',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _deco(bool isDark) => BoxDecoration(
    color: isDark
        ? AppColors.primaryOrange.withOpacity(0.06)
        : AppColors.primaryOrange.withOpacity(0.04),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
        color: AppColors.primaryOrange.withOpacity(isDark ? 0.2 : 0.15)),
  );

  void _refresh() {
    _narrativeCache.remove(widget.visualization.id);
    _loadNarrative();
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)} juta';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)} ribu';
    return n.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TypewriterText
// ─────────────────────────────────────────────────────────────────────────────

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  const _TypewriterText({required this.text, this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  int _visible = 0;
  late String _text;

  @override
  void initState() {
    super.initState();
    _text = widget.text;
    _start();
  }

  @override
  void didUpdateWidget(_TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _text = widget.text;
      _visible = 0;
      _start();
    }
  }

  void _start() {
    final total = _text.length;
    final ms = (1500 / total).clamp(8.0, 25.0).toInt();
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: ms));
      if (!mounted) return false;
      setState(() => _visible = (_visible + 3).clamp(0, _text.length));
      return _visible < _text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _visible >= _text.length;
    return RichText(
      text: TextSpan(children: [
        TextSpan(text: _text.substring(0, _visible), style: widget.style),
        if (!done)
          WidgetSpan(child: _BlinkingCursor(color: AppColors.primaryOrange)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BlinkingCursor
// ─────────────────────────────────────────────────────────────────────────────

class _BlinkingCursor extends StatefulWidget {
  final Color color;
  const _BlinkingCursor({required this.color});
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 530))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _ctrl.value,
        child: Container(
          width: 2,
          height: 13,
          margin: const EdgeInsets.only(left: 1, bottom: 1),
          decoration: BoxDecoration(
              color: widget.color, borderRadius: BorderRadius.circular(1)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State enum
// ─────────────────────────────────────────────────────────────────────────────

enum _NarrativeState { idle, loading, success, error }