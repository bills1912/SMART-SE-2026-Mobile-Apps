import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/models/spatial_analysis_models.dart';
import 'spatial_map_widget.dart';

/// Full spatial analysis card rendered below an AI message
/// Shows: map, economic centers, spatial insights, statistics
class SpatialAnalysisCard extends StatefulWidget {
  final SpatialAnalysisResult result;

  const SpatialAnalysisCard({super.key, required this.result});

  @override
  State<SpatialAnalysisCard> createState() => _SpatialAnalysisCardState();
}

class _SpatialAnalysisCardState extends State<SpatialAnalysisCard> {
  bool _mapExpanded = true;
  bool _insightsExpanded = true;
  bool _centersExpanded = true;
  bool _statsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 48, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Map ──────────────────────────────────────────────
          _buildSection(
            title: '🗺️ Peta Persebaran',
            subtitle: '${widget.result.locations.length} provinsi dipetakan',
            expanded: _mapExpanded,
            onTap: () => setState(() => _mapExpanded = !_mapExpanded),
            isDark: isDark,
            child: SpatialMapWidget(result: widget.result),
          ),

          const SizedBox(height: 8),

          // ── Economic Centers ─────────────────────────────────
          if (widget.result.economicCenters.isNotEmpty)
            _buildSection(
              title: '⭐ Pusat Ekonomi',
              subtitle: '${widget.result.economicCenters.length} simpul utama teridentifikasi',
              expanded: _centersExpanded,
              onTap: () =>
                  setState(() => _centersExpanded = !_centersExpanded),
              isDark: isDark,
              child: _buildEconomicCenters(isDark),
            ),

          const SizedBox(height: 8),

          // ── Spatial Insights ─────────────────────────────────
          if (widget.result.insights.isNotEmpty)
            _buildSection(
              title: '🔍 Analisis Spasial',
              subtitle: '${widget.result.insights.length} temuan',
              expanded: _insightsExpanded,
              onTap: () =>
                  setState(() => _insightsExpanded = !_insightsExpanded),
              isDark: isDark,
              child: _buildInsights(isDark),
            ),

          const SizedBox(height: 8),

