import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/models/spatial_analysis_models.dart';

/// Full-screen overlay map with analysis panels.
/// Pushed as a route from SpatialMapWidget.
class SpatialFullscreenMap extends StatefulWidget {
  final SpatialAnalysisResult result;

  const SpatialFullscreenMap({super.key, required this.result});

  @override
  State<SpatialFullscreenMap> createState() => _SpatialFullscreenMapState();
}

class _SpatialFullscreenMapState extends State<SpatialFullscreenMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  BusinessLocation? _selected;
  bool _showCenters = true;
  bool _showHeatmap = false;
  bool _panelOpen = true;

  // Map viewport
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;
  double _startScale = 1.0;

  // Panel tab
  int _activeTab = 0; // 0=centers 1=insights 2=stats

  late Size _canvasSize;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Frosted backdrop ────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),

          // ── Main card ───────────────────────────────────────────
          SafeArea(
            child: Center(
              child: Container(
                margin:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : const Color(0xFFF0F4FA),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 4)
                  ],
                ),
                child: Column(
                  children: [
                    _buildTopBar(isDark),
                    Expanded(
                      child: Row(
                        children: [
                          // Left: map
                          Expanded(child: _buildMapPanel(isDark)),
                          // Right: analysis panel (collapsible)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: _panelOpen
                                ? _buildAnalysisPanel(isDark)
                                : const SizedBox(width: 0),
                          ),
                        ],
                      ),
                    ),
                    _buildBottomBar(isDark),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 250.ms).scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1, 1),
            curve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  // ─── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color:
                isDark ? AppColors.darkDivider : AppColors.lightDivider)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.map, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analisis Spasial — Sensus Ekonomi 2016',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${widget.result.statistics.totalLocations} provinsi · '
                      '${_fmt(widget.result.statistics.totalUsaha)} unit usaha',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Toggle panel
          GestureDetector(
            onTap: () => setState(() => _panelOpen = !_panelOpen),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _panelOpen
                    ? AppColors.primaryOrange.withOpacity(0.1)
                    : (isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _panelOpen
                        ? AppColors.primaryOrange.withOpacity(0.3)
                        : (isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder)),
              ),
              child: Icon(
                _panelOpen
                    ? Icons.view_sidebar
                    : Icons.view_sidebar_outlined,
                size: 16,
                color: _panelOpen
                    ? AppColors.primaryOrange
                    : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Close
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.close,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Map panel ─────────────────────────────────────────────────────────────
  Widget _buildMapPanel(bool isDark) {
    return Column(
      children: [
        // Map tools
        _buildMapTools(isDark),
        // Map canvas
        Expanded(
          child: GestureDetector(
            onScaleStart: (d) {
              _startFocal = d.focalPoint;
              _startOffset = _offset;
              _startScale = _scale;
            },
            onScaleUpdate: (d) => setState(() {
              _scale = (_startScale * d.scale).clamp(0.6, 5.0);
              _offset = _startOffset + (d.focalPoint - _startFocal);
            }),
            onDoubleTap: () => setState(() {
              _scale = 1.0;
              _offset = Offset.zero;
            }),
            onTapUp: (d) => _handleTap(d.localPosition),
            child: Container(
              color: isDark
                  ? const Color(0xFF080C12)
                  : const Color(0xFFCDD9EE),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _GridPainter(isDark: isDark)),
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => LayoutBuilder(
                      builder: (context, constraints) {
                        _canvasSize = Size(
                            constraints.maxWidth, constraints.maxHeight);
                        return CustomPaint(
                          painter: _FSMapPainter(
                            locations: widget.result.locations,
                            economicCenters: widget.result.economicCenters,
                            selectedLocation: _selected,
                            showCenters: _showCenters,
                            showHeatmap: _showHeatmap,
                            isDark: isDark,
                            scale: _scale,
                            offset: _offset,
                            pulseValue: _pulseCtrl.value,
                          ),
                        );
                      },
                    ),
                  ),
                  // Zoom hint
                  Positioned(
                    bottom: 10, right: 10,
                    child: _mapBadge('Pinch · Drag · Double-tap reset', isDark),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Selected location card
        if (_selected != null)
          _buildSelectedCard(_selected!, isDark)
              .animate()
              .slideY(begin: 0.2, duration: 200.ms)
              .fadeIn(),
      ],
    );
  }

  Widget _buildMapTools(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withOpacity(0.8)
            : Colors.white.withOpacity(0.7),
        border: Border(
            bottom: BorderSide(
                color: isDark
                    ? AppColors.darkDivider
                    : AppColors.lightDivider)),
      ),
      child: Row(
        children: [
          // Zoom buttons
          _toolBtn(Icons.add, () => setState(() => _scale = (_scale * 1.3).clamp(0.6, 5.0)), isDark),
          const SizedBox(width: 4),
          _toolBtn(Icons.remove, () => setState(() => _scale = (_scale / 1.3).clamp(0.6, 5.0)), isDark),
          const SizedBox(width: 4),
          _toolBtn(Icons.center_focus_strong,
                  () => setState(() { _scale = 1.0; _offset = Offset.zero; }), isDark),
          const Spacer(),
          // Toggles
          _toggleChip('Pusat', _showCenters,
                  () => setState(() => _showCenters = !_showCenters), isDark),
          const SizedBox(width: 6),
          _toggleChip('Densitas', _showHeatmap,
                  () => setState(() => _showHeatmap = !_showHeatmap), isDark),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Icon(icon,
            size: 14,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
      ),
    );
  }

  Widget _toggleChip(
      String label, bool active, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryOrange.withOpacity(0.12)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.primaryOrange.withOpacity(0.4)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active
                    ? AppColors.primaryOrange
                    : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary))),
      ),
    );
  }

  Widget _buildSelectedCard(BusinessLocation loc, bool isDark) {
    final total = widget.result.statistics.totalUsaha;
    final pct = total > 0 ? (loc.totalUsaha / total * 100) : 0.0;
    final maxU = widget.result.locations.map((l) => l.totalUsaha).reduce(max);
    final ratio = maxU > 0 ? loc.totalUsaha / maxU : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.08),
        border: Border(
          top: BorderSide(color: AppColors.primaryOrange.withOpacity(0.25)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
            const Icon(Icons.location_on, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.province,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('Sektor utama: ${loc.sectorName}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmt(loc.totalUsaha),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryOrange)),
              Text('${pct.toStringAsFixed(1)}% nasional',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary)),
            ],
          ),
          const SizedBox(width: 10),
          // Mini spark bar
          SizedBox(
            width: 4,
            height: 36,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Column(
                children: [
                  Expanded(
                      flex: ((1 - ratio) * 100).round(),
                      child: Container(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface)),
                  Expanded(
                      flex: (ratio * 100).round(),
                      child:
                      Container(color: AppColors.primaryOrange)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Analysis panel ────────────────────────────────────────────────────────
  Widget _buildAnalysisPanel(bool isDark) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
              color:
              isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
      ),
      child: Column(
        children: [
          // Tabs
          _buildTabs(isDark),
          // Tab content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: _activeTab == 0
                  ? _buildCentersTab(isDark)
                  : _activeTab == 1
                  ? _buildInsightsTab(isDark)
                  : _buildStatsTab(isDark),
            ),
          ),
          // Narrative
          _buildNarrativeBar(isDark),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    final tabs = ['Pusat', 'Insight', 'Statistik'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color:
                isDark ? AppColors.darkDivider : AppColors.lightDivider)),
        color: isDark
            ? AppColors.darkSurface.withOpacity(0.5)
            : Colors.white.withOpacity(0.6),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final active = _activeTab == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primaryOrange.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: active
                        ? AppColors.primaryOrange
                        : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Centers tab
  Widget _buildCentersTab(bool isDark) {
    final centers = widget.result.economicCenters;
    if (centers.isEmpty) {
      return Center(
        child: Text('Tidak ada data pusat ekonomi',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('⭐  Pusat-Pusat Ekonomi',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...centers.asMap().entries.map((e) =>
            _centerItem(e.value, e.key, isDark)),
      ],
    );
  }

  Widget _centerItem(EconomicCenter c, int idx, bool isDark) {
    final colors = [
      const Color(0xFFE53E3E),
      const Color(0xFFED8936),
      const Color(0xFFECC94B),
      const Color(0xFF38A169),
      const Color(0xFF3182CE),
    ];
    final col = colors[idx % colors.length];
    final maxU = widget.result.economicCenters
        .map((x) => x.totalUsaha)
        .reduce(max);

    return GestureDetector(
      onTap: () {
        // Pan map to this center
        setState(() {
          final loc = widget.result.locations.firstWhere(
                (l) => l.province == c.province,
            orElse: () => widget.result.locations.first,
          );
          _selected = loc;
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: col.withOpacity(0.25), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                      child: Text('${idx + 1}',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: col))),
                ),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(c.name,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700))),
                Text('${c.score.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: col)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: maxU > 0 ? c.totalUsaha / maxU : 0,
                backgroundColor: isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
                valueColor: AlwaysStoppedAnimation(col),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(_fmt(c.totalUsaha) + ' usaha',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                    fontSize: 10)),
          ],
        ),
      ).animate(delay: Duration(milliseconds: idx * 60)).fadeIn().slideX(begin: 0.06),
    );
  }

  // Insights tab
  Widget _buildInsightsTab(bool isDark) {
    final insights = widget.result.insights;
    if (insights.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🔍  Temuan Spasial',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...insights
            .asMap()
            .entries
            .map((e) => _insightItem(e.value, e.key, isDark)),
      ],
    );
  }

  Widget _insightItem(SpatialInsight insight, int idx, bool isDark) {
    final typeColor = {
      'concentration': const Color(0xFFE53E3E),
      'cluster': const Color(0xFF3182CE),
      'gap': const Color(0xFFED8936),
      'corridor': const Color(0xFF38A169),
      'anomaly': const Color(0xFF805AD5),
    }[insight.type] ??
        AppColors.primaryOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: typeColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(insight.title,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                          fontWeight: FontWeight.w700, fontSize: 11))),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: insight.magnitude.clamp(0.0, 1.0),
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: typeColor)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(insight.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)),
          if (insight.relatedProvinces.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 3,
              children: insight.relatedProvinces
                  .take(3)
                  .map((p) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: typeColor.withOpacity(0.2)),
                ),
                child: Text(p,
                    style: TextStyle(
                        fontSize: 9,
                        color: typeColor,
                        fontWeight: FontWeight.w600)),
              ))
                  .toList(),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: idx * 70))
        .fadeIn()
        .slideX(begin: 0.06);
  }

  // Stats tab
  Widget _buildStatsTab(bool isDark) {
    final s = widget.result.statistics;
    final sorted = s.usahaByProvince.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();
    final total = s.totalUsaha;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📊  Statistik',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _statRow('Total Provinsi', s.totalLocations.toString(), isDark),
        _statRow('Total Usaha', _fmt(s.totalUsaha), isDark),
        _statRow('Rata-rata', _fmt(s.averageUsahaPerLocation.toInt()),
            isDark),
        _statRow(
            'Indeks Konsentrasi',
            '${(s.spatialConcentrationIndex * 100).toStringAsFixed(0)}%',
            isDark),
        _statRow('Densitas Tertinggi', s.highestDensityRegion, isDark),
        _statRow('Densitas Terendah', s.lowestDensityRegion, isDark),
        const SizedBox(height: 14),
        Text('Top 5 Provinsi',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        // Stacked bar
        if (total > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                ...top5.asMap().entries.map((e) {
                  final colors = [
                    const Color(0xFFE53E3E),
                    const Color(0xFFED8936),
                    const Color(0xFFECC94B),
                    const Color(0xFF38A169),
                    const Color(0xFF3182CE),
                  ];
                  final pct = e.value.value / total;
                  return Flexible(
                    flex: (pct * 1000).round().clamp(1, 1000),
                    child: Container(
                        height: 10,
                        color: colors[e.key % colors.length]),
                  );
                }),
                Flexible(
                  flex: ((1 -
                      top5.fold(
                          0.0,
                              (s, e) =>
                          s + e.value / total)) *
                      1000)
                      .round()
                      .clamp(0, 1000),
                  child: Container(
                      height: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        ...top5.asMap().entries.map((e) {
          final colors = [
            const Color(0xFFE53E3E),
            const Color(0xFFED8936),
            const Color(0xFFECC94B),
            const Color(0xFF38A169),
            const Color(0xFF3182CE),
          ];
          final pct = total > 0 ? (e.value.value / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                        color: colors[e.key % colors.length],
                        shape: BoxShape.circle)),
                Expanded(
                    child: Text(
                      e.value.key,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    )),
                Text('${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors[e.key % colors.length])),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _statRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                      fontSize: 10))),
          Text(value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700, fontSize: 10)),
        ],
      ),
    );
  }

  // Narrative
  Widget _buildNarrativeBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.06),
        border: Border(
            top: BorderSide(
                color: AppColors.primaryOrange.withOpacity(0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 12, color: AppColors.primaryOrange),
              const SizedBox(width: 4),
              Text('Ringkasan Analisis',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryOrange)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.result.narrativeAnalysis
                .replaceAll('**', '')
                .split('\n')
                .take(4)
                .join('\n'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Bottom bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color:
                isDark ? AppColors.darkDivider : AppColors.lightDivider)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          _dot(const Color(0xFFE53E3E), 'Tinggi', isDark),
          const SizedBox(width: 12),
          _dot(const Color(0xFFED8936), 'Sedang', isDark),
          const SizedBox(width: 12),
          _dot(const Color(0xFFECC94B), 'Rendah', isDark),
          const SizedBox(width: 12),
          if (_showCenters) ...[
            Icon(Icons.star, size: 11, color: AppColors.primaryOrange),
            const SizedBox(width: 4),
            Text('Pusat Ekonomi',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.primaryOrange)),
          ],
          const Spacer(),
          Text('Sumber: BPS Sensus Ekonomi 2016',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                  fontSize: 9)),
        ],
      ),
    );
  }

  Widget _dot(Color color, String label, bool isDark) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 4),
      Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary)),
    ]);
  }

  Widget _mapBadge(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white60, fontSize: 9)),
    );
  }

  // ─── Tap detection ─────────────────────────────────────────────────────────
  void _handleTap(Offset localPos) {
    final painter = _FSMapPainter(
      locations: widget.result.locations,
      economicCenters: [],
      selectedLocation: null,
      showCenters: false,
      showHeatmap: false,
      isDark: true,
      scale: _scale,
      offset: _offset,
      pulseValue: 0,
    );

    for (final loc in widget.result.locations) {
      final pos = painter.project(
          loc.latitude, loc.longitude, _canvasSize);
      if ((pos - localPos).distance < 20) {
        setState(() {
          _selected = _selected?.id == loc.id ? null : loc;
        });
        HapticFeedback.selectionClick();
        return;
      }
    }
    setState(() => _selected = null);
  }

  String _fmt(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.');
}

