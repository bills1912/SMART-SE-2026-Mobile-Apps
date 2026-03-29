import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  BusinessLocation? _selectedLocation;
  bool _showCenters = true;
  bool _showHeatmap = false;

  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _startOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _startScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
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
            onScaleStart: (d) {
              _startFocalPoint = d.focalPoint;
              _startOffset = _offset;
              _startScale = _scale;
            },
            onScaleUpdate: (d) {
              setState(() {
                _scale = (_startScale * d.scale).clamp(0.7, 4.0);
                _offset = _startOffset + (d.focalPoint - _startFocalPoint);
              });
            },
            onDoubleTap: () => setState(() {
              _scale = 1.0;
              _offset = Offset.zero;
            }),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
              child: Container(
                height: 220,
                width: double.infinity,
                color: isDark
                    ? const Color(0xFF0D1117)
                    : const Color(0xFFDDE8F4),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Grid
                    CustomPaint(painter: _GridPainter(isDark: isDark)),
                    // Map dots
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => CustomPaint(
                        painter: _IndonesiaMapPainter(
                          locations: widget.result.locations,
                          economicCenters: widget.result.economicCenters,
                          selectedLocation: _selectedLocation,
                          showCenters: _showCenters,
                          showHeatmap: _showHeatmap,
                          isDark: isDark,
                          scale: _scale,
                          offset: _offset,
                          pulseValue: _pulseController.value,
                        ),
                      ),
                    ),
                    // Tap overlay info
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.open_in_full, size: 10, color: Colors.white70),
                            SizedBox(width: 4),
                            Text('Tap untuk peta penuh',
                                style: TextStyle(
                                    fontSize: 9, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                    // Province count
                    Positioned(
                      top: 8, left: 8,
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
                border: Border.all(
                    color: AppColors.primaryOrange.withOpacity(0.3)),
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
          horizontal: BorderSide(
              color: AppColors.primaryOrange.withOpacity(0.2)),
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
            style: TextStyle(
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

// ─── CustomPainters ────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color =
      (isDark ? Colors.white : Colors.blueGrey).withOpacity(0.06)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) => false;
}

/// Shared painter — used by both compact card and fullscreen view.
class _IndonesiaMapPainter extends CustomPainter {
  final List<BusinessLocation> locations;
  final List<EconomicCenter> economicCenters;
  final BusinessLocation? selectedLocation;
  final bool showCenters;
  final bool showHeatmap;
  final bool isDark;
  final double scale;
  final Offset offset;
  final double pulseValue;

  _IndonesiaMapPainter({
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
  static const double _pad = 20.0;

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
    final maxU = locations.map((l) => l.totalUsaha).reduce(max);
    if (maxU == 0) return;

    if (showHeatmap) _drawHeatmap(canvas, size, maxU);
    _drawCorridors(canvas, size);
    for (final loc in locations) _drawDot(canvas, size, loc, maxU);
    if (showCenters) {
      for (final c in economicCenters) _drawCenter(canvas, size, c);
    }
  }

  void _drawHeatmap(Canvas canvas, Size size, int maxU) {
    for (final loc in locations) {
      if (loc.totalUsaha == 0) continue;
      final pos = project(loc.latitude, loc.longitude, size);
      final intensity = loc.totalUsaha / maxU;
      final r = 16.0 + intensity * 36.0;
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFEF4444).withOpacity(0.28 * intensity),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: pos, radius: r)),
      );
    }
  }

  void _drawCorridors(Canvas canvas, Size size) {
    if (locations.length < 2) return;
    final top = ([...locations]
      ..sort((a, b) => b.totalUsaha.compareTo(a.totalUsaha)))
        .take(6)
        .toList();
    final p = Paint()
      ..color = const Color(0xFFF97316).withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < top.length - 1; i++) {
      canvas.drawLine(
        project(top[i].latitude, top[i].longitude, size),
        project(top[i + 1].latitude, top[i + 1].longitude, size),
        p,
      );
    }
  }

  void _drawDot(Canvas canvas, Size size, BusinessLocation loc, int maxU) {
    if (loc.totalUsaha == 0) return; // skip empty provinces
    final pos = project(loc.latitude, loc.longitude, size);
    final ratio = loc.totalUsaha / maxU;
    final isSelected = selectedLocation?.id == loc.id;
    final r = 3.5 + ratio * 13.0;

    final color = ratio > 0.5
        ? const Color(0xFFE53E3E)
        : ratio > 0.2
        ? const Color(0xFFED8936)
        : const Color(0xFFF6C90E);

    // Pulse ring for selected
    if (isSelected) {
      canvas.drawCircle(
        pos,
        r + 5 + pulseValue * 7,
        Paint()
          ..color = const Color(0xFFF97316)
              .withOpacity(0.25 * (1 - pulseValue)),
      );
    }

    // Glow
    canvas.drawCircle(pos, r + 3,
        Paint()..color = color.withOpacity(0.22));
    // Fill
    canvas.drawCircle(pos, r, Paint()..color = color);
    // White core
    canvas.drawCircle(pos, r * 0.28,
        Paint()..color = Colors.white.withOpacity(0.75));

    // Label for large provinces
    if (ratio > 0.45 || isSelected) {
      final parts = loc.province.split(' ');
      final short = parts.length >= 2 ? parts.last : loc.province;
      _drawLabel(canvas, pos, short, r, isSelected);
    }
  }

  void _drawLabel(
      Canvas canvas, Offset pos, String text, double r, bool bold) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: bold ? 10 : 9,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          shadows: [
            Shadow(
              color: isDark
                  ? Colors.black.withOpacity(0.9)
                  : Colors.white.withOpacity(0.9),
              blurRadius: 3,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + r + 3));
  }

  void _drawCenter(Canvas canvas, Size size, EconomicCenter c) {
    final pos = project(c.latitude, c.longitude, size);
    final isPrimary = c.centerType == 'primary';
    final r = isPrimary ? 7.0 : 5.0;

    // Pulsing ring
    canvas.drawCircle(
      pos,
      r + 5 + pulseValue * 5,
      Paint()
        ..color = const Color(0xFFF97316)
            .withOpacity(0.18 * (1 - pulseValue * 0.4))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _drawStar(canvas, pos, r, const Color(0xFFF97316));
  }

  void _drawStar(Canvas canvas, Offset c, double sz, Color color) {
    final path = Path();
    const pts = 5;
    for (int i = 0; i < pts * 2; i++) {
      final angle = (i * pi / pts) - pi / 2;
      final rad = i.isEven ? sz : sz * 0.44;
      final x = c.dx + rad * cos(angle);
      final y = c.dy + rad * sin(angle);
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
  bool shouldRepaint(_IndonesiaMapPainter o) =>
      o.selectedLocation != selectedLocation ||
          o.pulseValue != pulseValue ||
          o.scale != scale ||
          o.offset != offset ||
          o.showCenters != showCenters ||
          o.showHeatmap != showHeatmap;
}

// Export painter so fullscreen can reuse it
class IndonesiaMapPainter extends _IndonesiaMapPainter {
  IndonesiaMapPainter({
    required super.locations,
    required super.economicCenters,
    required super.selectedLocation,
    required super.showCenters,
    required super.showHeatmap,
    required super.isDark,
    required super.scale,
    required super.offset,
    required super.pulseValue,
  });

  Offset projectPublic(double lat, double lng, Size size) =>
      project(lat, lng, size);
}