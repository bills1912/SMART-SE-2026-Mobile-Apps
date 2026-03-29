import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart';
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
  late MapController _mapController;

  BusinessLocation? _selected;
  bool _showCenters = true;
  bool _showHeatmap = false;
  bool _panelOpen = true;

  // Panel tab
  int _activeTab = 0; // 0=centers 1=insights 2=stats

  // Indonesia center
  static const _center = LatLng(-2.5, 118.0);
  static const _zoom = 4.5;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _mapController = MapController();
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
      // Use resizeToAvoidBottomInset: false to prevent layout shifts
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Frosted backdrop ────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),

          // ── Main card — uses SafeArea OUTSIDE the card ──────────
          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  // Let the card fill the safe area minus padding
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
                  // Use a Column that fills the container
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Top bar — fixed height
                      _buildTopBar(isDark),
                      // Content row — fills remaining space
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left: map
                            Expanded(child: _buildMapPanel(isDark)),
                            // Right: analysis panel (collapsible)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              child: _panelOpen
                                  ? SizedBox(
                                  width: 280,
                                  child: _buildAnalysisPanel(isDark))
                                  : const SizedBox(width: 0),
                            ),
                          ],
                        ),
                      ),
                      // Bottom bar — fixed height
                      _buildBottomBar(isDark),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color:
                isDark ? AppColors.darkDivider : AppColors.lightDivider)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.map, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          // Title - Expanded so it takes remaining space and never overflows
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Analisis Spasial — Sensus Ekonomi 2016',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '${widget.result.statistics.totalLocations} prov · '
                      '${_fmt(widget.result.statistics.totalUsaha)} usaha',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Toggle panel button
          GestureDetector(
            onTap: () => setState(() => _panelOpen = !_panelOpen),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _panelOpen
                    ? AppColors.primaryOrange.withOpacity(0.1)
                    : (isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(7),
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
                size: 14,
                color: _panelOpen
                    ? AppColors.primaryOrange
                    : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(Icons.close,
                  size: 14,
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
        // Map canvas with flutter_map
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: _zoom,
                  minZoom: 3.0,
                  maxZoom: 15.0,
                  onTap: (tapPosition, point) => _handleMapTap(point),
                ),
                children: [
                  // Google Hybrid base layer
                  TileLayer(
                    urlTemplate:
                    'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                    subdomains: const ['0', '1', '2', '3'],
                    userAgentPackageName:
                    'com.bps.smart_se2026_agentic_ai',
                    maxZoom: 20,
                  ),
                  // Corridor lines layer
                  fmap.PolylineLayer(
                    polylines: _buildCorridorLines(),
                  ),
                  // Business location markers
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => MarkerLayer(
                      markers: _buildAllMarkers(),
                    ),
                  ),
                ],
              ),

              // Zoom hint badge
              Positioned(
                bottom: 10,
                right: 10,
                child: _mapBadge('Pinch · Drag · Double-tap reset', isDark),
              ),
            ],
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

  /// Build corridor polylines connecting top provinces
  List<fmap.Polyline> _buildCorridorLines() {
    final nonZero =
    widget.result.locations.where((l) => l.totalUsaha > 0).toList();
    if (nonZero.length < 2) return [];

    final top6 = ([...nonZero]
      ..sort((a, b) => b.totalUsaha.compareTo(a.totalUsaha)))
        .take(6)
        .toList();

    final points = top6
        .map((l) => LatLng(l.latitude, l.longitude))
        .toList();

    return [
      fmap.Polyline(
        points: points,
        color: const Color(0xFFF97316).withOpacity(0.4),
        strokeWidth: 2.0,
        isDotted: true,
      ),
    ];
  }

  /// Build all map markers
  List<Marker> _buildAllMarkers() {
    final nonZero =
    widget.result.locations.where((l) => l.totalUsaha > 0).toList();
    if (nonZero.isEmpty) return [];

    final maxU = nonZero.map((l) => l.totalUsaha).reduce(max);
    final markers = <Marker>[];

    // Business dots
    for (final loc in nonZero) {
      final ratio = maxU > 0 ? loc.totalUsaha / maxU : 0.0;
      final isSelected = _selected?.id == loc.id;

      final color = ratio > 0.5
          ? const Color(0xFFE53E3E)
          : ratio > 0.2
          ? const Color(0xFFED8936)
          : const Color(0xFFF6C90E);

      final size = 10.0 + ratio * 20.0;

      markers.add(
        Marker(
          point: LatLng(loc.latitude, loc.longitude),
          width: size + 24,
          height: size + 24,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selected = _selected?.id == loc.id ? null : loc;
              });
              HapticFeedback.selectionClick();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring for selected
                if (isSelected)
                  Container(
                    width: size + 14 + _pulseCtrl.value * 10,
                    height: size + 14 + _pulseCtrl.value * 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF97316)
                          .withOpacity(0.3 * (1 - _pulseCtrl.value)),
                    ),
                  ),
                // Glow
                Container(
                  width: size + 8,
                  height: size + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.22),
                  ),
                ),
                // Fill
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: size * 0.28,
                      height: size * 0.28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Economic center star markers
    if (_showCenters) {
      for (final center in widget.result.economicCenters) {
        final sz = center.centerType == 'primary' ? 9.0 : 6.5;
        markers.add(
          Marker(
            point: LatLng(center.latitude, center.longitude),
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: () {
                final loc = widget.result.locations.firstWhere(
                      (l) => l.province == center.province,
                  orElse: () => widget.result.locations.first,
                );
                setState(() => _selected = loc);
                HapticFeedback.selectionClick();
              },
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _StarPainter(
                    color: AppColors.primaryOrange,
                    pulseValue: _pulseCtrl.value,
                    isPrimary: center.centerType == 'primary',
                    sz: sz,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
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
          _toolBtn(Icons.add, () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1), isDark),
          const SizedBox(width: 4),
          _toolBtn(Icons.remove, () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1), isDark),
          const SizedBox(width: 4),
          _toolBtn(Icons.center_focus_strong, () {
            _mapController.move(_center, _zoom);
          }, isDark),
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
    final nonZero =
    widget.result.locations.where((l) => l.totalUsaha > 0).toList();
    final maxU = nonZero.isNotEmpty
        ? nonZero.map((l) => l.totalUsaha).reduce(max)
        : 1;
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
                  style: const TextStyle(
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
                      flex: ((1 - ratio) * 100).round().clamp(0, 100),
                      child: Container(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface)),
                  Expanded(
                      flex: (ratio * 100).round().clamp(1, 100),
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
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
              color:
              isDark ? AppColors.darkDivider : AppColors.lightDivider),
        ),
      ),
      // Column must fill full height — tabs + scrollable content + narrative
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          _buildTabs(isDark),
          // Scrollable tab content — takes all remaining space
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
          // Narrative bar — fixed at bottom, height constrained
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
                    fontWeight:
                    active ? FontWeight.w700 : FontWeight.w400,
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
        ...centers.asMap().entries
            .map((e) => _centerItem(e.value, e.key, isDark)),
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
        final loc = widget.result.locations.firstWhere(
              (l) => l.province == c.province,
          orElse: () => widget.result.locations.first,
        );
        setState(() => _selected = loc);
        // Pan map to province
        _mapController.move(
            LatLng(loc.latitude, loc.longitude), 6.0);
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
        ...insights.asMap().entries
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
              children: insight.relatedProvinces.take(3).map((p) =>
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border:
                      Border.all(color: typeColor.withOpacity(0.2)),
                    ),
                    child: Text(p,
                        style: TextStyle(
                            fontSize: 9,
                            color: typeColor,
                            fontWeight: FontWeight.w600)),
                  )).toList(),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: idx * 70))
        .fadeIn()
        .slideX(begin: 0.06);
  }

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
        _statRow('Rata-rata',
            _fmt(s.averageUsahaPerLocation.toInt()), isDark),
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
                      top5.fold(0.0,
                              (s, e) => s + e.value / total)) *
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
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontSize: 10),
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

  Widget _buildNarrativeBar(bool isDark) {
    // Limit narrative to 3 lines maximum to prevent overflow
    final narrativeText = widget.result.narrativeAnalysis
        .replaceAll('**', '')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(3)
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.06),
        border: Border(
            top: BorderSide(
                color: AppColors.primaryOrange.withOpacity(0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 11, color: AppColors.primaryOrange),
              const SizedBox(width: 4),
              Text('Ringkasan Analisis',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryOrange)),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            narrativeText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                height: 1.4,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          const SizedBox(width: 10),
          _dot(const Color(0xFFED8936), 'Sedang', isDark),
          const SizedBox(width: 10),
          _dot(const Color(0xFFECC94B), 'Rendah', isDark),
          if (_showCenters) ...[
            const SizedBox(width: 10),
            Icon(Icons.star, size: 11, color: AppColors.primaryOrange),
            const SizedBox(width: 3),
            Text('Pusat Ekonomi',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9, color: AppColors.primaryOrange)),
          ],
          const Spacer(),
          // Flexible prevents this text from causing overflow
          Flexible(
            child: Text(
              'Sumber: BPS SE 2016',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                  fontSize: 9),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
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

  void _handleMapTap(LatLng point) {
    // Find nearest location within ~50km tap radius
    BusinessLocation? nearest;
    double minDist = double.infinity;

    for (final loc in widget.result.locations) {
      final dlat = loc.latitude - point.latitude;
      final dlng = loc.longitude - point.longitude;
      final dist = sqrt(dlat * dlat + dlng * dlng);
      if (dist < minDist && dist < 1.0) {
        // ~1 degree ≈ 111km, use 1.0 as threshold
        minDist = dist;
        nearest = loc;
      }
    }

    setState(() {
      _selected = nearest == _selected ? null : nearest;
    });
    if (nearest != null) HapticFeedback.selectionClick();
  }

  String _fmt(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.');
}

// ─── Star marker painter ────────────────────────────────────────────────────

class _StarPainter extends CustomPainter {
  final Color color;
  final double pulseValue;
  final bool isPrimary;
  final double sz;

  _StarPainter({
    required this.color,
    required this.pulseValue,
    required this.isPrimary,
    required this.sz,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Pulsing ring
    canvas.drawCircle(
      center,
      sz + 5 + pulseValue * 6,
      Paint()
        ..color = color.withOpacity(0.18 * (1 - pulseValue * 0.4))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Star
    final path = ui.Path();
    const pts = 5;
    for (int i = 0; i < pts * 2; i++) {
      final angle = (i * pi / pts) - pi / 2;
      final rad = i.isEven ? sz : sz * 0.42;
      final x = center.dx + rad * cos(angle);
      final y = center.dy + rad * sin(angle);
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
  bool shouldRepaint(_StarPainter o) =>
      o.pulseValue != pulseValue || o.isPrimary != isPrimary;
}