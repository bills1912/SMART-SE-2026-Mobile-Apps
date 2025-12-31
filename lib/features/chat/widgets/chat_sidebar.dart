import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/models/chat_models.dart';
import '../../widgets/gradient_button.dart';

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

class _ChatSidebarState extends State<ChatSidebar> {
  bool _isSelectionMode = false;
  final Set<String> _selectedSessions = {};
  bool _showActions = false;

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
        'Delete ${_selectedSessions.length} conversations?',
        'This action cannot be undone.',
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
        'Delete all conversations?',
        'This will permanently delete ALL your chat history. This action cannot be undone.',
        isDestructive: true,
      ),
    );

    if (confirmed == true) {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.deleteAllSessions();
      setState(() => _showActions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatProvider = context.watch<ChatProvider>();

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark),
            
            // Action Buttons
            _buildActionButtons(isDark, chatProvider),
            
            const Divider(height: 1),
            
            // Session List
            Expanded(
              child: chatProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange),
                      ),
                    )
                  : chatProvider.sessions.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildSessionList(isDark, chatProvider),
            ),
            
            // Footer Stats
            _buildFooter(isDark, chatProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          
          // Title
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
                  'Agentic AI for Analysis',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark 
                        ? AppColors.darkTextTertiary 
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          
          // Close Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark, ChatProvider chatProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // History Header
          Row(
            children: [
              Icon(
                Icons.history,
                size: 18,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              Text(
                'Chat History',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
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
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Buttons
          if (!_isSelectionMode) ...[
            // New Chat Button
            GradientButton(
              onPressed: widget.onNewChat,
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text('New Chat'),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Actions Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _showActions = !_showActions),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.more_horiz,
                        size: 20,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Actions',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions Menu
            if (_showActions)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _buildActionItem(
                      icon: Icons.file_download_outlined,
                      label: 'Export Current',
                      onTap: () {
                        final chatProvider = context.read<ChatProvider>();
                        chatProvider.exportCurrentChat();
                        setState(() => _showActions = false);
                      },
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    _buildActionItem(
                      icon: Icons.download,
                      label: 'Export All',
                      onTap: () {
                        final chatProvider = context.read<ChatProvider>();
                        chatProvider.exportAllChats();
                        setState(() => _showActions = false);
                      },
                      isDark: isDark,
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    _buildActionItem(
                      icon: Icons.delete_outline,
                      label: 'Delete All History',
                      onTap: _deleteAll,
                      isDark: isDark,
                      isDestructive: true,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slideY(begin: -0.1),
          ] else ...[
            // Delete Selected Button
            GradientButton(
              onPressed: _selectedSessions.isEmpty ? null : _deleteSelected,
              height: 44,
              gradient: LinearGradient(
                colors: [
                  AppColors.error,
                  AppColors.error.withOpacity(0.8),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline, size: 20),
                  const SizedBox(width: 8),
                  Text('Delete (${_selectedSessions.length})'),
                ],
              ),
            ),
          ],
        ],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDestructive 
                    ? AppColors.error
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isDestructive 
                      ? AppColors.error
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No chat history yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(bool isDark, ChatProvider chatProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chatProvider.sessions.length,
      itemBuilder: (context, index) {
        final session = chatProvider.sessions[index];
        final isSelected = _selectedSessions.contains(session.id);
        final isActive = chatProvider.currentSession?.id == session.id;

        return _buildSessionItem(
          session: session,
          isDark: isDark,
          isSelected: isSelected,
          isActive: isActive,
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(session.id);
            } else {
              widget.onSelectSession(session.id);
            }
          },
          onDelete: () => _deleteSession(session.id),
        ).animate(delay: Duration(milliseconds: index * 50))
            .fadeIn(duration: 200.ms)
            .slideX(begin: -0.1);
      },
    );
  }

  Widget _buildSessionItem({
    required ChatSession session,
    required bool isDark,
    required bool isSelected,
    required bool isActive,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive && !_isSelectionMode
                  ? (isDark 
                      ? AppColors.primaryOrange.withOpacity(0.1)
                      : AppColors.primaryOrange.withOpacity(0.05))
                  : isSelected
                      ? (isDark 
                          ? AppColors.primaryOrange.withOpacity(0.2)
                          : AppColors.primaryOrange.withOpacity(0.1))
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
                // Checkbox (Selection Mode)
                if (_isSelectionMode) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primaryOrange
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primaryOrange
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: isDark 
                                ? AppColors.darkTextTertiary 
                                : AppColors.lightTextTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(session.createdAt),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark 
                                  ? AppColors.darkTextTertiary 
                                  : AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Active Indicator or Delete Button
                if (!_isSelectionMode) ...[
                  if (isActive)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryOrange,
                      ),
                    )
                  else
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: isDark 
                            ? AppColors.darkTextTertiary 
                            : AppColors.lightTextTertiary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark, ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            'Total Sessions: ${chatProvider.sessions.length}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
          Text(
            'Messages: ${chatProvider.totalMessages}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, HH:mm').format(date);
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteDialog(
        'Delete this conversation?',
        'This action cannot be undone.',
      ),
    );

    if (confirmed == true) {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.deleteSession(sessionId);
    }
  }

  Widget _buildDeleteDialog(String title, String message, {bool isDestructive = false}) {
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
              color: (isDestructive ? AppColors.error : AppColors.warning).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: isDestructive ? AppColors.error : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? AppColors.error : AppColors.primaryOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
