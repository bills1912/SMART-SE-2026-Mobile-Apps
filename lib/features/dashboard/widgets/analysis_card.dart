import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/models/chat_models.dart';

class AnalysisCard extends StatefulWidget {
  final DashboardAnalysisType type;
  final AgentAnalysisResult? result;
  final VoidCallback onRun;
  final void Function(String sessionId) onOpenChat;

  const AnalysisCard({
    super.key,
    required this.type,
    required this.result,
    required this.onRun,
    required this.onOpenChat,
  });

  @override
  State<AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<AnalysisCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = widget.result;
    final hasResult = result != null && result.isSuccess;
    final isLoading = result?.isLoading ?? false;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          _buildHeader(context, isDark, isLoading, hasResult),

          // ── Body (collapsed/expanded) ─────────────────────────────
          if (hasResult && _expanded) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
            _buildBody(context, isDark, result!),
          ],

          // ── Loading state ─────────────────────────────────────────
          if (isLoading) _buildLoadingBody(isDark),

          // ── Error state ───────────────────────────────────────────
          if (result?.isError == true) _buildErrorBody(context, isDark),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, bool isDark, bool isLoading, bool hasResult) {
    return GestureDetector(
      onTap: hasResult ? () => setState(() => _expanded = !_expanded) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: hasResult || isLoading
                    ? AppColors.primaryGradient
                    : null,
                color: hasResult || isLoading
                    ? null
                    : (isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(13),
                border: hasResult || isLoading
                    ? null
                    : Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
              ),
              child: Center(
                child: Text(
                  widget.type.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.type.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.type.description,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Action button
            _buildActionButton(context, isDark, isLoading, hasResult),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, bool isDark, bool isLoading, bool hasResult) {
    if (isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange),
        ),
      );
    }

    if (hasResult) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Open in chat
          GestureDetector(
            onTap: () =>
                widget.onOpenChat(widget.result?.sessionId ?? ''),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded,
                      size: 12, color: AppColors.primaryOrange),
                  SizedBox(width: 3),
                  Text(
                    'Buka',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            _expanded
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            size: 18,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
        ],
      );
    }

    // Not yet run — show "Analisis" button
    return GestureDetector(
      onTap: widget.onRun,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 13, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Analisis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Body (expanded) ──────────────────────────────────────────────────────
  Widget _buildBody(
      BuildContext context, bool isDark, AgentAnalysisResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Message summary
        if (result.message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              result.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.5,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05),

        // First visualization
        if (result.hasVisualizations)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildMiniChart(
                context, isDark, result.visualizations.first),
          ).animate(delay: 100.ms).fadeIn(duration: 250.ms).slideY(begin: 0.05),

        // Insights
        if (result.hasInsights)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildInsightsSummary(context, isDark, result.insights),
          ).animate(delay: 150.ms).fadeIn(duration: 250.ms),

        // Top policy
        if (result.hasPolicies)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: _buildTopPolicy(context, isDark, result.policies.first),
          ).animate(delay: 200.ms).fadeIn(duration: 250.ms),

        if (!result.hasInsights && !result.hasPolicies)
          const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMiniChart(
      BuildContext context, bool isDark, VisualizationConfig viz) {
    final chartData = viz.chartData;
    if (chartData.isEmpty) return const SizedBox();

    final take = chartData.length > 7 ? 7 : chartData.length;
    final data = chartData.take(take).toList();

    double maxVal = 0;
    for (final d in data) {
      final v = (d['value'] ?? 0) is num ? (d['value'] as num).toDouble() : 0.0;
      if (v > maxVal) maxVal = v;
    }
    if (maxVal == 0) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          viz.title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.25,
              barGroups: data.asMap().entries.map((e) {
                final v = (e.value['value'] ?? 0) is num
                    ? (e.value['value'] as num).toDouble()
                    : 0.0;
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: v,
                      gradient: AppColors.primaryGradient,
                      width: 18,
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(5)),
                    ),
                  ],
                );
              }).toList(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: isDark
                      ? AppColors.darkDivider
                      : AppColors.lightDivider,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= data.length) return const Text('');
                      final lbl = (data[idx]['label'] ??
                          data[idx]['name'] ??
                          '')
                          .toString();
                      final short =
                      lbl.length > 6 ? '${lbl.substring(0, 6)}..' : lbl;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          short,
                          style: TextStyle(
                            fontSize: 8,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor:
                  isDark ? AppColors.darkSurface : Colors.white,
                  tooltipRoundedRadius: 6,
                  getTooltipItem: (group, groupIndex, rod, _) {
                    return BarTooltipItem(
                      _fmtVal(rod.toY),
                      TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSummary(
      BuildContext context, bool isDark, List<String> insights) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: AppColors.primaryOrange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 14, color: AppColors.primaryOrange),
              const SizedBox(width: 5),
              Text(
                'Insight Utama (${insights.length})',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...insights.take(2).map((ins) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    ins,
                    style:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTopPolicy(
      BuildContext context, bool isDark, PolicyRecommendation policy) {
    final priorityColor = policy.priority == 'high'
        ? AppColors.error
        : policy.priority == 'medium'
        ? AppColors.warning
        : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.policy_outlined,
                size: 16, color: priorityColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekomendasi Kebijakan',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  policy.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              policy.priority.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: priorityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading & error states ───────────────────────────────────────────────
  Widget _buildLoadingBody(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
          const SizedBox(height: 14),
          Row(
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
                'Agent sedang menganalisis data...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSkeletonLine(isDark, width: double.infinity),
          const SizedBox(height: 6),
          _buildSkeletonLine(isDark, width: 240),
          const SizedBox(height: 6),
          _buildSkeletonLine(isDark, width: 180),
        ],
      ),
    );
  }

  Widget _buildSkeletonLine(bool isDark, {double? width}) {
    return Container(
      width: width,
      height: 11,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        borderRadius: BorderRadius.circular(4),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.08));
  }

  Widget _buildErrorBody(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Gagal mengambil analisis. Tap "Analisis" untuk coba lagi.',
                style: TextStyle(fontSize: 11, color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtVal(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}M';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}Jt';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}Rb';
    return v.toStringAsFixed(0);
  }
}