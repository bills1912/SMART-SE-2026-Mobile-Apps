import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/chat_models.dart';

/// VisualizationCard - displays charts from backend VisualizationConfig
/// Backend returns ECharts configuration which we convert to fl_chart
class VisualizationCard extends StatefulWidget {
  final VisualizationConfig visualization;

  const VisualizationCard({
    super.key,
    required this.visualization,
  });

  @override
  State<VisualizationCard> createState() => _VisualizationCardState();
}

class _VisualizationCardState extends State<VisualizationCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 48),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getChartIcon(),
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.visualization.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getChartTypeLabel(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ],
              ),
            ),
          ),

          // Chart Content
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
            Container(
              padding: const EdgeInsets.all(16),
              height: 280,
              child: _buildChart(isDark),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  String _getChartTypeLabel() {
    final chartType = widget.visualization.chartType;
    switch (chartType) {
      case 'bar':
        return 'Bar Chart';
      case 'line':
        return 'Line Chart';
      case 'pie':
        return 'Pie Chart';
      case 'treemap':
        return 'Treemap';
      case 'heatmap':
        return 'Heatmap';
      case 'radar':
        return 'Radar Chart';
      default:
        return 'Chart';
    }
  }

  IconData _getChartIcon() {
    final chartType = widget.visualization.chartType;
    switch (chartType) {
      case 'bar':
        return Icons.bar_chart;
      case 'line':
        return Icons.show_chart;
      case 'pie':
        return Icons.pie_chart;
      case 'treemap':
        return Icons.grid_view;
      case 'heatmap':
        return Icons.grid_on;
      case 'radar':
        return Icons.radar;
      default:
        return Icons.insert_chart;
    }
  }

  Widget _buildChart(bool isDark) {
    final chartType = widget.visualization.chartType;
    final chartData = widget.visualization.chartData;

    if (chartData.isEmpty) {
      return _buildEmptyState(isDark);
    }

    switch (chartType) {
      case 'bar':
        return _buildBarChart(isDark, chartData);
      case 'line':
        return _buildLineChart(isDark, chartData);
      case 'pie':
        return _buildPieChart(isDark, chartData);
      case 'treemap':
        return _buildTreemapFallback(isDark, chartData);
      case 'heatmap':
        return _buildHeatmapFallback(isDark);
      case 'radar':
        return _buildRadarFallback(isDark, chartData);
      default:
        return _buildBarChart(isDark, chartData);
    }
  }

  Widget _buildBarChart(bool isDark, List<Map<String, dynamic>> data) {
    final barGroups = <BarChartGroupData>[];
    final labels = <String>[];

    for (int i = 0; i < data.length && i < 15; i++) {
      final item = data[i];
      final value = _getValue(item);
      final label = _getLabel(item, i);

      labels.add(label);
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              gradient: AppColors.primaryGradient,
              width: data.length > 10 ? 16 : 24,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    final maxValue = _getMaxValue(data);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        _truncateLabel(labels[index], 10),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatValue(value),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // FIX: Using tooltipBgColor instead of getTooltipColor for broader compatibility
            // If you're using fl_chart >= 0.55.0, you can use getTooltipColor
            // For older versions, use tooltipBgColor
            tooltipBgColor: isDark ? AppColors.darkSurface : Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${labels[groupIndex]}\n${_formatValue(rod.toY)}',
                TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(bool isDark, List<Map<String, dynamic>> data) {
    final spots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 0; i < data.length && i < 20; i++) {
      final item = data[i];
      final value = _getValue(item);
      final label = _getLabel(item, i);

      labels.add(label);
      spots.add(FlSpot(i.toDouble(), value));
    }

    final maxValue = _getMaxValue(data);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (data.length / 5).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _truncateLabel(labels[index], 8),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatValue(value),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxValue * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: AppColors.primaryGradient,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: data.length <= 10,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primaryOrange,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryOrange.withOpacity(0.3),
                  AppColors.primaryOrange.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // FIX: Using tooltipBgColor instead of getTooltipColor for broader compatibility
            tooltipBgColor: isDark ? AppColors.darkSurface : Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                return LineTooltipItem(
                  '${labels[index]}\n${_formatValue(spot.y)}',
                  TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(bool isDark, List<Map<String, dynamic>> data) {
    final colors = [
      const Color(0xFFE74C3C), // Red
      const Color(0xFF3498DB), // Blue
      const Color(0xFF2ECC71), // Green
      const Color(0xFFF39C12), // Orange
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF1ABC9C), // Teal
      const Color(0xFFE67E22), // Dark Orange
      const Color(0xFF34495E), // Dark Blue
    ];

    final sections = <PieChartSectionData>[];
    double total = 0;

    // Calculate total
    for (final item in data) {
      total += _getValue(item);
    }

    for (int i = 0; i < data.length && i < 8; i++) {
      final item = data[i];
      final value = _getValue(item);
      final percentage = total > 0 ? (value / total * 100) : 0;

      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: value,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Add "Others" if more than 8 items
    if (data.length > 8) {
      double othersTotal = 0;
      for (int i = 8; i < data.length; i++) {
        othersTotal += _getValue(data[i]);
      }
      final percentage = total > 0 ? (othersTotal / total * 100) : 0;
      sections.add(
        PieChartSectionData(
          color: const Color(0xFF95A5A6),
          value: othersTotal,
          title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 35,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...data.take(8).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final label = _getLabel(item, index);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _truncateLabel(label, 15),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (data.length > 8)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF95A5A6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lainnya',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Fallback for treemap - show as horizontal bar chart
  Widget _buildTreemapFallback(bool isDark, List<Map<String, dynamic>> data) {
    return _buildBarChart(isDark, data);
  }

  /// Fallback for heatmap - show message
  Widget _buildHeatmapFallback(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_on,
            size: 48,
            color: AppColors.primaryOrange.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Heatmap tersedia di web app',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
          Text(
            'Gunakan browser untuk melihat visualisasi lengkap',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Fallback for radar chart - show as bar chart
  Widget _buildRadarFallback(bool isDark, List<Map<String, dynamic>> data) {
    return _buildBarChart(isDark, data);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 48,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Data tidak tersedia',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  double _getValue(Map<String, dynamic> item) {
    final value = item['value'] ?? item['y'] ?? 0;
    return (value is num) ? value.toDouble() : 0.0;
  }

  String _getLabel(Map<String, dynamic> item, int index) {
    return (item['name'] ?? item['label'] ?? item['x'] ?? 'Item $index').toString();
  }

  double _getMaxValue(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 100;

    double max = 0;
    for (final item in data) {
      final value = _getValue(item);
      if (value > max) max = value;
    }

    return max > 0 ? max : 100;
  }

  String _truncateLabel(String label, int maxLength) {
    if (label.length <= maxLength) return label;
    return '${label.substring(0, maxLength - 2)}..';
  }

  String _formatValue(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }
}