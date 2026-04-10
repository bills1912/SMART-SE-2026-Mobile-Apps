import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/dashboard_models.dart';

class QuickPromptGrid extends StatelessWidget {
  final void Function(String prompt) onPromptTap;

  const QuickPromptGrid({super.key, required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kQuickPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final p = kQuickPrompts[i];
          return _QuickPromptChip(
            prompt: p,
            index: i,
            onTap: () => onPromptTap(p.prompt),
          );
        },
      ),
    );
  }
}

class _QuickPromptChip extends StatefulWidget {
  final QuickPrompt prompt;
  final int index;
  final VoidCallback onTap;

  const _QuickPromptChip({
    required this.prompt,
    required this.index,
    required this.onTap,
  });

  @override
  State<_QuickPromptChip> createState() => _QuickPromptChipState();
}

class _QuickPromptChipState extends State<_QuickPromptChip> {
  bool _pressed = false;

  // Card accent colors cycling
  static const _colors = [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _colors[widget.index % _colors.length];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(isDark ? 0.35 : 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Category badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(widget.prompt.icon,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.prompt.category,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Label
              Text(
                widget.prompt.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 300 + widget.index * 60))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1);
  }
}