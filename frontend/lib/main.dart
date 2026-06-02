import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/tool_screen.dart';
import 'core/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const PdfToolsApp(),
    ),
  );
}

class PdfToolsApp extends StatelessWidget {
  const PdfToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'PDF Tools — Merge, Split, Convert & More',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        quill.FlutterQuillLocalizations.delegate,
      ],
      onGenerateRoute: (settings) {
        if (settings.name == '/') return MaterialPageRoute(builder: (_) => const HomeScreen());
        if (settings.name != null && settings.name!.startsWith('/tool/')) {
          final toolId = settings.name!.replaceFirst('/tool/', '');
          return MaterialPageRoute(builder: (_) => ToolScreen(toolId: toolId));
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      },
      initialRoute: '/',
    );
  }
}
