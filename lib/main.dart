import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/chat_provider.dart';
import 'core/providers/dashboard_provider.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';

import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/chat/chat_detail_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await StorageService.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SmartSE2026App());
}

class SmartSE2026App extends StatelessWidget {
  const SmartSE2026App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(ApiService())),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (context) => ChatProvider(
            ApiService(),
            context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) =>
          previous ?? ChatProvider(ApiService(), auth),
        ),
        // ── NEW: DashboardProvider ──────────────────────────────────
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SMART SE2026',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            initialRoute: '/splash',
            onGenerateRoute: _generateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return _buildPageRoute(const SplashScreen(), settings);
      case '/login':
        return _buildPageRoute(const LoginScreen(), settings);
      case '/register':
        return _buildPageRoute(const RegisterScreen(), settings);

    // ── NEW: /dashboard → DashboardScreen (was ChatScreen) ───────
      case '/dashboard':
        return _buildPageRoute(const DashboardScreen(), settings);

      case '/chat':
        return _buildPageRoute(const ChatScreen(), settings);
      case '/chat-detail':
        final sessionId = settings.arguments as String?;
        return _buildPageRoute(
          ChatDetailScreen(sessionId: sessionId ?? ''),
          settings,
        );
      case '/settings':
        return _buildPageRoute(const SettingsScreen(), settings);
      case '/profile':
        return _buildPageRoute(const ProfileScreen(), settings);
      default:
        return _buildPageRoute(const SplashScreen(), settings);
    }
  }

  PageRouteBuilder _buildPageRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        final offsetAnimation = animation.drive(tween);
        final fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}