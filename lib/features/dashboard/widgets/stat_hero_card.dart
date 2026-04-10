import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class StatHeroCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final String value;
  final double? growth;
  final bool isLoading;
  final Color accentColor;
  final bool compact;

  const StatHeroCard({
    super.key,
    required this.index,
    required this.icon,
    required this.label,
    required this.value,
    required this.growth,
    required this.isLoading,
    required this.accentColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withOpacity(isDark ? 0.3 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLoading
          ? _buildSkeleton(isDark)
          : _buildContent(context, isDark),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1);
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: compact ? 32 : 38,
              height: compact ? 32 : 38,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
              Icon(icon, color: accentColor, size: compact ? 16 : 20),
            ),
            const Spacer(),
            if (growth != null) _buildGrowthBadge(),
          ],
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          value,
          style: TextStyle(
            fontSize: compact ? 22 : 28,
            fontWeight: FontWeight.w800,
            color: accentColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthBadge() {
    final isPositive = (growth ?? 0) >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${growth!.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    final shimmerColor =
    isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: compact ? 22 : 28,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.1));
  }
}