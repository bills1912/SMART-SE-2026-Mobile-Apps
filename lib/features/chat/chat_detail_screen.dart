import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/theme_provider.dart';
import 'widgets/chat_message_list.dart';
import 'widgets/user_menu.dart';

class ChatDetailScreen extends StatefulWidget {
  final String sessionId;

  const ChatDetailScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.switchToSession(widget.sessionId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendMessage(message);
    _messageController.clear();
    _focusNode.requestFocus();
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatProvider = context.watch<ChatProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    
    final messages = chatProvider.currentSession?.messages ?? [];
    final realMessages = messages.where((m) => !m.id.startsWith('welcome_')).toList();

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
              // App Bar
              _buildAppBar(isDark, themeProvider, chatProvider),
              
              // Loading State
              if (chatProvider.isLoading)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange),
                        ),
                        SizedBox(height: 16),
                        Text('Loading conversation...'),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      // Messages
                      Expanded(
                        child: ChatMessageList(
                          messages: realMessages,
                          isLoading: chatProvider.isSending,
                          scrapingStatus: chatProvider.scrapingStatus,
                        ),
                      ),
                      
                      // Input Area
                      _buildInputArea(isDark, chatProvider.isSending, chatProvider),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark, ThemeProvider themeProvider, ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              size: 20,
            ),
          ),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatProvider.currentSession?.title ?? 'Chat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${realMessages.length} messages',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          
          // Theme Toggle
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.themeModeType == ThemeModeType.dark
                  ? Icons.dark_mode
                  : themeProvider.themeModeType == ThemeModeType.light
                      ? Icons.light_mode
                      : Icons.auto_mode,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              size: 22,
            ),
          ),
          
          // User Menu
          const UserMenu(),
        ],
      ),
    );
  }

  List<Widget> get realMessages {
    final chatProvider = context.read<ChatProvider>();
    final messages = chatProvider.currentSession?.messages ?? [];
    return messages.where((m) => !m.id.startsWith('welcome_')).toList() as List<Widget>;
  }

  Widget _buildInputArea(bool isDark, bool isLoading, ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.darkBackground : Colors.white).withOpacity(0),
            isDark ? AppColors.darkBackground : Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  enabled: !isLoading,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSendMessage(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  cursorColor: AppColors.primaryOrange,
                  decoration: InputDecoration(
                    hintText: 'Reply...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark 
                          ? AppColors.darkTextTertiary 
                          : AppColors.lightTextTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleRecording,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _isRecording 
                                ? AppColors.error.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic_none,
                            color: _isRecording 
                                ? AppColors.error
                                : (isDark 
                                    ? AppColors.darkTextTertiary 
                                    : AppColors.lightTextTertiary),
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: isLoading ? null : _handleSendMessage,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: _messageController.text.trim().isNotEmpty && !isLoading
                                ? AppColors.primaryGradient
                                : null,
                            color: _messageController.text.trim().isEmpty || isLoading
                                ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                                : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  color: _messageController.text.trim().isNotEmpty
                                      ? Colors.white
                                      : (isDark 
                                          ? AppColors.darkTextTertiary 
                                          : AppColors.lightTextTertiary),
                                  size: 18,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.storage,
                    size: 12,
                    color: chatProvider.scrapingStatus == 'in_progress'
                        ? AppColors.primaryOrange
                        : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    chatProvider.scrapingStatus == 'in_progress'
                        ? 'Gathering data...'
                        : 'Data ready',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: chatProvider.scrapingStatus == 'in_progress'
                          ? AppColors.primaryOrange
                          : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: chatProvider.isBackendAvailable
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    chatProvider.isBackendAvailable ? 'Connected' : 'Offline',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: chatProvider.isBackendAvailable
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
