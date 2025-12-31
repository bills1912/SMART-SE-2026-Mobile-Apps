import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  // Google Sign In instance
  // Android Client ID sudah didaftarkan di Google Cloud Console
  // dengan SHA-1 dari upload-keystore.jks
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (mounted) {
      _showError(authProvider.error ?? 'Login failed');
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);

    try {
      // Sign out first to ensure account picker is shown
      await _googleSignIn.signOut();

      print('[LoginScreen] Starting Google Sign In...');

      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign in
        print('[LoginScreen] User cancelled Google Sign In');
        setState(() => _isGoogleLoading = false);
        return;
      }

      print('[LoginScreen] Google Sign In Success:');
      print('[LoginScreen] - Email: ${googleUser.email}');
      print('[LoginScreen] - Name: ${googleUser.displayName}');
      print('[LoginScreen] - Photo: ${googleUser.photoUrl}');

      // Send to backend (tanpa idToken karena tidak pakai serverClientId)
      print('[LoginScreen] Sending to backend...');

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.loginWithGoogle(
        idToken: '', // Kosong karena tidak pakai Web Client ID
        email: googleUser.email,
        name: googleUser.displayName ?? googleUser.email.split('@')[0],
        picture: googleUser.photoUrl,
      );

      print('[LoginScreen] Backend response: success=$success');

      if (success && mounted) {
        print('[LoginScreen] Login successful, navigating to dashboard');
        print('[LoginScreen] User ID: ${authProvider.user?.userId}');
        print('[LoginScreen] User Email: ${authProvider.user?.email}');
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (mounted) {
        print('[LoginScreen] Login failed: ${authProvider.error}');
        _showError(authProvider.error ?? 'Google login failed');
      }
    } catch (e, stackTrace) {
      print('[LoginScreen] Google Sign In Error: $e');
      print('[LoginScreen] Stack trace: $stackTrace');
      if (mounted) {
        _showError('Gagal login dengan Google: ${_parseGoogleError(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  String _parseGoogleError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('network')) {
      return 'Tidak ada koneksi internet';
    } else if (errorStr.contains('canceled') || errorStr.contains('cancelled')) {
      return 'Login dibatalkan';
    } else if (errorStr.contains('sign_in_failed')) {
      return 'Konfigurasi Google Sign In belum lengkap';
    }
    return 'Silakan coba lagi';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final double safeBottomPadding = bottomPadding > 0 ? (bottomPadding + 20).toDouble() : 40.0;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkBackgroundGradient
              : AppColors.lightBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: safeBottomPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.of(context).padding.top - safeBottomPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildLogo()
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.elasticOut)
                      .fadeIn(),
                  const SizedBox(height: 24),
                  Text(
                    'SMART SE2026',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn()
                      .slideY(begin: 0.3),
                  const SizedBox(height: 8),
                  Text(
                    'Agentic AI for Analysis',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  )
                      .animate(delay: 300.ms)
                      .fadeIn()
                      .slideY(begin: 0.3),
                  const SizedBox(height: 48),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildGoogleButton()
                                .animate(delay: 400.ms)
                                .fadeIn()
                                .slideY(begin: 0.3),
                            const SizedBox(height: 24),
                            _buildDivider(isDark)
                                .animate(delay: 500.ms)
                                .fadeIn(),
                            const SizedBox(height: 24),
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'your@email.com',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            )
                                .animate(delay: 600.ms)
                                .fadeIn()
                                .slideX(begin: -0.1),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: '••••••••',
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            )
                                .animate(delay: 700.ms)
                                .fadeIn()
                                .slideX(begin: -0.1),
                            const SizedBox(height: 24),
                            GradientButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              isLoading: _isLoading,
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                                .animate(delay: 800.ms)
                                .fadeIn()
                                .slideY(begin: 0.3),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate(delay: 400.ms)
                      .fadeIn()
                      .slideY(begin: 0.2),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: Text(
                            'Sign Up',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate(delay: 900.ms)
                      .fadeIn(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildGoogleButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isGoogleLoading ? null : _handleGoogleLogin,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
            ),
          ),
          child: _isGoogleLoading
              ? const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange),
              ),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://www.google.com/favicon.ico',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.g_mobiledata,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or continue with email',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
      ],
    );
  }
}