// ─── Fullscreen Painter (same logic, larger canvas) ────────────────────────

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = (isDark ? Colors.white : Colors.blueGrey).withOpacity(0.05)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) => false;
}

class _FSMapPainter extends CustomPainter {
  final List<BusinessLocation> locations;
  final List<EconomicCenter> economicCenters;
  final BusinessLocation? selectedLocation;
  final bool showCenters;
  final bool showHeatmap;
  final bool isDark;
  final double scale;
  final Offset offset;
  final double pulseValue;

  _FSMapPainter({
    required this.locations,
    required this.economicCenters,
    required this.selectedLocation,
    required this.showCenters,
    required this.showHeatmap,
    required this.isDark,
    required this.scale,
    required this.offset,
    required this.pulseValue,
  });

  static const double _minLat = -11.5;
  static const double _maxLat = 6.5;
  static const double _minLng = 94.5;
  static const double _maxLng = 142.0;
  static const double _pad = 24.0;

  Offset project(double lat, double lng, Size size) {
    final w = size.width - _pad * 2;
    final h = size.height - _pad * 2;
    final x = _pad + (lng - _minLng) / (_maxLng - _minLng) * w;
    final y = _pad + (1.0 - (lat - _minLat) / (_maxLat - _minLat)) * h;
    final cx = size.width / 2;
    final cy = size.height / 2;
    return Offset(
      cx + (x - cx) * scale + offset.dx,
      cy + (y - cy) * scale + offset.dy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (locations.isEmpty) return;
    final nonZero = locations.where((l) => l.totalUsaha > 0).toList();
    if (nonZero.isEmpty) return;
    final maxU = nonZero.map((l) => l.totalUsaha).reduce(max);

    if (showHeatmap) {
      for (final loc in nonZero) {
        final pos = project(loc.latitude, loc.longitude, size);
        final intensity = loc.totalUsaha / maxU;
        final r = 20.0 + intensity * 48.0;
        canvas.drawCircle(
          pos,
          r,
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xFFEF4444).withOpacity(0.3 * intensity),
              Colors.transparent,
            ]).createShader(Rect.fromCircle(center: pos, radius: r)),
        );
      }
    }

    // Corridor lines
    final top6 = ([...nonZero]
      ..sort((a, b) => b.totalUsaha.compareTo(a.totalUsaha)))
        .take(6)
        .toList();
    final cp = Paint()
      ..color = const Color(0xFFF97316).withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < top6.length - 1; i++) {
      canvas.drawLine(
        project(top6[i].latitude, top6[i].longitude, size),
        project(top6[i + 1].latitude, top6[i + 1].longitude, size),
        cp,
      );
    }

    // Dots
    for (final loc in locations) {
      if (loc.totalUsaha == 0) continue;
      final pos = project(loc.latitude, loc.longitude, size);
      final ratio = loc.totalUsaha / maxU;
      final isSel = selectedLocation?.id == loc.id;
      final r = 4.5 + ratio * 16.0;

      final color = ratio > 0.5
          ? const Color(0xFFE53E3E)
          : ratio > 0.2
          ? const Color(0xFFED8936)
          : const Color(0xFFECC94B);

      if (isSel) {
        canvas.drawCircle(
          pos,
          r + 6 + pulseValue * 8,
          Paint()
            ..color = const Color(0xFFF97316)
                .withOpacity(0.28 * (1 - pulseValue)),
        );
      }
      canvas.drawCircle(pos, r + 3, Paint()..color = color.withOpacity(0.2));
      canvas.drawCircle(pos, r, Paint()..color = color);
      canvas.drawCircle(
          pos, r * 0.28, Paint()..color = Colors.white.withOpacity(0.75));

      if (ratio > 0.35 || isSel) {
        final parts = loc.province.split(' ');
        final short = parts.length >= 2 ? parts.last : loc.province;
        _drawLabel(canvas, pos, short, r, isSel);
      }
    }

    // Centers
    if (showCenters) {
      for (final c in economicCenters) {
        final pos = project(c.latitude, c.longitude, size);
        final isPrimary = c.centerType == 'primary';
        final sz = isPrimary ? 9.0 : 6.5;
        canvas.drawCircle(
          pos,
          sz + 6 + pulseValue * 6,
          Paint()
            ..color = const Color(0xFFF97316)
                .withOpacity(0.18 * (1 - pulseValue * 0.4))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        _drawStar(canvas, pos, sz, const Color(0xFFF97316));
      }
    }
  }

  void _drawLabel(Canvas canvas, Offset p, String t, double r, bool bold) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: bold ? 11 : 9,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          shadows: [
            Shadow(
              color: isDark
                  ? Colors.black.withOpacity(0.9)
                  : Colors.white.withOpacity(0.9),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy + r + 3));
  }

  void _drawStar(Canvas canvas, Offset c, double sz, Color color) {
    final path = Path();
    const pts = 5;
    for (int i = 0; i < pts * 2; i++) {
      final angle = (i * pi / pts) - pi / 2;
      final rad = i.isEven ? sz : sz * 0.42;
      final x = c.dx + rad * cos(angle);
      final y = c.dy + rad * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FSMapPainter o) =>
      o.selectedLocation != selectedLocation ||
          o.pulseValue != pulseValue ||
          o.scale != scale ||
          o.offset != offset ||
          o.showCenters != showCenters ||
          o.showHeatmap != showHeatmap;
}