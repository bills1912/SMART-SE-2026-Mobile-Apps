import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/chat_models.dart';

/// PdfExportService — Fixed version
/// Fixes:
///   1. PdfColors.white  → PdfColor.fromInt(0xFFFFFFFF)
///   2. theme.bold/base  → pass pw.Font instances directly
///   3. Expanded helper  → removed; use pw.Expanded inline
class PdfExportService {
  // ─── Colors ──────────────────────────────────────────────────────────────────
  static const _red          = PdfColor.fromInt(0xFFEF4444);
  static const _orange       = PdfColor.fromInt(0xFFF97316);
  static const _textDark     = PdfColor.fromInt(0xFF1F2937);
  static const _textMid      = PdfColor.fromInt(0xFF6B7280);
  static const _textLight    = PdfColor.fromInt(0xFF9CA3AF);
  static const _border       = PdfColor.fromInt(0xFFE5E7EB);
  static const _successGreen = PdfColor.fromInt(0xFF10B981);
  static const _warningAmber = PdfColor.fromInt(0xFFF59E0B);
  static const _errorRed     = PdfColor.fromInt(0xFFEF4444);
  static const _white        = PdfColor.fromInt(0xFFFFFFFF);
  static const _white70      = PdfColor.fromInt(0xB3FFFFFF);
  static const _white24      = PdfColor.fromInt(0x3DFFFFFF);
  static const _bgLight      = PdfColor.fromInt(0xFFFAFAFA);
  static const _bgGrey       = PdfColor.fromInt(0xFFF3F4F6);
  static const _bgWarmLight  = PdfColor.fromInt(0xFFFFF7ED);
  static const _borderWarm   = PdfColor.fromInt(0xFFFED7AA);
  static const _bgBodyText   = PdfColor.fromInt(0xFFF9FAFB);
  static const _purple       = PdfColor.fromInt(0xFF8B5CF6);
  static const _blue         = PdfColor.fromInt(0xFF3B82F6);

  // ─── Public API ──────────────────────────────────────────────────────────────

  Future<Uint8List> generateSessionReport(ChatSession session) async {
    final doc = pw.Document(
      title: 'Laporan Analisis SE2026 — ${session.title}',
      author: 'SMART SE2026 Agentic AI',
      subject: 'Sensus Ekonomi Indonesia 2026',
      creator: 'BPS · SMART SE2026',
    );

    // Load fonts and store as plain variables (NOT via theme.bold etc.)
    final fReg  = await PdfGoogleFonts.notoSansRegular();
    final fBold = await PdfGoogleFonts.notoSansBold();
    final fItal = await PdfGoogleFonts.notoSansItalic();

    final theme = pw.ThemeData.withFont(
      base: fReg, bold: fBold, italic: fItal, boldItalic: fBold,
    );

    final messages    = session.messages.where((m) => !m.id.startsWith('welcome_')).toList();
    final aiMessages  = messages.where((m) => m.isAI).toList();
    final allInsights = aiMessages.expand((m) => m.insights ?? <String>[]).toList();
    final allPolicies = aiMessages.expand((m) => m.policies ?? <PolicyRecommendation>[]).toList();

    doc.addPage(_coverPage(theme, fBold, fReg, session, messages));
    doc.addPage(_summaryPage(theme, fBold, fReg, fItal, session, messages, allInsights, allPolicies));
    if (messages.isNotEmpty)  doc.addPage(_transcriptPages(theme, fBold, fReg, fItal, messages));
    if (allPolicies.isNotEmpty) doc.addPage(_policyPages(theme, fBold, fReg, fItal, allPolicies));
    if (allInsights.isNotEmpty) doc.addPage(_insightPages(theme, fBold, fReg, allInsights));
    doc.addPage(_closingPage(theme, fBold, fReg, session));

    return doc.save();
  }

  Future<void> printOrShare(Uint8List bytes, String filename) =>
      Printing.sharePdf(bytes: bytes, filename: filename);

  Future<void> previewPdf(Uint8List bytes) =>
      Printing.layoutPdf(onLayout: (_) async => bytes);

  // ─── Cover ───────────────────────────────────────────────────────────────────

