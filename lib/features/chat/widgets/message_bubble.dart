import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/chat_models.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isUser;
  final void Function(String messageId, String newContent)? onEdit;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.onEdit,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showActions = false;
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Copied to clipboard'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
    setState(() => _showActions = false);
  }

  void _startEditing() {
    _editController.text = widget.message.content;
    setState(() {
      _isEditing = true;
      _showActions = false;
    });
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  void _submitEdit() {
    final newContent = _editController.text.trim();
    if (newContent.isEmpty || newContent == widget.message.content) {
      setState(() => _isEditing = false);
      return;
    }
    widget.onEdit?.call(widget.message.id, newContent);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () => setState(() => _showActions = !_showActions),
      onTap: () {
        if (_showActions) setState(() => _showActions = false);
      },
      child: Row(
        mainAxisAlignment:
        widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isUser) ...[
            // AI Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Message Content
          Flexible(
            child: Column(
              crossAxisAlignment: widget.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // ── Editing mode ──────────────────────────────────
                if (_isEditing && widget.isUser)
                  _buildEditView(isDark)
                else
                  _buildMessageContent(isDark),

                // ── Quick action bar (always visible beneath messages) ──
                if (!_isEditing) _buildQuickActions(isDark),

                // ── Expanded actions (on long press) ──────────────
                if (_showActions && !_isEditing)
                  _buildExpandedActions(isDark)
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: -0.2),

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTimestamp(widget.message.timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (widget.isUser) ...[
            const SizedBox(width: 12),
            // User Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                  isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Icon(
                Icons.person,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Message bubble content ───────────────────────────────────────────────
  Widget _buildMessageContent(bool isDark) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: widget.isUser ? AppColors.primaryGradient : null,
        color:
        widget.isUser ? null : (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(widget.isUser ? 20 : 4),
          bottomRight: Radius.circular(widget.isUser ? 4 : 20),
        ),
        border: widget.isUser
            ? null
            : Border.all(
          color:
          isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: widget.isUser
            ? [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SelectableText(
        widget.message.content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: widget.isUser
              ? Colors.white
              : (isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary),
          height: 1.5,
        ),
      ),
    );
  }

  // ─── Quick actions (small icons beneath the bubble) ────────────────────────
  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Copy button — available for both user and AI messages
          _buildSmallActionIcon(
            icon: Icons.copy_rounded,
            tooltip: 'Copy',
            onTap: _copyToClipboard,
            isDark: isDark,
          ),

          // Edit button — only for user messages
          if (widget.isUser && widget.onEdit != null) ...[
            const SizedBox(width: 4),
            _buildSmallActionIcon(
              icon: Icons.edit_outlined,
              tooltip: 'Edit',
              onTap: _startEditing,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 15,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Expanded actions (on long press) ─────────────────────────────────────
  Widget _buildExpandedActions(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: _copyToClipboard,
            isDark: isDark,
          ),
          if (widget.isUser && widget.onEdit != null) ...[
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: _startEditing,
              isDark: isDark,
            ),
          ],
          if (!widget.isUser) ...[
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.thumb_up_outlined,
              label: 'Good',
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _showActions = false);
              },
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.thumb_down_outlined,
              label: 'Bad',
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _showActions = false);
              },
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

  // ─── Edit view (inline editing for user messages) ─────────────────────────
  Widget _buildEditView(bool isDark) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryOrange.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Edit header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.08),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_outlined,
                    size: 14, color: AppColors.primaryOrange),
                const SizedBox(width: 6),
                Text(
                  'Edit Message',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          // Text field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _editController,
              autofocus: true,
              maxLines: 6,
              minLines: 1,
              style: Theme.of(context).textTheme.bodyMedium,
              cursorColor: AppColors.primaryOrange,
              decoration: InputDecoration(
                hintText: 'Edit your message...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                isDense: true,
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color:
                  isDark ? AppColors.darkDivider : AppColors.lightDivider,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel
                TextButton(
                  onPressed: _cancelEditing,
                  style: TextButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Save & Send
                GestureDetector(
                  onTap: _submitEdit,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.send_rounded,
                            size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Send',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).scale(
      begin: const Offset(0.97, 0.97),
      curve: Curves.easeOutCubic,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}