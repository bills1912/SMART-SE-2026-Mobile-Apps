import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/dashboard_provider.dart';

class RecentAnalysesList extends StatelessWidget {
  final void Function(String sessionId) onSessionTap;

  const RecentAnalysesList({super.key, required this.onSessionTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<DashboardProvider>();

    if (provider.isRecentLoading) {
      return _buildSkeleton(isDark);
    }

    if (provider.recentAnalyses.isEmpty) {
      return _buildEmpty(context, isDark);
    }

    return Column(
      children: provider.recentAnalyses.asMap().entries.map((e) {
        final session = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _RecentItem(
            title: session.title,
            date: session.updatedAt,
            messageCount: session.messageCount,
            onTap: () => onSessionTap(session.sessionId),
            isDark: isDark,
          ),
        )
            .animate(delay: Duration(milliseconds: e.key * 60))
            .fadeIn(duration: 250.ms)
            .slideX(begin: 0.05);
      }).toList(),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return Column(
      children: List.generate(
        3,
            (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
              duration: 1200.ms,
              color: Colors.white.withOpacity(0.05)),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 36,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada riwayat analisis',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentItem extends StatefulWidget {
  final String title;
  final DateTime date;
  final int messageCount;
  final VoidCallback onTap;
  final bool isDark;

  const _RecentItem({
    required this.title,
    required this.date,
    required this.messageCount,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_RecentItem> createState() => _RecentItemState();
}

class _RecentItemState extends State<_RecentItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryRed.withOpacity(0.15),
                      AppColors.primaryOrange.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  size: 18,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style:
                      Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: widget.isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          DateFormat('dd MMM, HH:mm').format(widget.date),
                          style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: widget.isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                            fontSize: 10,
                          ),
                        ),
                        if (widget.messageCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.messageCount} pesan',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                              color: widget.isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: widget.isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}