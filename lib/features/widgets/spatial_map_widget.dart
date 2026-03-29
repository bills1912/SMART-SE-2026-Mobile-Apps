import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/models/spatial_analysis_models.dart';
import '../map/spatial_fullscreen_map.dart';

/// Compact map card shown inside chat.
/// Tapping the map opens SpatialFullscreenMap.
class SpatialMapWidget extends StatefulWidget {
  final SpatialAnalysisResult result;
  final VoidCallback? onClose;

  const SpatialMapWidget({
    super.key,
    required this.result,
    this.onClose,
  });

  @override
  State<SpatialMapWidget> createState() => _SpatialMapWidgetState();
}

class _SpatialMapWidgetState extends State<SpatialMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late MapController _mapController;
  BusinessLocation? _selectedLocation;
  bool _showCenters = true;
  bool _showHeatmap = false;

  // Indonesia center
  static const _center = LatLng(-2.5, 118.0);
  static const _zoom = 4.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) =>
            SpatialFullscreenMap(result: widget.result),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),

          // ── Map canvas ─────────────────────────────────────────
          GestureDetector(
            onTap: _openFullscreen,
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  children: [
                    // Flutter Map with Google Hybrid tiles
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _center,
                        initialZoom: _zoom,
                        interactionOptions: const InteractionOptions(
                          // Disable interaction in compact card — tap opens fullscreen
                          flags: InteractiveFlag.none,
                        ),
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
                        // Business location markers overlay
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) {
                            return _buildMarkersLayer();
                          },
                        ),
                      ],
                    ),

                    // Tap overlay — open fullscreen
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_full,
                                size: 10, color: Colors.white70),
                            SizedBox(width: 4),
                            Text('Tap untuk peta penuh',
                                style: TextStyle(
                                    fontSize: 9, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),

                    // Province count badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.result.locations.length} provinsi',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Selected location detail ────────────────────────────
          if (_selectedLocation != null) _buildLocationDetail(isDark),

          // ── Legend + toggles ────────────────────────────────────
          _buildFooter(isDark),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06);
  }

  /// Build flutter_map MarkerLayer for all business locations
  Widget _buildMarkersLayer() {
    final nonZero =
    widget.result.locations.where((l) => l.totalUsaha > 0).toList();
    if (nonZero.isEmpty) return const SizedBox();

    final maxU = nonZero.map((l) => l.totalUsaha).reduce(max);

    final markers = nonZero.map((loc) {
      final ratio = maxU > 0 ? loc.totalUsaha / maxU : 0.0;
      final isSelected = _selectedLocation?.id == loc.id;

      final color = ratio > 0.5
          ? const Color(0xFFE53E3E)
          : ratio > 0.2
          ? const Color(0xFFED8936)
          : const Color(0xFFF6C90E);

      // Scale dot size: 8–22px diameter
      final size = 8.0 + ratio * 14.0;

      return Marker(
        point: LatLng(loc.latitude, loc.longitude),
        width: size + 16,
        height: size + 16,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedLocation =
              _selectedLocation?.id == loc.id ? null : loc;
            });
            HapticFeedback.selectionClick();
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse ring for selected
                  if (isSelected)
                    Container(
                      width: size + 10 + _pulseController.value * 8,
                      height: size + 10 + _pulseController.value * 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF97316).withOpacity(
                            0.3 * (1 - _pulseController.value)),
                      ),
                    ),
                  // Glow ring
                  Container(
                    width: size + 6,
                    height: size + 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.25),
                    ),
                  ),
                  // Main dot
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: size * 0.3,
                        height: size * 0.3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }).toList();

    // Economic center star markers
    if (_showCenters) {
      for (final center in widget.result.economicCenters) {
        markers.add(
          Marker(
            point: LatLng(center.latitude, center.longitude),
            width: 28,
            height: 28,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => CustomPaint(
                painter: _StarPainter(
                  color: AppColors.primaryOrange,
                  pulseValue: _pulseController.value,
                  isPrimary: center.centerType == 'primary',
                ),
              ),
            ),
          ),
        );
      }
    }

    return MarkerLayer(markers: markers);
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
            const Icon(Icons.map_outlined, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peta Persebaran Usaha',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
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
                ),
              ],
            ),
          ),
          // Expand button
          GestureDetector(
            onTap: _openFullscreen,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_full,
                      size: 12, color: AppColors.primaryOrange),
                  const SizedBox(width: 4),
                  Text(
                    'Perluas',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryOrange),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetail(bool isDark) {
    final loc = _selectedLocation!;
    final total = widget.result.statistics.totalUsaha;
    final pct = total > 0 ? (loc.totalUsaha / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.05),
        border: Border.symmetric(
          horizontal:
          BorderSide(color: AppColors.primaryOrange.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on,
              size: 16, color: AppColors.primaryOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loc.province,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${_fmt(loc.totalUsaha)} (${pct.toStringAsFixed(1)}%)',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryOrange),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: [
          _dot(Colors.red.shade400, 'Tinggi', isDark),
          const SizedBox(width: 12),
          _dot(Colors.orange.shade400, 'Sedang', isDark),
          const SizedBox(width: 12),
          _dot(Colors.amber.shade300, 'Rendah', isDark),
          const Spacer(),
          _chip('Pusat', _showCenters,
                  () => setState(() => _showCenters = !_showCenters), isDark),
          const SizedBox(width: 6),
          _chip('Densitas', _showHeatmap,
                  () => setState(() => _showHeatmap = !_showHeatmap), isDark),
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
      const SizedBox(width: 3),
      Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary)),
    ]);
  }

  Widget _chip(String label, bool active, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryOrange.withOpacity(0.12)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.primaryOrange.withOpacity(0.4)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: active
                    ? AppColors.primaryOrange
                    : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary))),
      ),
    );
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

  _StarPainter(
      {required this.color,
        required this.pulseValue,
        required this.isPrimary});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final sz = isPrimary ? 9.0 : 6.5;

    // Pulsing ring
    canvas.drawCircle(
      center,
      sz + 5 + pulseValue * 5,
      Paint()
        ..color = color.withOpacity(0.18 * (1 - pulseValue * 0.4))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Star shape
    final path = ui.Path();
    const pts = 5;
    for (int i = 0; i < pts * 2; i++) {
      final angle = (i * pi / pts) - pi / 2;
      final rad = i.isEven ? sz : sz * 0.44;
      final x = center.dx + rad * cos(angle);
      final y = center.dy + rad * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    // Glow
    canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter o) =>
      o.pulseValue != pulseValue || o.isPrimary != isPrimary;
}