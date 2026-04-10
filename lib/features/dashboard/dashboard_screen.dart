import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/models/dashboard_models.dart';
import '../chat/widgets/user_menu.dart';
import 'widgets/stat_hero_card.dart';
import 'widgets/analysis_card.dart';
import 'widgets/quick_prompt_grid.dart';
import 'widgets/recent_analyses_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().initialize();
    });
  }

  void _navigateToChat({String? initialMessage, String? sessionId}) {
    final chatProvider = context.read<ChatProvider>();

    if (sessionId != null && sessionId.isNotEmpty) {
      chatProvider.switchToSession(sessionId);
    } else {
      chatProvider.createNewChat();
      if (initialMessage != null && initialMessage.isNotEmpty) {
        // Send after navigation so the chat screen is ready
        Future.microtask(() => chatProvider.sendMessage(initialMessage));
      }
    }
    Navigator.pushNamed(context, '/chat');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkBackgroundGradient
              : AppColors.lightBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _AppBar(onNewChat: () => _navigateToChat()),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryOrange,
                  onRefresh: () => context.read<DashboardProvider>().refresh(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Greeting ──────────────────────────────────
                        _GreetingSection()
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: -0.1),

                        const SizedBox(height: 20),

                        // ── Hero Stats Row ─────────────────────────────
                        _SectionLabel(label: 'Statistik Nasional SE2026'),
                        const SizedBox(height: 10),
                        const _HeroStatsRow(),

                        const SizedBox(height: 24),

                        // ── Quick Prompts ──────────────────────────────
                        _SectionLabel(
                          label: 'Analisis Cepat',
                          subtitle: 'Tap untuk mulai analisis dengan AI',
                        ),
                        const SizedBox(height: 10),
                        QuickPromptGrid(
                          onPromptTap: (prompt) =>
                              _navigateToChat(initialMessage: prompt),
                        ),

                        const SizedBox(height: 24),

                        // ── AI Analysis Cards ─────────────────────────
                        _SectionLabel(
                          label: 'Analisis Agentic AI',
                          subtitle: 'Diproses oleh agent analisis backend',
                          actionLabel: 'Jalankan Semua',
                          onAction: () =>
                              context.read<DashboardProvider>().runAllAnalyses(),
                        ),
                        const SizedBox(height: 10),
                        const _AnalysisCardsGrid(),

                        const SizedBox(height: 24),

                        // ── Recent Analyses ────────────────────────────
                        _SectionLabel(
                          label: 'Analisis Terakhir',
                          subtitle: 'Riwayat sesi chat Anda',
                          actionLabel: 'Lihat Semua',
                          onAction: () => Navigator.pushNamed(context, '/chat'),
                        ),
                        const SizedBox(height: 10),
                        RecentAnalysesList(
                          onSessionTap: (sessionId) =>
                              _navigateToChat(sessionId: sessionId),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // ── FAB: New Chat ──────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToChat(),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text(
          'Chat Baru',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ).animate(delay: 600.ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final VoidCallback onNewChat;
  const _AppBar({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                  child: Text(
                    'SMART SE2026',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  'Dashboard Analitik',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Theme toggle
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.themeModeType == ThemeModeType.dark
                  ? Icons.dark_mode
                  : themeProvider.themeModeType == ThemeModeType.light
                  ? Icons.light_mode
                  : Icons.auto_mode,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              size: 22,
            ),
          ),
          const UserMenu(),
        ],
      ),
    );
  }
}

// ─── Greeting ─────────────────────────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat Pagi'
        : hour < 15
        ? 'Selamat Siang'
        : hour < 18
        ? 'Selamat Sore'
        : 'Selamat Malam';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryRed.withOpacity(isDark ? 0.25 : 0.08),
            AppColors.primaryOrange.withOpacity(isDark ? 0.15 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryOrange.withOpacity(isDark ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, ${user?.name?.split(' ').first ?? 'Analis'}! 👋',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sensus Ekonomi 2026 siap dianalisis. Apa yang ingin Anda telusuri hari ini?',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.query_stats_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionLabel({
    required this.label,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05);
  }
}

// ─── Hero Stats Row ───────────────────────────────────────────────────────────

class _HeroStatsRow extends StatelessWidget {
  const _HeroStatsRow();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final stats = provider.stats;
    final isLoading = provider.isStatsLoading;

    return Column(
      children: [
        // Top row: 2 wide cards
        Row(
          children: [
            Expanded(
              child: StatHeroCard(
                index: 0,
                icon: Icons.store_rounded,
                label: 'Total Usaha',
                value: isLoading ? '...' : _fmt(stats.totalUsaha),
                growth: stats.usahaGrowthPct,
                isLoading: isLoading,
                accentColor: AppColors.primaryRed,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatHeroCard(
                index: 1,
                icon: Icons.people_alt_rounded,
                label: 'Tenaga Kerja',
                value: isLoading ? '...' : _fmt(stats.totalTenagaKerja),
                growth: stats.tkGrowthPct,
                isLoading: isLoading,
                accentColor: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Bottom row: 2 smaller stat cards
        Row(
          children: [
            Expanded(
              child: StatHeroCard(
                index: 2,
                icon: Icons.map_rounded,
                label: 'Provinsi',
                value: isLoading ? '...' : '${stats.totalProvinsi}',
                growth: null,
                isLoading: isLoading,
                accentColor: const Color(0xFF10B981),
                compact: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatHeroCard(
                index: 3,
                icon: Icons.category_rounded,
                label: 'Sektor KBLI',
                value: isLoading ? '...' : '${stats.totalSektor}',
                growth: null,
                isLoading: isLoading,
                accentColor: const Color(0xFFF59E0B),
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}Jt';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}Rb';
    return n.toString();
  }
}

// ─── Analysis Cards Grid ──────────────────────────────────────────────────────

class _AnalysisCardsGrid extends StatelessWidget {
  const _AnalysisCardsGrid();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Column(
      children: DashboardAnalysisType.values.asMap().entries.map((e) {
        final type = e.value;
        final result = provider.getAnalysis(type);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnalysisCard(
            type: type,
            result: result,
            onRun: () => provider.runAnalysis(type),
            onOpenChat: (sessionId) {
              if (sessionId.isNotEmpty) {
                context.read<ChatProvider>().switchToSession(sessionId);
                Navigator.pushNamed(context, '/chat');
              }
            },
          ),
        )
            .animate(delay: Duration(milliseconds: 200 + e.key * 80))
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.08);
      }).toList(),
    );
  }
}