import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/chat_models.dart';
import '../../../core/providers/chat_provider.dart';
import 'message_bubble.dart';
import 'visualization_card.dart';
import 'policy_card.dart';
import 'insight_card.dart';
import '../../widgets/spatial_analysis_card.dart';

class ChatMessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String scrapingStatus;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.scrapingStatus,
  });

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: widget.messages.length + (widget.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.messages.length) {
          return _buildLoadingIndicator(isDark);
        }
        final message = widget.messages[index];
        return _buildMessageItem(context, message, isDark, index);
      },
    );
  }

  Widget _buildMessageItem(
      BuildContext context, ChatMessage message, bool isDark, int index) {
    final isUser = message.isUser;
    final chatProvider = context.watch<ChatProvider>();
    final spatialResult = chatProvider.getSpatialResult(message.id);

    return Column(
      crossAxisAlignment:
      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // ── Message bubble ──────────────────────────────────────────
        MessageBubble(message: message, isUser: isUser)
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn(duration: 300.ms)
            .slideX(begin: isUser ? 0.1 : -0.1),

        // ── Spatial Map & Analysis (NEW) ────────────────────────────
        if (!isUser && spatialResult != null) ...[
          const SizedBox(height: 12),
          SpatialAnalysisCard(result: spatialResult),
        ],

        // ── Regular Visualizations ──────────────────────────────────
        if (message.visualizations != null &&
            message.visualizations!.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...message.visualizations!.map((viz) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: VisualizationCard(visualization: viz),
          )),
        ],

        // ── Insights ─────────────────────────────────────────────────
        if (message.insights != null && message.insights!.isNotEmpty) ...[
          const SizedBox(height: 12),
          InsightCard(insights: message.insights!),
        ],

        // ── Policies ─────────────────────────────────────────────────
        if (message.policies != null && message.policies!.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...message.policies!.map((policy) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PolicyCard(policy: policy),
          )),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                          (index) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        child: _buildTypingDot(index),
                      ),
                    ),
                  ),
                  if (widget.scrapingStatus == 'in_progress') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                                AppColors.primaryOrange),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Memproses data & analisis spasial…',
                          style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildTypingDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryOrange.withOpacity(0.6),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1.2, 1.2),
      duration: 600.ms,
      delay: Duration(milliseconds: index * 150),
    )
        .then()
        .scale(
      begin: const Offset(1.2, 1.2),
      end: const Offset(0.8, 0.8),
      duration: 600.ms,
    );
  }
}