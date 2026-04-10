import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/chat_models.dart';
import 'pdf_export_sheet.dart';

/// Compact PDF export button — drop this anywhere you have a ChatSession.
/// Usage:
///   PdfExportButton(session: chatProvider.currentSession)
class PdfExportButton extends StatelessWidget {
  final ChatSession? session;
  final bool compact; // true = icon only, false = icon + label

  const PdfExportButton({
    super.key,
    required this.session,
    this.compact = true,
  });

  bool get _canExport {
    if (session == null) return false;
    final msgs = session!.messages
        .where((m) => !m.id.startsWith('welcome_'))
        .toList();
    return msgs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return Tooltip(
        message: _canExport ? 'Export PDF' : 'Belum ada pesan',
        child: IconButton(
          onPressed: _canExport
              ? () => PdfExportSheet.show(context, session: session!)
              : null,
          icon: Icon(
            Icons.picture_as_pdf_rounded,
            size: 22,
            color: _canExport
                ? AppColors.primaryOrange
                : (isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary),
          ),
        ),
      );
    }

    // Full button variant (for sidebar / settings)
    return GestureDetector(
      onTap: _canExport
          ? () => PdfExportSheet.show(context, session: session!)
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _canExport ? 1.0 : 0.4,
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: _canExport ? AppColors.primaryGradient : null,
            color: _canExport
                ? null
                : (isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface),
            borderRadius: BorderRadius.circular(12),
            border: _canExport
                ? null
                : Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder),
            boxShadow: _canExport
                ? [
              BoxShadow(
                color: AppColors.primaryRed.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.picture_as_pdf_rounded,
                size: 18,
                color: _canExport
                    ? Colors.white
                    : (isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary),
              ),
              const SizedBox(width: 8),
              Text(
                'Export PDF',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _canExport
                      ? Colors.white
                      : (isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}