  pw.Page _coverPage(pw.ThemeData theme, pw.Font fBold, pw.Font fReg,
      ChatSession session, List<ChatMessage> messages) {
    final now      = DateFormat('dd MMMM yyyy').format(DateTime.now());
    final msgCount = messages.length;
    final aiCount  = messages.where((m) => m.isAI).length;
    final vizCount = messages.where((m) => m.hasVisualizations).length;
    final polCount = messages.expand((m) => m.policies ?? []).length;

    return pw.Page(
      theme: theme, pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Stack(children: [
        pw.Positioned(top: 0, left: 0, right: 0,
            child: pw.Container(height: 320,
                decoration: const pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                        begin: pw.Alignment.topLeft, end: pw.Alignment.bottomRight,
                        colors: [_red, _orange])))),
        pw.Positioned(top: 280, left: 0, right: 0, bottom: 0,
            child: pw.Container(color: _white)),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 56),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            // Logo
            pw.Row(children: [
              pw.Container(width: 44, height: 44,
                  decoration: pw.BoxDecoration(color: _white, borderRadius: pw.BorderRadius.circular(12)),
                  child: pw.Center(child: pw.Text('SE',
                      style: pw.TextStyle(font: fBold, fontSize: 16, color: _red)))),
              pw.SizedBox(width: 12),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('SMART SE2026',
                    style: pw.TextStyle(font: fBold, fontSize: 16, color: _white, letterSpacing: 1.5)),
                pw.Text('Agentic AI for Analysis',
                    style: pw.TextStyle(font: fReg, fontSize: 9, color: _white70)),
              ]),
              pw.Spacer(),
              pw.Text('LAPORAN RESMI',
                  style: pw.TextStyle(font: fBold, fontSize: 8, color: _white, letterSpacing: 2)),
            ]),
            pw.SizedBox(height: 48),
            pw.Text('Laporan Analisis',
                style: pw.TextStyle(font: fReg, fontSize: 18, color: _white70)),
            pw.SizedBox(height: 6),
            pw.Text('Sensus Ekonomi\nIndonesia 2026',
                style: pw.TextStyle(font: fBold, fontSize: 36, color: _white, lineSpacing: 4)),
            pw.SizedBox(height: 16),
            pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: pw.BoxDecoration(color: _white24, borderRadius: pw.BorderRadius.circular(20)),
                child: pw.Text(session.title,
                    style: pw.TextStyle(font: fReg, fontSize: 11, color: _white))),
            pw.SizedBox(height: 60),
            pw.Row(children: [
              _coverStat(fBold, fReg, '$msgCount', 'Total Pesan'),
              pw.SizedBox(width: 24),
              _coverStat(fBold, fReg, '$aiCount', 'Respons AI'),
              pw.SizedBox(width: 24),
              _coverStat(fBold, fReg, '$vizCount', 'Visualisasi'),
              pw.SizedBox(width: 24),
              _coverStat(fBold, fReg, '$polCount', 'Rekomendasi'),
            ]),
            pw.SizedBox(height: 48),
            pw.Divider(color: _border),
            pw.SizedBox(height: 20),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              _metaItem(fBold, fReg, 'Tanggal Dibuat', now),
              _metaItem(fBold, fReg, 'Sumber Data', 'BPS — Sensus Ekonomi 2026'),
              _metaItem(fBold, fReg, 'Dianalisis Oleh', 'SMART SE2026 AI'),
            ]),
            pw.Spacer(),
            pw.Text(
                'Dokumen ini dibuat secara otomatis oleh sistem SMART SE2026. '
                    'Data bersumber dari Sensus Ekonomi 2026, Badan Pusat Statistik.',
                style: pw.TextStyle(font: fReg, fontSize: 8, color: _textLight)),
          ]),
        ),
      ]),
    );
  }

  pw.Widget _coverStat(pw.Font fBold, pw.Font fReg, String v, String l) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(v, style: pw.TextStyle(font: fBold, fontSize: 28, color: _red)),
        pw.Text(l, style: pw.TextStyle(font: fReg,  fontSize: 9,  color: _textMid)),
      ]);

  pw.Widget _metaItem(pw.Font fBold, pw.Font fReg, String l, String v) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(l, style: pw.TextStyle(font: fReg,  fontSize: 8, color: _textLight)),
        pw.SizedBox(height: 2),
        pw.Text(v, style: pw.TextStyle(font: fBold, fontSize: 9, color: _textDark)),
      ]);

  // ─── Summary ─────────────────────────────────────────────────────────────────

  pw.Page _summaryPage(pw.ThemeData theme, pw.Font fBold, pw.Font fReg, pw.Font fItal,
      ChatSession session, List<ChatMessage> messages,
      List<String> insights, List<PolicyRecommendation> policies) {
    final highP = policies.where((p) => p.priority == 'high').length;
    final medP  = policies.where((p) => p.priority == 'medium').length;
    final lowP  = policies.where((p) => p.priority == 'low').length;

    return pw.Page(
      theme: theme, pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _header(fBold, fReg, 'Ringkasan Eksekutif', '02'),
        pw.SizedBox(height: 24),
        // Session box
        pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
                color: _bgWarmLight, borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: _borderWarm)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Sesi Analisis', style: pw.TextStyle(font: fBold, fontSize: 10, color: _orange)),
              pw.SizedBox(height: 6),
              pw.Text(session.title, style: pw.TextStyle(font: fBold, fontSize: 14, color: _textDark)),
              pw.SizedBox(height: 4),
              pw.Text(
                  'Dibuat: ${DateFormat('dd MMM yyyy HH:mm').format(session.createdAt)}  ·  '
                      'Diperbarui: ${DateFormat('dd MMM yyyy HH:mm').format(session.updatedAt)}',
                  style: pw.TextStyle(font: fReg, fontSize: 8, color: _textMid)),
            ])),
        pw.SizedBox(height: 20),
        // Stats row — use pw.Expanded directly (no helper wrapper)
        pw.Row(children: [
          pw.Expanded(child: _statBox(fBold, fReg, '${messages.length}', 'Total Pesan', _orange)),
          pw.SizedBox(width: 12),
          pw.Expanded(child: _statBox(fBold, fReg, '${insights.length}', 'Insights', _purple)),
          pw.SizedBox(width: 12),
          pw.Expanded(child: _statBox(fBold, fReg, '${policies.length}', 'Rekomendasi', _successGreen)),
          pw.SizedBox(width: 12),
          pw.Expanded(child: _statBox(fBold, fReg,
              '${messages.where((m) => m.hasVisualizations).length}', 'Visualisasi', _blue)),
        ]),
        pw.SizedBox(height: 20),
        // Priority
        if (policies.isNotEmpty) ...[
          pw.Text('Distribusi Prioritas Rekomendasi',
              style: pw.TextStyle(font: fBold, fontSize: 11, color: _textDark)),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _prioBadge(fBold, fReg, 'TINGGI', highP, _errorRed),
            pw.SizedBox(width: 10),
            _prioBadge(fBold, fReg, 'SEDANG', medP, _warningAmber),
            pw.SizedBox(width: 10),
            _prioBadge(fBold, fReg, 'RENDAH', lowP, _successGreen),
          ]),
          pw.SizedBox(height: 20),
        ],
        // Insights preview
        if (insights.isNotEmpty) ...[
          pw.Text('Insight Utama', style: pw.TextStyle(font: fBold, fontSize: 11, color: _textDark)),
          pw.SizedBox(height: 10),
          ...insights.take(4).map((ins) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Container(margin: const pw.EdgeInsets.only(top: 5),
                    width: 5, height: 5,
                    decoration: pw.BoxDecoration(color: _orange, shape: pw.BoxShape.circle)),
                pw.SizedBox(width: 8),
                pw.Expanded(child: pw.Text(ins,
                    style: pw.TextStyle(font: fReg, fontSize: 10, color: _textDark, lineSpacing: 2))),
              ]))),
        ],
        pw.Spacer(),
        _footer(fReg, session.title),
      ]),
    );
  }

  pw.Widget _statBox(pw.Font fBold, pw.Font fReg, String v, String l, PdfColor c) =>
      pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: c.shade(0.3)),
              borderRadius: pw.BorderRadius.circular(8),
              color: c.shade(0.05)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(v, style: pw.TextStyle(font: fBold, fontSize: 22, color: c)),
            pw.Text(l, style: pw.TextStyle(font: fReg,  fontSize: 8,  color: _textMid)),
          ]));

  pw.Widget _prioBadge(pw.Font fBold, pw.Font fReg, String l, int count, PdfColor c) =>
      pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
              color: c.shade(0.08), borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: c.shade(0.3))),
          child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
            pw.Container(width: 6, height: 6,
                decoration: pw.BoxDecoration(color: c, shape: pw.BoxShape.circle)),
            pw.SizedBox(width: 6),
            pw.Text('$count $l', style: pw.TextStyle(font: fBold, fontSize: 9, color: c)),
          ]));

  // ─── Transcript ───────────────────────────────────────────────────────────────

  pw.Page _transcriptPages(pw.ThemeData theme, pw.Font fBold, pw.Font fReg,
      pw.Font fItal, List<ChatMessage> messages) =>
      pw.MultiPage(
          theme: theme, pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
          header: (ctx) => _header(fBold, fReg, 'Transkrip Percakapan', '03'),
          footer: (ctx) => _multiFooter(fReg, ctx),
          build: (ctx) => [
            pw.SizedBox(height: 16),
            ...messages.map((msg) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 16),
                child: msg.isUser
                    ? _userBubble(fBold, fReg, msg)
                    : _aiBubble(fBold, fReg, msg))),
          ]);

  pw.Widget _userBubble(pw.Font fBold, pw.Font fReg, ChatMessage msg) =>
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Spacer(),
        pw.ConstrainedBox(
            constraints: const pw.BoxConstraints(maxWidth: 350),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                pw.Text(DateFormat('HH:mm').format(msg.timestamp),
                    style: pw.TextStyle(font: fReg, fontSize: 8, color: _textLight)),
                pw.SizedBox(width: 6),
                pw.Text('Pengguna', style: pw.TextStyle(font: fBold, fontSize: 9, color: _textMid)),
              ]),
              pw.SizedBox(height: 4),
              pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                      gradient: const pw.LinearGradient(colors: [_red, _orange]),
                      borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(14), topRight: pw.Radius.circular(14),
                          bottomLeft: pw.Radius.circular(14), bottomRight: pw.Radius.circular(3))),
                  child: pw.Text(msg.content,
                      style: pw.TextStyle(font: fReg, fontSize: 10, color: _white, lineSpacing: 2))),
            ])),
      ]);

  pw.Widget _aiBubble(pw.Font fBold, pw.Font fReg, ChatMessage msg) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(children: [
          pw.Container(width: 22, height: 22,
              decoration: pw.BoxDecoration(
                  gradient: const pw.LinearGradient(colors: [_red, _orange]),
                  borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Center(
                  child: pw.Text('AI', style: pw.TextStyle(font: fBold, fontSize: 7, color: _white)))),
          pw.SizedBox(width: 6),
          pw.Text('SMART SE2026', style: pw.TextStyle(font: fBold, fontSize: 9, color: _textDark)),
          pw.SizedBox(width: 8),
          pw.Text(DateFormat('HH:mm').format(msg.timestamp),
              style: pw.TextStyle(font: fReg, fontSize: 8, color: _textLight)),
        ]),
        pw.SizedBox(height: 6),
        pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
                color: _bgBodyText,
                borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(3), topRight: pw.Radius.circular(14),
                    bottomLeft: pw.Radius.circular(14), bottomRight: pw.Radius.circular(14)),
                border: pw.Border.all(color: _border)),
            child: pw.Text(msg.content,
                style: pw.TextStyle(font: fReg, fontSize: 10, color: _textDark, lineSpacing: 2))),
        if (msg.hasInsights || msg.hasPolicies || msg.hasVisualizations) ...[
          pw.SizedBox(height: 6),
          pw.Row(children: [
            pw.SizedBox(width: 28),
            if (msg.hasInsights)   _badge(fBold, '${msg.insightCount} insight', _purple),
            if (msg.hasInsights && msg.hasPolicies) pw.SizedBox(width: 6),
            if (msg.hasPolicies)   _badge(fBold, '${msg.policyCount} rekomendasi', _successGreen),
            if (msg.hasVisualizations) ...[
              pw.SizedBox(width: 6),
              _badge(fBold, '${msg.visualizationCount} visualisasi', _blue),
            ],
          ]),
        ],
      ]);

  pw.Widget _badge(pw.Font fBold, String label, PdfColor c) =>
      pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: pw.BoxDecoration(
              color: c.shade(0.08), borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: c.shade(0.25))),
          child: pw.Text(label, style: pw.TextStyle(font: fBold, fontSize: 8, color: c)));

  // ─── Policy ───────────────────────────────────────────────────────────────────

  pw.Page _policyPages(pw.ThemeData theme, pw.Font fBold, pw.Font fReg, pw.Font fItal,
      List<PolicyRecommendation> policies) =>
      pw.MultiPage(
          theme: theme, pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
          header: (ctx) => _header(fBold, fReg, 'Rekomendasi Kebijakan', '04'),
          footer: (ctx) => _multiFooter(fReg, ctx),
          build: (ctx) => [
            pw.SizedBox(height: 16),
            pw.Text(
                'Rekomendasi kebijakan yang dihasilkan oleh SMART SE2026 Agentic AI '
                    'berdasarkan analisis data Sensus Ekonomi 2026.',
                style: pw.TextStyle(font: fItal, fontSize: 10, color: _textMid, lineSpacing: 2)),
            pw.SizedBox(height: 16),
            ...policies.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 14),
                child: _policyCard(fBold, fReg, fItal, e.value, e.key + 1))),
          ]);

  pw.Widget _policyCard(pw.Font fBold, pw.Font fReg, pw.Font fItal,
      PolicyRecommendation p, int num) {
    final pc = p.priority == 'high' ? _errorRed
        : p.priority == 'medium' ? _warningAmber : _successGreen;
    final pl = p.priority == 'high' ? 'TINGGI'
        : p.priority == 'medium' ? 'SEDANG' : 'RENDAH';

    return pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
            color: _white, borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border(
                left: pw.BorderSide(color: pc, width: 4),
                top: pw.BorderSide(color: _border),
                right: pw.BorderSide(color: _border),
                bottom: pw.BorderSide(color: _border))),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(width: 24, height: 24,
                decoration: pw.BoxDecoration(
                    color: pc.shade(0.1), borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Center(child: pw.Text('$num',
                    style: pw.TextStyle(font: fBold, fontSize: 10, color: pc)))),
            pw.SizedBox(width: 10),
            pw.Expanded(child: pw.Text(p.title,
                style: pw.TextStyle(font: fBold, fontSize: 12, color: _textDark))),
            pw.SizedBox(width: 8),
            pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: pw.BoxDecoration(
                    color: pc.shade(0.08), borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Text('PRIORITAS $pl',
                    style: pw.TextStyle(font: fBold, fontSize: 7, color: pc))),
          ]),
          pw.SizedBox(height: 8),
          pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                  color: _bgGrey, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Text(p.category.displayName,
                  style: pw.TextStyle(font: fReg, fontSize: 8, color: _textMid))),
          pw.SizedBox(height: 8),
          pw.Text(p.description,
              style: pw.TextStyle(font: fReg, fontSize: 10, color: _textDark, lineSpacing: 2)),
          if (p.impact.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Dampak yang Diharapkan:',
                style: pw.TextStyle(font: fBold, fontSize: 9, color: _orange)),
            pw.SizedBox(height: 3),
            pw.Text(p.impact,
                style: pw.TextStyle(font: fItal, fontSize: 9, color: _textMid, lineSpacing: 1.5)),
          ],
          if (p.implementationSteps.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('Langkah Implementasi:',
                style: pw.TextStyle(font: fBold, fontSize: 9, color: _textDark)),
            pw.SizedBox(height: 4),
            ...p.implementationSteps.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Container(width: 16, height: 16,
                      decoration: pw.BoxDecoration(
                          gradient: const pw.LinearGradient(colors: [_red, _orange]),
                          borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Center(child: pw.Text('${e.key + 1}',
                          style: pw.TextStyle(font: fBold, fontSize: 7, color: _white)))),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Text(e.value,
                      style: pw.TextStyle(font: fReg, fontSize: 9, color: _textDark, lineSpacing: 1.5))),
                ]))),
          ],
        ]));
  }

  // ─── Insights ────────────────────────────────────────────────────────────────

  pw.Page _insightPages(pw.ThemeData theme, pw.Font fBold, pw.Font fReg,
      List<String> insights) =>
      pw.MultiPage(
          theme: theme, pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
          header: (ctx) => _header(fBold, fReg, 'Key Insights Lengkap', '05'),
          footer: (ctx) => _multiFooter(fReg, ctx),
          build: (ctx) => [
            pw.SizedBox(height: 16),
            ...insights.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                        color: _bgLight, borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: _border)),
                    child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Container(width: 20, height: 20,
                          decoration: pw.BoxDecoration(
                              color: _purple.shade(0.1), borderRadius: pw.BorderRadius.circular(5)),
                          child: pw.Center(child: pw.Text('${e.key + 1}',
                              style: pw.TextStyle(font: fBold, fontSize: 8, color: _purple)))),
                      pw.SizedBox(width: 10),
                      pw.Expanded(child: pw.Text(e.value,
                          style: pw.TextStyle(font: fReg, fontSize: 10, color: _textDark, lineSpacing: 2))),
                    ])))),
          ]);

  // ─── Closing ─────────────────────────────────────────────────────────────────

  pw.Page _closingPage(pw.ThemeData theme, pw.Font fBold, pw.Font fReg,
      ChatSession session) =>
      pw.Page(
          theme: theme, pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero,
          build: (ctx) => pw.Stack(children: [
            pw.Positioned(bottom: 0, left: 0, right: 0,
                child: pw.Container(height: 280,
                    decoration: const pw.BoxDecoration(
                        gradient: pw.LinearGradient(
                            begin: pw.Alignment.topLeft, end: pw.Alignment.bottomRight,
                            colors: [_red, _orange])))),
            pw.Positioned(bottom: 240, left: 0, right: 0, top: 0,
                child: pw.Container(color: _white)),
            pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 56),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                  pw.Spacer(),
                  pw.Text('✓', style: pw.TextStyle(font: fBold, fontSize: 48, color: _successGreen)),
                  pw.SizedBox(height: 16),
                  pw.Text('Laporan Selesai',
                      style: pw.TextStyle(font: fBold, fontSize: 28, color: _textDark)),
                  pw.SizedBox(height: 8),
                  pw.Text(
                      'Analisis ini dihasilkan oleh SMART SE2026 Agentic AI\n'
                          'berdasarkan data Sensus Ekonomi Indonesia 2026.',
                      style: pw.TextStyle(font: fReg, fontSize: 11, color: _textMid, lineSpacing: 2),
                      textAlign: pw.TextAlign.center),
                  pw.Spacer(),
                  pw.Divider(color: _border),
                  pw.SizedBox(height: 20),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('SMART SE2026 · Badan Pusat Statistik',
                        style: pw.TextStyle(font: fBold, fontSize: 9, color: _white)),
                    pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()),
                        style: pw.TextStyle(font: fReg,  fontSize: 9, color: _white70)),
                  ]),
                ])),
          ]));

  // ─── Layout helpers ───────────────────────────────────────────────────────────

  pw.Widget _header(pw.Font fBold, pw.Font fReg, String title, String num) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(children: [
          pw.Container(width: 4, height: 20,
              decoration: pw.BoxDecoration(
                  gradient: const pw.LinearGradient(
                      colors: [_red, _orange],
                      begin: pw.Alignment.topCenter,
                      end: pw.Alignment.bottomCenter),
                  borderRadius: pw.BorderRadius.circular(2))),
          pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Text(title,
              style: pw.TextStyle(font: fBold, fontSize: 18, color: _textDark))),
          pw.Text(num, style: pw.TextStyle(font: fBold, fontSize: 32, color: _border)),
        ]),
        pw.SizedBox(height: 8),
        pw.Divider(color: _border, thickness: 1),
      ]);

  pw.Widget _footer(pw.Font fReg, String sessionTitle) =>
      pw.Column(children: [
        pw.Divider(color: _border, thickness: 0.5),
        pw.SizedBox(height: 6),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('SMART SE2026 — $sessionTitle',
              style: pw.TextStyle(font: fReg, fontSize: 8, color: _textLight)),
          pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()),
              style: pw.TextStyle(font: fReg, fontSize: 8, color: _textLight)),
        ]),
      ]);

  pw.Widget _multiFooter(pw.Font fReg, pw.Context ctx) =>
      pw.Column(children: [
        pw.Divider(color: _border, thickness: 0.5),
        pw.SizedBox(height: 6),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('SMART SE2026 · Sensus Ekonomi Indonesia 2026',
              style: pw.TextStyle(font: fReg, fontSize: 8, color: _textLight)),
          pw.Text('Halaman ${ctx.pageNumber}',
              style: pw.TextStyle(font: fReg, fontSize: 8, color: _textLight)),
        ]),
      ]);
}