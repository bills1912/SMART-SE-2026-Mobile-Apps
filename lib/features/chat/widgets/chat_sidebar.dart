import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/models/chat_models.dart';
import '../../widgets/gradient_button.dart';

// ─── Filter Model ─────────────────────────────────────────────────────────────

enum DateFilterOption { all, today, thisWeek, thisMonth, older }

class _ActiveFilters {
  final String searchQuery;
  final DateFilterOption dateFilter;
  final String? provinceFilter;
  final String? topicFilter;

  const _ActiveFilters({
    this.searchQuery = '',
    this.dateFilter = DateFilterOption.all,
    this.provinceFilter,
    this.topicFilter,
  });

  bool get hasAnyFilter =>
      searchQuery.isNotEmpty ||
          dateFilter != DateFilterOption.all ||
          provinceFilter != null ||
          topicFilter != null;

  _ActiveFilters copyWith({
    String? searchQuery,
    DateFilterOption? dateFilter,
    String? provinceFilter,
    String? topicFilter,
    bool clearProvince = false,
    bool clearTopic = false,
  }) {
    return _ActiveFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      dateFilter: dateFilter ?? this.dateFilter,
      provinceFilter:
      clearProvince ? null : (provinceFilter ?? this.provinceFilter),
      topicFilter: clearTopic ? null : (topicFilter ?? this.topicFilter),
    );
  }
}

// ─── Topic & Province keyword maps ────────────────────────────────────────────

const _kTopicKeywords = {
  'Distribusi Sektor': ['sektor', 'kbli', 'distribusi', 'usaha', 'industri'],
  'Analisis UMKM': ['umkm', 'mikro', 'kecil', 'menengah'],
  'Peringkat Provinsi': ['peringkat', 'ranking', 'provinsi', 'wilayah'],
  'Tren Pertumbuhan': ['tren', 'pertumbuhan', 'growth'],
  'Tenaga Kerja': ['tenaga kerja', 'ketenagakerjaan', 'lapangan kerja', 'penyerapan'],
  'Investasi & Potensi': ['investasi', 'potensi', 'peluang'],
  'Ketimpangan Wilayah': ['ketimpangan', 'disparitas', 'jawa', 'luar jawa'],
  'Perdagangan': ['perdagangan', 'ekspor', 'impor', 'dagang'],
};

const _kIndonesianProvinces = [
  'Aceh', 'Sumatera Utara', 'Sumatera Barat', 'Riau', 'Kepulauan Riau',
  'Jambi', 'Sumatera Selatan', 'Bengkulu', 'Lampung', 'Bangka Belitung',
  'DKI Jakarta', 'Jawa Barat', 'Jawa Tengah', 'DI Yogyakarta', 'Jawa Timur',
  'Banten', 'Bali', 'NTB', 'NTT', 'Kalimantan Barat', 'Kalimantan Tengah',
  'Kalimantan Selatan', 'Kalimantan Timur', 'Kalimantan Utara',
  'Sulawesi Utara', 'Sulawesi Tengah', 'Sulawesi Selatan', 'Sulawesi Tenggara',
  'Gorontalo', 'Sulawesi Barat', 'Maluku', 'Maluku Utara', 'Papua', 'Papua Barat',
];

// ─── Main ChatSidebar Widget ──────────────────────────────────────────────────

class ChatSidebar extends StatefulWidget {
  final VoidCallback onNewChat;
  final Function(String) onSelectSession;

  const ChatSidebar({
    super.key,
    required this.onNewChat,
    required this.onSelectSession,
  });

