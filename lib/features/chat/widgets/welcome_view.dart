import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class WelcomeView extends StatelessWidget {
  final TextEditingController messageController;
  final VoidCallback onSend;
  final VoidCallback onVoice;
  final bool isRecording;
  final bool isLoading;

  const WelcomeView({
    super.key,
    required this.messageController,
    required this.onSend,
    required this.onVoice,
    required this.isRecording,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: size.height - 200,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 40,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'Asisten Sensus Ekonomi\nIndonesia',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn()
                .slideY(begin: 0.3),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'Saya siap membantu analisis data dan metodologi sensus',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn()
                .slideY(begin: 0.3),
            
            const SizedBox(height: 40),
            
            // Input Card
            _buildInputCard(context, isDark)
                .animate(delay: 400.ms)
                .fadeIn()
                .slideY(begin: 0.2),
            
            const SizedBox(height: 8),
            
            // Disclaimer
            Text(
              'AI can make mistakes. Please verify important information.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark 
                    ? AppColors.darkTextTertiary 
                    : AppColors.lightTextTertiary,
              ),
            )
                .animate(delay: 500.ms)
                .fadeIn(),
            
            const SizedBox(height: 32),
            
            // Suggestion Chips
            _buildSuggestionChips(context, isDark)
                .animate(delay: 600.ms)
                .fadeIn()
                .slideY(begin: 0.2),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: messageController,
            maxLines: 4,
            minLines: 2,
            enabled: !isLoading,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            style: Theme.of(context).textTheme.bodyMedium,
            cursorColor: AppColors.primaryOrange,
            decoration: InputDecoration(
              hintText: 'Apa yang ingin Anda ketahui hari ini?',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark 
                    ? AppColors.darkTextTertiary 
                    : AppColors.lightTextTertiary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.darkBackground.withOpacity(0.5)
                  : AppColors.lightBackground.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Voice Button
                GestureDetector(
                  onTap: onVoice,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isRecording 
                          ? AppColors.error.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isRecording ? Icons.stop : Icons.mic_none,
                      color: isRecording 
                          ? AppColors.error
                          : (isDark 
                              ? AppColors.darkTextTertiary 
                              : AppColors.lightTextTertiary),
                      size: 22,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Send Button
                GestureDetector(
                  onTap: isLoading ? null : onSend,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: messageController.text.trim().isNotEmpty && !isLoading
                          ? AppColors.primaryGradient
                          : null,
                      color: messageController.text.trim().isEmpty || isLoading
                          ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: messageController.text.trim().isNotEmpty && !isLoading
                          ? [
                              BoxShadow(
                                color: AppColors.primaryRed.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: messageController.text.trim().isNotEmpty
                                ? Colors.white
                                : (isDark 
                                    ? AppColors.darkTextTertiary 
                                    : AppColors.lightTextTertiary),
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips(BuildContext context, bool isDark) {
    final suggestions = [
      'Metodologi Sensus 2026',
      'Publikasi Hasil Sensus',
      'Sektor Ekonomi Indonesia',
      'Pelaksanaan Sensus',
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: suggestions.asMap().entries.map((entry) {
        final index = entry.key;
        final text = entry.value;
        
        return GestureDetector(
          onTap: () {
            messageController.text = text;
            onSend();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: 600 + (index * 100)))
            .fadeIn()
            .scale(begin: const Offset(0.9, 0.9));
      }).toList(),
    );
  }
}
