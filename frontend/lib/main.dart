import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'providers/favorites_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/shell_navigation_provider.dart' show ShellNavigationProvider, kAccountTabIndex;
import 'providers/theme_provider.dart';
import 'features/cv_maker/providers/cv_maker_provider.dart';
import 'screens/app_shell_screen.dart';
import 'screens/tool_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/static_pages.dart';
import 'core/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => ShellNavigationProvider()),
        ChangeNotifierProvider(create: (_) => CvMakerProvider()),
      ],
      child: const PdfToolsApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PdfToolsApp extends StatefulWidget {
  const PdfToolsApp({super.key});

  @override
  State<PdfToolsApp> createState() => _PdfToolsAppState();
}

class _PdfToolsAppState extends State<PdfToolsApp> {
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initIntentListener();
  }

  void _initIntentListener() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        _handleSharedFiles(value);
      },
      onError: (err) {
        debugPrint("getMediaStream error: $err");
      },
    );

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    final file = files.first;
    
    // Check if it's a PDF
    if (file.path.toLowerCase().endsWith('.pdf') || 
        (file.mimeType?.toLowerCase() == 'application/pdf')) {
      try {
        // Read file into bytes
        final bytes = File(file.path).readAsBytesSync();
        // Determine filename
        String name = file.path.split('/').last;
        // Sometimes the path is a content URI. If name is a number, we might want to default it.
        if (name.isEmpty) name = 'shared_document.pdf';

        // Push to viewer
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => ToolScreen(
                toolId: 'pdf-viewer',
                initialPdfBytes: bytes,
                initialPdfName: name,
              ),
            ),
          );
        });
      } catch (e) {
        debugPrint("Error reading shared file: $e");
      }
    }
    
    // Clear intent so it doesn't refire
    ReceiveSharingIntent.instance.reset();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PDF Tools — Merge, Split, Convert & More',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (_) => const AuthCheck());
        }
        if (settings.name == '/home') {
          return MaterialPageRoute(builder: (_) => const AppShellScreen());
        }
        if (settings.name == '/login') {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
        if (settings.name == '/register') {
          return MaterialPageRoute(builder: (_) => const RegisterScreen());
        }
        if (settings.name == '/history') {
          return MaterialPageRoute(
            builder: (_) => const AppShellScreen(initialTab: kAccountTabIndex),
          );
        }
        if (settings.name != null && settings.name!.startsWith('/tool/')) {
          final toolId = settings.name!.replaceFirst('/tool/', '');
          return MaterialPageRoute(builder: (_) => ToolScreen(toolId: toolId));
        }
        if (settings.name == '/privacy-policy') {
          return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
        }
        if (settings.name == '/terms') {
          return MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen());
        }
        if (settings.name == '/about') {
          return MaterialPageRoute(builder: (_) => const AboutUsScreen());
        }
        if (settings.name == '/contact') {
          return MaterialPageRoute(builder: (_) => const ContactUsScreen());
        }
        return MaterialPageRoute(builder: (_) => const AppShellScreen());
      },
      initialRoute: '/',
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        setState(() => _animate = true);
      }
    });
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Keep splash visible long enough for a polished launch.
    await Future.delayed(const Duration(milliseconds: 1600));

    if (mounted) {
      // App always opens tools first; login is only for protected features.
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF0D1020), Color(0xFF181F35)]
                : const [Color(0xFFF5F7FF), Color(0xFFEFF2FF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              left: -40,
              child: _SplashGlow(
                size: 220,
                color: AppTheme.primaryColor.withOpacity(isDark ? 0.22 : 0.16),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -60,
              child: _SplashGlow(
                size: 260,
                color: AppTheme.secondaryColor.withOpacity(isDark ? 0.18 : 0.12),
              ),
            ),
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 700),
                opacity: _animate ? 1 : 0,
                curve: Curves.easeOut,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 700),
                  scale: _animate ? 1 : 0.92,
                  curve: Curves.easeOutBack,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: -5, end: 5),
                    duration: const Duration(milliseconds: 1450),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(0, value),
                      child: child,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.34),
                                blurRadius: 34,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.white,
                            size: 54,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          'PDF Tools',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: isDark ? Colors.white : const Color(0xFF121826),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Merge • Split • Compress • Convert',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : const Color(0xFF5B6473),
                              ),
                        ),
                        const SizedBox(height: 28),
                        const _SplashLoadingRow(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Text(
                'Professional PDF workspace',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 0.3,
                      color: isDark ? Colors.white38 : const Color(0xFF7A8392),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _SplashGlow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _SplashLoadingRow extends StatelessWidget {
  const _SplashLoadingRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CircularProgressIndicator(
        strokeWidth: 2.8,
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      ),
    );
  }
}