  @override
  State<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends State<ChatSidebar>
    with SingleTickerProviderStateMixin {
  bool _isSelectionMode = false;
  final Set<String> _selectedSessions = {};
  bool _showActions = false;

  // Search & Filter state
  bool _showSearch = false;
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();
  _ActiveFilters _filters = const _ActiveFilters();
  late AnimationController _filterPanelController;

  @override
  void initState() {
    super.initState();
    _filterPanelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _searchController.addListener(() {
      setState(() {
        _filters = _filters.copyWith(searchQuery: _searchController.text);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterPanelController.dispose();
    super.dispose();
  }

  // ─── Filter Logic ──────────────────────────────────────────────────────────

  List<ChatSession> _applyFilters(List<ChatSession> sessions) {
    return sessions.where((session) {
      // Search query
      if (_filters.searchQuery.isNotEmpty) {
        final q = _filters.searchQuery.toLowerCase();
        final titleMatch = session.title.toLowerCase().contains(q);
        final msgMatch = session.messages.any(
              (m) => m.content.toLowerCase().contains(q),
        );
        if (!titleMatch && !msgMatch) return false;
      }

      // Date filter
      if (_filters.dateFilter != DateFilterOption.all) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final updated = session.updatedAt;

        switch (_filters.dateFilter) {
          case DateFilterOption.today:
            if (updated.isBefore(today)) return false;
          case DateFilterOption.thisWeek:
            if (updated.isBefore(today.subtract(const Duration(days: 7)))) {
              return false;
            }
          case DateFilterOption.thisMonth:
            if (updated.isBefore(DateTime(now.year, now.month, 1))) {
              return false;
            }
          case DateFilterOption.older:
            if (!updated.isBefore(DateTime(now.year, now.month, 1))) {
              return false;
            }
          case DateFilterOption.all:
            break;
        }
      }

      // Province filter
      if (_filters.provinceFilter != null) {
        final prov = _filters.provinceFilter!.toLowerCase();
        final hasProvince = session.title.toLowerCase().contains(prov) ||
            session.messages.any(
                  (m) => m.content.toLowerCase().contains(prov),
            );
        if (!hasProvince) return false;
      }

      // Topic filter
      if (_filters.topicFilter != null) {
        final keywords = _kTopicKeywords[_filters.topicFilter!] ?? [];
        final hasKeyword = keywords.any((kw) {
          return session.title.toLowerCase().contains(kw) ||
              session.messages.any(
                    (m) => m.content.toLowerCase().contains(kw),
              );
        });
        if (!hasKeyword) return false;
      }

      return true;
    }).toList();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _filters = _filters.copyWith(searchQuery: '');
      }
      if (_showSearch) _showFilters = false;
    });
    if (_showSearch) {
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(FocusNode());
      });
    }
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _filterPanelController.forward();
      } else {
        _filterPanelController.reverse();
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _filters = const _ActiveFilters();
      _searchController.clear();
      _showFilters = false;
      _filterPanelController.reverse();
    });
  }

  // ─── Selection Helpers ─────────────────────────────────────────────────────

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedSessions.clear();
    });
  }

  void _toggleSelection(String sessionId) {
    setState(() {
      if (_selectedSessions.contains(sessionId)) {
        _selectedSessions.remove(sessionId);
      } else {
        _selectedSessions.add(sessionId);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedSessions.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteDialog(
        'Hapus ${_selectedSessions.length} percakapan?',
        'Tindakan ini tidak dapat dibatalkan.',
      ),
    );
    if (confirmed == true) {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.deleteSessions(_selectedSessions.toList());
      setState(() {
        _isSelectionMode = false;
        _selectedSessions.clear();
      });
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteDialog(
        'Hapus semua percakapan?',
        'Ini akan menghapus SEMUA riwayat chat Anda secara permanen.',
        isDestructive: true,
      ),
    );
    if (confirmed == true) {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.deleteAllSessions();
      setState(() => _showActions = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatProvider = context.watch<ChatProvider>();
    final filteredSessions = _applyFilters(chatProvider.sessions);

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildActionButtons(isDark, chatProvider),

            // ── Search Bar ───────────────────────────────────────────
            if (_showSearch)
              _buildSearchBar(isDark)
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slideY(begin: -0.1),

            // ── Filter Panel ──────────────────────────────────────────
            if (_showFilters)
              _buildFilterPanel(isDark)
                  .animate()
                  .fadeIn(duration: 220.ms)
                  .slideY(begin: -0.08),

            // ── Active filter chips ───────────────────────────────────
            if (_filters.hasAnyFilter) _buildActiveFilterChips(isDark),

            const Divider(height: 1),

            // ── Result count ──────────────────────────────────────────
            if (_filters.hasAnyFilter)
              _buildResultCount(filteredSessions.length,
                  chatProvider.sessions.length, isDark),

            // ── Session List ──────────────────────────────────────────
            Expanded(
              child: chatProvider.isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                  AlwaysStoppedAnimation(AppColors.primaryOrange),
                ),
              )
                  : filteredSessions.isEmpty
                  ? _buildEmptyState(isDark, chatProvider.sessions.isEmpty)
                  : _buildSessionList(isDark, filteredSessions, chatProvider),
            ),

            _buildFooter(isDark, chatProvider),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: Text(
                    'SMART SE2026',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  'Riwayat Chat',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Search toggle
          _buildHeaderIconBtn(
            icon: _showSearch ? Icons.search_off : Icons.search,
            active: _showSearch || _filters.searchQuery.isNotEmpty,
            onTap: _toggleSearch,
            isDark: isDark,
            tooltip: 'Cari riwayat',
          ),

          // Filter toggle
          _buildHeaderIconBtn(
            icon: Icons.tune,
            active: _showFilters || _filters.hasAnyFilter,
            onTap: _toggleFilters,
            isDark: isDark,
            tooltip: 'Filter',
            hasBadge: _filters.hasAnyFilter,
          ),

          // Close
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconBtn({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required bool isDark,
    required String tooltip,
    bool hasBadge = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primaryOrange.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(color: AppColors.primaryOrange.withOpacity(0.3))
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: active
                    ? AppColors.primaryOrange
                    : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
              ),
              if (hasBadge)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Search Bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _searchController.text.isNotEmpty
                ? AppColors.primaryOrange.withOpacity(0.4)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.search, size: 18, color: AppColors.primaryOrange),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.bodySmall,
                cursorColor: AppColors.primaryOrange,
                decoration: InputDecoration(
                  hintText: 'Cari judul, pesan, topik...',
                  hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  isDense: true,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() =>
                  _filters = _filters.copyWith(searchQuery: ''));
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.cancel,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Filter Panel ──────────────────────────────────────────────────────────

  Widget _buildFilterPanel(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withOpacity(0.8)
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date filter ────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.primaryOrange),
              const SizedBox(width: 6),
              Text(
                'Waktu',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DateFilterOption.values.map((opt) {
                final selected = _filters.dateFilter == opt;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _filterChipButton(
                    label: _dateFilterLabel(opt),
                    selected: selected,
                    onTap: () => setState(() =>
                    _filters = _filters.copyWith(dateFilter: opt)),
                    isDark: isDark,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // ── Topic filter ───────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.topic_outlined, size: 14, color: AppColors.primaryOrange),
              const SizedBox(width: 6),
              Text(
                'Topik',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _kTopicKeywords.keys.map((topic) {
              final selected = _filters.topicFilter == topic;
              return _filterChipButton(
                label: topic,
                selected: selected,
                onTap: () => setState(() {
                  _filters = selected
                      ? _filters.copyWith(clearTopic: true)
                      : _filters.copyWith(topicFilter: topic);
                }),
                isDark: isDark,
                small: true,
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // ── Province filter ────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.map_outlined, size: 14, color: AppColors.primaryOrange),
              const SizedBox(width: 6),
              Text(
                'Provinsi',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_filters.provinceFilter != null)
                GestureDetector(
                  onTap: () =>
                      setState(() => _filters = _filters.copyWith(clearProvince: true)),
                  child: Text(
                    'Hapus',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildProvinceDropdown(isDark),

          // ── Clear all button ───────────────────────────────────────
          if (_filters.hasAnyFilter) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _clearAllFilters,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.filter_alt_off_outlined,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Text(
                      'Hapus Semua Filter',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChipButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
    bool small = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10,
          vertical: small ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryOrange.withOpacity(0.15)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryOrange.withOpacity(0.5)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: small ? 10 : 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected
                ? AppColors.primaryOrange
                : (isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildProvinceDropdown(bool isDark) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _filters.provinceFilter != null
              ? AppColors.primaryOrange.withOpacity(0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filters.provinceFilter,
          hint: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              'Pilih provinsi...',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
          ),
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.keyboard_arrow_down, size: 18),
          ),
          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  'Semua Provinsi',
                  style: TextStyle(fontSize: 12, color: AppColors.primaryOrange),
                ),
              ),
            ),
            ..._kIndonesianProvinces.map(
                  (prov) => DropdownMenuItem<String>(
                value: prov,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    prov,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
          onChanged: (val) {
            setState(() {
              _filters = val == null
                  ? _filters.copyWith(clearProvince: true)
                  : _filters.copyWith(provinceFilter: val);
            });
          },
        ),
      ),
    );
  }

  // ─── Active Filter Chips ───────────────────────────────────────────────────

  Widget _buildActiveFilterChips(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Filter aktif:',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
            const SizedBox(width: 6),
            if (_filters.searchQuery.isNotEmpty)
              _activeChip(
                '"${_filters.searchQuery}"',
                    () => setState(() {
                  _searchController.clear();
                  _filters = _filters.copyWith(searchQuery: '');
                }),
                isDark,
              ),
            if (_filters.dateFilter != DateFilterOption.all)
              _activeChip(
                _dateFilterLabel(_filters.dateFilter),
                    () => setState(() => _filters =
                    _filters.copyWith(dateFilter: DateFilterOption.all)),
                isDark,
              ),
            if (_filters.topicFilter != null)
              _activeChip(
                _filters.topicFilter!,
                    () => setState(
                        () => _filters = _filters.copyWith(clearTopic: true)),
                isDark,
              ),
            if (_filters.provinceFilter != null)
              _activeChip(
                _filters.provinceFilter!,
                    () => setState(
                        () => _filters = _filters.copyWith(clearProvince: true)),
                isDark,
              ),
          ],
        ),
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primaryOrange.withOpacity(0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close,
                  size: 12, color: AppColors.primaryOrange),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Result Count ──────────────────────────────────────────────────────────

  Widget _buildResultCount(int shown, int total, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shown > 0
                  ? AppColors.success
                  : (isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            shown == total
                ? '$total sesi'
                : '$shown dari $total sesi cocok',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          if (shown > 0 && shown < total) ...[
            const Spacer(),
            GestureDetector(
              onTap: _clearAllFilters,
              child: Text(
                'Tampilkan semua',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Action Buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons(bool isDark, ChatProvider chatProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 16, color: AppColors.primaryOrange),
              const SizedBox(width: 6),
              Text(
                'Riwayat Chat',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (chatProvider.sessions.isNotEmpty)
                IconButton(
                  onPressed: _toggleSelectionMode,
                  icon: Icon(
                    _isSelectionMode ? Icons.close : Icons.checklist,
                    size: 20,
                    color: _isSelectionMode
                        ? AppColors.primaryOrange
                        : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                  ),
                  padding: EdgeInsets.zero,
                  constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (!_isSelectionMode) ...[
            GradientButton(
              onPressed: widget.onNewChat,
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 6),
                  Text('Chat Baru', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _buildActionsMenu(isDark, chatProvider),
          ] else ...[
            GradientButton(
              onPressed: _selectedSessions.isEmpty ? null : _deleteSelected,
              height: 40,
              gradient: LinearGradient(colors: [
                AppColors.error,
                AppColors.error.withOpacity(0.8),
              ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline, size: 18),
                  const SizedBox(width: 6),
                  Text('Hapus (${_selectedSessions.length})',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsMenu(bool isDark, ChatProvider chatProvider) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _showActions = !_showActions),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.more_horiz,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                  const SizedBox(width: 6),
                  Text('Tindakan',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)),
                ],
              ),
            ),
          ),
        ),
        if (_showActions)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                _buildActionItem(
                  icon: Icons.file_download_outlined,
                  label: 'Export Chat Ini',
                  onTap: () {
                    chatProvider.exportCurrentChat();
                    setState(() => _showActions = false);
                  },
                  isDark: isDark,
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.lightDivider),
                _buildActionItem(
                  icon: Icons.download,
                  label: 'Export Semua',
                  onTap: () {
                    chatProvider.exportAllChats();
                    setState(() => _showActions = false);
                  },
                  isDark: isDark,
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.lightDivider),
                _buildActionItem(
                  icon: Icons.delete_outline,
                  label: 'Hapus Semua Riwayat',
                  onTap: _deleteAll,
                  isDark: isDark,
                  isDestructive: true,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDestructive
                    ? AppColors.error
                    : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDestructive
                      ? AppColors.error
                      : (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark, bool noSessions) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              noSessions
                  ? Icons.chat_bubble_outline
                  : Icons.search_off_rounded,
              size: 52,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: 14),
            Text(
              noSessions ? 'Belum ada riwayat chat' : 'Tidak ada hasil',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noSessions
                  ? 'Mulai chat baru untuk menganalisis data SE2026'
                  : 'Coba ubah kata kunci atau hapus filter aktif',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
                height: 1.5,
              ),
            ),
            if (!noSessions) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _clearAllFilters,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primaryOrange.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Hapus semua filter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Session List ──────────────────────────────────────────────────────────

  Widget _buildSessionList(
      bool isDark, List<ChatSession> sessions, ChatProvider chatProvider) {
    // Group by date if no search query
    if (_filters.searchQuery.isEmpty && _filters.dateFilter == DateFilterOption.all) {
      return _buildGroupedList(isDark, sessions, chatProvider);
    }
    return _buildFlatList(isDark, sessions, chatProvider);
  }

  Widget _buildGroupedList(
      bool isDark, List<ChatSession> sessions, ChatProvider chatProvider) {
    final groups = _groupByDate(sessions);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: groups.length,
      itemBuilder: (context, idx) {
        final group = groups[idx];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                group.key,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...group.sessions.asMap().entries.map((e) {
              return _buildSessionTile(
                session: e.value,
                isDark: isDark,
                chatProvider: chatProvider,
                animDelay: e.key * 40,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildFlatList(
      bool isDark, List<ChatSession> sessions, ChatProvider chatProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return _buildSessionTile(
          session: sessions[index],
          isDark: isDark,
          chatProvider: chatProvider,
          animDelay: index * 40,
          searchQuery: _filters.searchQuery,
        );
      },
    );
  }

  Widget _buildSessionTile({
    required ChatSession session,
    required bool isDark,
    required ChatProvider chatProvider,
    int animDelay = 0,
    String searchQuery = '',
  }) {
    final isSelected = _selectedSessions.contains(session.id);
    final isActive = chatProvider.currentSession?.id == session.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(session.id);
            } else {
              widget.onSelectSession(session.id);
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              _toggleSelectionMode();
              _toggleSelection(session.id);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: isActive && !_isSelectionMode
                  ? AppColors.primaryOrange.withOpacity(isDark ? 0.12 : 0.07)
                  : isSelected
                  ? AppColors.primaryOrange.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive && !_isSelectionMode
                    ? AppColors.primaryOrange.withOpacity(0.3)
                    : isSelected
                    ? AppColors.primaryOrange
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                if (_isSelectionMode) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryOrange
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryOrange
                            : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 10),
                ],

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with highlight
                      searchQuery.isNotEmpty
                          ? _highlightedText(
                          session.title, searchQuery, isDark)
                          : Text(
                        session.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 10,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary),
                          const SizedBox(width: 3),
                          Text(
                            _relativeDate(session.updatedAt),
                            style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (session.realMessageCount > 0) ...[
                            Icon(Icons.chat_bubble_outline,
                                size: 10,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary),
                            const SizedBox(width: 3),
                            Text(
                              '${session.realMessageCount}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                color: isDark
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

                // Right side
                if (!_isSelectionMode) ...[
                  if (isActive)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryOrange,
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => _deleteSession(session.id),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animDelay))
        .fadeIn(duration: 200.ms)
        .slideX(begin: -0.05);
  }

  // ─── Highlighted Search Text ───────────────────────────────────────────────

  Widget _highlightedText(String text, String query, bool isDark) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
      );
    }

    final lower = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int idx;

    while ((idx = lower.indexOf(lowerQuery, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(
          text: text.substring(start, idx),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryOrange,
          backgroundColor: AppColors.primaryOrange.withOpacity(0.12),
        ),
      ));
      start = idx + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(bool isDark, ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${chatProvider.sessions.length} sesi',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
          Text(
            '${chatProvider.totalMessages} pesan',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _dateFilterLabel(DateFilterOption opt) {
    switch (opt) {
      case DateFilterOption.all:
        return 'Semua';
      case DateFilterOption.today:
        return 'Hari Ini';
      case DateFilterOption.thisWeek:
        return '7 Hari';
      case DateFilterOption.thisMonth:
        return 'Bulan Ini';
      case DateFilterOption.older:
        return 'Lebih Lama';
    }
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes}m lalu';
    if (diff.inDays < 1) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return DateFormat('dd MMM').format(date);
  }

  List<_SessionGroup> _groupByDate(List<ChatSession> sessions) {
    final groups = <String, List<ChatSession>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final s in sessions) {
      final d = s.updatedAt;
      final String label;
      if (d.isAfter(today)) {
        label = 'Hari Ini';
      } else if (d.isAfter(today.subtract(const Duration(days: 1)))) {
        label = 'Kemarin';
      } else if (d.isAfter(today.subtract(const Duration(days: 7)))) {
        label = '7 Hari Terakhir';
      } else if (d.isAfter(DateTime(now.year, now.month, 1))) {
        label = 'Bulan Ini';
      } else {
        label = DateFormat('MMMM yyyy').format(d);
      }
      groups.putIfAbsent(label, () => []).add(s);
    }

    final order = [
      'Hari Ini',
      'Kemarin',
      '7 Hari Terakhir',
      'Bulan Ini',
    ];

    final result = <_SessionGroup>[];
    for (final key in order) {
      if (groups.containsKey(key)) {
        result.add(_SessionGroup(key: key, sessions: groups[key]!));
        groups.remove(key);
      }
    }
    for (final entry in groups.entries) {
      result.add(_SessionGroup(key: entry.key, sessions: entry.value));
    }
    return result;
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteDialog(
        'Hapus percakapan ini?',
        'Tindakan ini tidak dapat dibatalkan.',
      ),
    );
    if (confirmed == true) {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.deleteSession(sessionId);
    }
  }

  Widget _buildDeleteDialog(String title, String message,
      {bool isDestructive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isDestructive ? AppColors.error : AppColors.warning)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber_rounded,
                color: isDestructive ? AppColors.error : AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      content: Text(message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          )),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Batal',
              style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor:
            isDestructive ? AppColors.error : AppColors.primaryOrange,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}

// ─── Helper Data Classes ──────────────────────────────────────────────────────

class _SessionGroup {
  final String key;
  final List<ChatSession> sessions;
  const _SessionGroup({required this.key, required this.sessions});
}