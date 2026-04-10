import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../core/models/chat_models.dart';
import '../../core/services/pdf_export_service.dart';

/// Shows a bottom-sheet export panel, then triggers PDF generation.
/// Call via: PdfExportSheet.show(context, session: session)
class PdfExportSheet extends StatefulWidget {
  final ChatSession session;

  const PdfExportSheet({super.key, required this.session});

  static Future<void> show(BuildContext context,
      {required ChatSession session}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PdfExportSheet(session: session),
    );
  }

  @override
  State<PdfExportSheet> createState() => _PdfExportSheetState();
}

class _PdfExportSheetState extends State<PdfExportSheet> {
  _ExportState _state = _ExportState.idle;
  String _statusMessage = '';
  double _progress = 0;
  Uint8List? _pdfBytes;
  String? _savedPath;

  // Export options
  bool _includeTranscript = true;
  bool _includePolicies = true;
  bool _includeInsights = true;

  ChatSession get _session => widget.session;
  int get _msgCount =>
      _session.messages.where((m) => !m.id.startsWith('welcome_')).length;
  int get _policyCount =>
      _session.messages.expand((m) => m.policies ?? []).length;
  int get _insightCount =>
      _session.messages.expand((m) => m.insights ?? []).length;

  Future<void> _generate() async {
    setState(() {
      _state = _ExportState.generating;
      _progress = 0.1;
      _statusMessage = 'Mempersiapkan data sesi...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _progress = 0.3;
        _statusMessage = 'Membangun halaman cover...';
      });

      final service = PdfExportService();

      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _progress = 0.5;
        _statusMessage = 'Menyusun transkrip percakapan...';
      });

      final bytes =
      await service.generateSessionReport(_session);

      setState(() {
        _progress = 0.8;
        _statusMessage = 'Menyimpan file PDF...';
      });

      // Save to temp dir
      final dir = await getTemporaryDirectory();
      final filename =
          'SE2026_${_session.title.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      setState(() {
        _progress = 1.0;
        _statusMessage = 'Selesai!';
        _pdfBytes = bytes;
        _savedPath = file.path;
        _state = _ExportState.done;
      });
    } catch (e) {
      setState(() {
        _state = _ExportState.error;
        _statusMessage = 'Gagal membuat PDF: ${e.toString()}';
      });
    }
  }

  Future<void> _share() async {
    if (_pdfBytes == null) return;
    final service = PdfExportService();
    final filename =
        'SE2026_${_session.title.replaceAll(RegExp(r'[^\w]'), '_')}.pdf';
    await service.printOrShare(_pdfBytes!, filename);
  }

  Future<void> _preview() async {
    if (_pdfBytes == null) return;
    final service = PdfExportService();
    await service.previewPdf(_pdfBytes!);
  }

  Future<void> _openFile() async {
    if (_savedPath == null) return;
    await OpenFile.open(_savedPath!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Export Laporan PDF',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      'Laporan formal siap cetak / bagikan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),

          const SizedBox(height: 20),

          // Session info chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(
                  isDark ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryOrange.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _session.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_msgCount pesan  ·  $_policyCount rekomendasi  ·  $_insightCount insight',
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
              ],
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 16),

          // Options (only when idle)
          if (_state == _ExportState.idle) ...[
            Text('Konten yang disertakan:',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _OptionToggle(
              label: 'Transkrip Percakapan',
              icon: Icons.chat_bubble_outline_rounded,
              value: _includeTranscript,
              onChanged: (v) =>
                  setState(() => _includeTranscript = v),
              isDark: isDark,
            ),
            _OptionToggle(
              label: 'Rekomendasi Kebijakan ($_policyCount)',
              icon: Icons.policy_outlined,
              value: _includePolicies,
              onChanged: (v) =>
                  setState(() => _includePolicies = v),
              isDark: isDark,
            ),
            _OptionToggle(
              label: 'Key Insights ($_insightCount)',
              icon: Icons.lightbulb_outline_rounded,
              value: _includeInsights,
              onChanged: (v) =>
                  setState(() => _includeInsights = v),
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Generate button
            _GradientButton(
              onTap: _generate,
              label: 'Buat PDF',
              icon: Icons.auto_awesome,
            ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
          ],

          // Generating state
          if (_state == _ExportState.generating) ...[
            const SizedBox(height: 8),
            _ProgressWidget(
                progress: _progress, message: _statusMessage),
          ],

          // Done state
          if (_state == _ExportState.done) ...[
            _SuccessBanner(isDark: isDark)
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(
                begin: const Offset(0.95, 0.95),
                curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OutlineButton(
                    onTap: _preview,
                    label: 'Preview',
                    icon: Icons.preview_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OutlineButton(
                    onTap: _openFile,
                    label: 'Buka',
                    icon: Icons.open_in_new_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _GradientButton(
                    onTap: _share,
                    label: 'Bagikan / Cetak',
                    icon: Icons.share_rounded,
                  ),
                ),
              ],
            ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
          ],

          // Error state
          if (_state == _ExportState.error) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _GradientButton(
                onTap: _generate,
                label: 'Coba Lagi',
                icon: Icons.refresh_rounded),
          ],
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

enum _ExportState { idle, generating, done, error }

class _OptionToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _OptionToggle({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? AppColors.primaryOrange.withOpacity(isDark ? 0.12 : 0.06)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value
                ? AppColors.primaryOrange.withOpacity(0.3)
                : (isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: value
                    ? AppColors.primaryOrange
                    : (isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight:
                  value ? FontWeight.w600 : FontWeight.normal,
                  color: value
                      ? (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary)
                      : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? AppColors.primaryOrange : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value
                      ? AppColors.primaryOrange
                      : (isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressWidget extends StatelessWidget {
  final double progress;
  final String message;

  const _ProgressWidget(
      {required this.progress, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                const AlwaysStoppedAnimation(AppColors.primaryOrange),
                value: progress < 1 ? null : 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor:
            isDark ? AppColors.darkBorder : AppColors.lightBorder,
            valueColor:
            const AlwaysStoppedAnimation(AppColors.primaryOrange),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final bool isDark;
  const _SuccessBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PDF Berhasil Dibuat!',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
                Text(
                  'Siap untuk dicetak, dibagikan, atau disimpan.',
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
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  const _GradientButton(
      {required this.onTap, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final bool isDark;

  const _OutlineButton(
      {required this.onTap,
        required this.label,
        required this.icon,
        required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
            isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          color: isDark ? AppColors.darkSurface : Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}