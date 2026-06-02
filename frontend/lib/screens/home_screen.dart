import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../data/tools_data.dart';
import '../models/pdf_tool.dart';
import '../providers/theme_provider.dart';
import '../widgets/tool_card.dart';
import '../widgets/hero_section.dart';
import '../widgets/feature_banner.dart';
import '../widgets/app_navbar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      appBar: AppNavbar(isWide: isWide),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ──────────────────────────────────────
            const HeroSection(),

            // ── Tools Grid ────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 80 : 20,
                vertical: 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All PDF Tools',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Everything you need to work with PDFs in one place.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 36),

                  // Responsive Grid
                  _ToolsGrid(tools: allTools, isWide: isWide),
                ],
              ),
            ),

            // ── Feature Banners ───────────────────────────
            const FeatureBanner(),

            // ── Footer ────────────────────────────────────
            _Footer(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tools Grid
// ─────────────────────────────────────────────
class _ToolsGrid extends StatelessWidget {
  final List<PdfTool> tools;
  final bool isWide;
  const _ToolsGrid({required this.tools, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isWide
        ? 4
        : MediaQuery.of(context).size.width > 600
            ? 3
            : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: tools.length,
      itemBuilder: (context, i) {
        return ToolCard(tool: tools[i], index: i);
      },
    );
  }
}

// ─────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final bool isDark;
  const _Footer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF0F0FF),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'PDF Tools',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '© 2025 PDF Tools. All rights reserved. Files are automatically deleted after processing.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
