import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/custom_text_field.dart';
import 'widgets/chat_sidebar.dart';
import 'widgets/chat_message_list.dart';
import 'widgets/welcome_view.dart';
import 'widgets/user_menu.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
    
    // Initialize chat provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.createNewChat();
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

  void _handleNewChat() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.createNewChat();
    _messageController.clear();
    Navigator.pop(context); // Close drawer if open
  }

  void _handleSwitchSession(String sessionId) {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.switchToSession(sessionId);
    Navigator.pop(context); // Close drawer
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    // TODO: Implement voice recording
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatProvider = context.watch<ChatProvider>();
    final isNewChat = chatProvider.currentSession?.id.isEmpty ?? true;
    final messages = chatProvider.currentSession?.messages ?? [];
    final realMessages = messages.where((m) => !m.id.startsWith('welcome_')).toList();

    return Scaffold(
      key: _scaffoldKey,
      drawer: ChatSidebar(
        onNewChat: _handleNewChat,
        onSelectSession: _handleSwitchSession,
      ),
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
              _buildAppBar(isDark),
              
              // Main Content
              Expanded(
                child: isNewChat || realMessages.isEmpty
                    ? WelcomeView(
                        messageController: _messageController,
                        onSend: _handleSendMessage,
                        onVoice: _toggleRecording,
                        isRecording: _isRecording,
                        isLoading: chatProvider.isSending,
                      )
                    : Column(
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
                          _buildInputArea(isDark, chatProvider.isSending),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Menu Button
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: Icon(
              Icons.menu_rounded,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          
          // Logo & Title
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'SMART SE2026',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
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

  Widget _buildInputArea(bool isDark, bool isLoading) {
    final chatProvider = context.watch<ChatProvider>();
    
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
          // Input Field
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
                      // Voice Button
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
                      
                      // Send Button
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
          
          // Status Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Data Status
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
              
              // Connection Status
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
          
          const SizedBox(height: 4),
          
          Text(
            'AI can make mistakes. Verify info.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