          // ── Statistics ───────────────────────────────────────
          _buildSection(
            title: '📊 Statistik Spasial',
            subtitle: 'Indikator distribusi ekonomi wilayah',
            expanded: _statsExpanded,
            onTap: () => setState(() => _statsExpanded = !_statsExpanded),
            isDark: isDark,
            child: _buildStatistics(isDark),
          ),
        ],
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08);
  }

  // ─── Section wrapper ─────────────────────────────────────────────────────
  Widget _buildSection({
    required String title,
    required String subtitle,
    required bool expanded,
    required VoidCallback onTap,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          subtitle,
                          style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
            child,
          ],
        ],
      ),
    );
  }

  // ─── Economic Centers ────────────────────────────────────────────────────
  Widget _buildEconomicCenters(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: widget.result.economicCenters
            .asMap()
            .entries
            .map((e) => _buildCenterItem(e.value, e.key, isDark))
            .toList(),
      ),
    );
  }

  Widget _buildCenterItem(EconomicCenter center, int index, bool isDark) {
    final maxScore = widget.result.economicCenters
        .map((c) => c.score)
        .reduce(max);
    final barWidth = maxScore > 0 ? center.score / maxScore : 0.0;

    final color = index == 0
        ? AppColors.primaryRed
        : index < 3
        ? AppColors.primaryOrange
        : AppColors.warning;

    final typeLabel = center.centerType == 'primary'
        ? 'Primer'
        : center.centerType == 'secondary'
        ? 'Sekunder'
        : 'Tersier';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        center.name,
                        style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Score bar
          Row(
            children: [
              const SizedBox(width: 30),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: barWidth,
                        backgroundColor: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatNumber(center.totalUsaha)} usaha',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          'Sentralitas: ${center.score.toStringAsFixed(0)}/100',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Description
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 4),
            child: Text(
              center.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
                height: 1.4,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 200.ms)
        .slideX(begin: -0.04);
  }

  // ─── Insights ────────────────────────────────────────────────────────────
  Widget _buildInsights(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: widget.result.insights
            .asMap()
            .entries
            .map((e) => _buildInsightItem(e.value, e.key, isDark))
            .toList(),
      ),
    );
  }

  Widget _buildInsightItem(SpatialInsight insight, int index, bool isDark) {
    final typeData = _insightTypeData(insight.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: typeData.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(typeData.icon, size: 16, color: typeData.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        insight.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Magnitude bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: insight.magnitude.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: typeData.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.5,
                    fontSize: 12,
                  ),
                ),
                if (insight.relatedProvinces.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: insight.relatedProvinces
                        .take(4)
                        .map(
                          (p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeData.color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: typeData.color.withOpacity(0.25)),
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 9,
                            color: typeData.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 200.ms)
        .slideX(begin: -0.04);
  }

  // ─── Statistics ──────────────────────────────────────────────────────────
  Widget _buildStatistics(bool isDark) {
    final stats = widget.result.statistics;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _statTile('Total Provinsi',
                      stats.totalLocations.toString(), Icons.map_outlined, isDark)),
              const SizedBox(width: 8),
              Expanded(
                  child: _statTile('Total Usaha',
                      _formatNumber(stats.totalUsaha), Icons.store_outlined, isDark)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _statTile(
                      'Rata-rata / Provinsi',
                      _formatNumber(stats.averageUsahaPerLocation.toInt()),
                      Icons.calculate_outlined,
                      isDark)),
              const SizedBox(width: 8),
              Expanded(
                  child: _statTile(
                      'Indeks Konsentrasi',
                      '${(stats.spatialConcentrationIndex * 100).toStringAsFixed(0)}%',
                      Icons.hub_outlined,
                      isDark)),
            ],
          ),
          const SizedBox(height: 12),
          _buildConcentrationBar(stats, isDark),
          const SizedBox(height: 12),
          _buildSectorBreakdown(stats, isDark),
        ],
      ),
    );
  }

  Widget _statTile(
      String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryOrange),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryOrange,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcentrationBar(SpatialStatistics stats, bool isDark) {
    // Show top 5 provinces as a stacked bar
    final sorted = stats.usahaByProvince.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = stats.totalUsaha;
    if (total == 0 || sorted.isEmpty) return const SizedBox();

    final top5 = sorted.take(5).toList();
    final colors = [
      AppColors.primaryRed,
      AppColors.primaryOrange,
      AppColors.warning,
      AppColors.success,
      AppColors.info,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribusi Top 5 Provinsi',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: top5.asMap().entries.map((e) {
              final pct = e.value.value / total;
              return Flexible(
                flex: (pct * 1000).round(),
                child: Tooltip(
                  message: '${e.value.key}: ${(pct * 100).toStringAsFixed(1)}%',
                  child: Container(
                    height: 10,
                    color: colors[e.key % colors.length],
                  ),
                ),
              );
            }).toList()
              ..add(Flexible(
                flex: ((1 - top5.fold(0.0, (s, e) => s + e.value / total)) * 1000).round(),
                child: Container(height: 10, color: Colors.grey.shade500),
              )),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: top5.asMap().entries.map((e) {
            final pct = total > 0 ? (e.value.value / total * 100) : 0.0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors[e.key % colors.length],
                      shape: BoxShape.circle,
                    )),
                const SizedBox(width: 4),
                Text(
                  '${e.value.key.split(' ').last} ${pct.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectorBreakdown(SpatialStatistics stats, bool isDark) {
    if (stats.usahaBySector.isEmpty) return const SizedBox();

    final sorted = stats.usahaBySector.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();
    final total = stats.totalUsaha;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sektor Dominan',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...top3.asMap().entries.map((e) {
          final pct = total > 0 ? (e.value.value / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    e.value.key,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.primaryOrange.withOpacity(0.7 - e.key * 0.15),
                      ),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  _InsightTypeData _insightTypeData(String type) {
    switch (type) {
      case 'concentration':
        return _InsightTypeData(
            Icons.hub_outlined, const Color(0xFFE53E3E));
      case 'gap':
        return _InsightTypeData(
            Icons.warning_amber_outlined, const Color(0xFFED8936));
      case 'corridor':
        return _InsightTypeData(
            Icons.route_outlined, const Color(0xFF38A169));
      case 'cluster':
        return _InsightTypeData(
            Icons.scatter_plot_outlined, const Color(0xFF3182CE));
      case 'anomaly':
        return _InsightTypeData(
            Icons.auto_graph, const Color(0xFF805AD5));
      default:
        return _InsightTypeData(
            Icons.lightbulb_outline, AppColors.primaryOrange);
    }
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }
}

class _InsightTypeData {
  final IconData icon;
  final Color color;
  _InsightTypeData(this.icon, this.color);
}