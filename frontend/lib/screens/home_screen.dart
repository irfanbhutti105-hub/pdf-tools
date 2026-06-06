import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../features/cv_maker/data/cv_templates_data.dart';
import '../features/cv_maker/models/cv_profile.dart';
import '../features/cv_maker/providers/cv_maker_provider.dart';
import '../features/cv_maker/widgets/cv_preview_widget.dart';
import '../providers/shell_navigation_provider.dart';
import '../core/app_theme.dart';
import '../core/open_tool.dart';
import '../data/tools_data.dart';
import '../models/pdf_tool.dart';
import '../providers/favorites_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/tools_catalog_view.dart';
import '../widgets/hero_section.dart';
import '../widgets/feature_banner.dart';
import '../services/auth_service.dart';
import '../widgets/ad_banner.dart';
import 'notifications_screen.dart';
import 'static_pages.dart';

class HomeScreen extends StatelessWidget {
  final bool embeddedInShell;
  const HomeScreen({super.key, this.embeddedInShell = false});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final unread = context.watch<NotificationsProvider>().unreadCount;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;
    final isMobile = size.width < 700;

    final content = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const AdBanner(placement: 'HomeTop'),
          const SizedBox(height: 12),
          if (isMobile) const _MobileHeader() else const HeroSection(),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 80 : 20,
              vertical: isMobile ? 20 : 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CvMakerHomeCard(),
                const SizedBox(height: 22),
                Text(
                  'Popular Tools',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 20 : 22,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start quickly with the most used actions.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _TopToolsRow(isMobile: isMobile),
                const SizedBox(height: 22),
                _FavoriteToolsSection(isMobile: isMobile),
                // const SizedBox(height: 22),
                // _HomeHighlights(isDark: isDark, isMobile: isMobile),
                if (!embeddedInShell) ...[
                  const SizedBox(height: 26),
                  Text(
                    isMobile ? 'Tools' : 'All PDF Tools',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: isMobile ? 26 : null,
                        ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    isMobile
                        ? 'Pick a tool to start processing your PDF'
                        : 'Everything you need to work with PDFs in one place.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 28),
                  ToolsCatalogView(
                    tools: allTools,
                    isWide: isWide,
                    showFeatured: false,
                  ),
                ],
              ],
            ),
          ),

          if (!isMobile) const FeatureBanner(),
          _Footer(isDark: isDark),
          if (isMobile) const SizedBox(height: 24),
        ],
      ),
    );

    if (embeddedInShell) {
      return ColoredBox(
        color: isDark ? const Color(0xFF0D1020) : const Color(0xFFF5F7FF),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1020) : const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'PDF Tools',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (unread > 0)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : unread.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          // History Button (only show if authenticated)
          FutureBuilder<bool>(
            future: AuthService.isAuthenticated(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'File History',
                  onPressed: () {
                    Navigator.pushNamed(context, '/history');
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Login/Logout Button
          FutureBuilder<bool>(
            future: AuthService.isAuthenticated(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return PopupMenuButton(
                  icon: const Icon(Icons.account_circle),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'history',
                      child: ListTile(
                        leading: Icon(Icons.history),
                        title: Text('File History'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Logout'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await AuthService.logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    } else if (value == 'history') {
                      Navigator.pushNamed(context, '/history');
                    }
                  },
                );
              } else {
                return TextButton.icon(
                  icon: Icon(Icons.login,
                      color: isDark ? Colors.white : AppTheme.primaryColor),
                  label: Text('Login',
                      style: TextStyle(
                          color:
                              isDark ? Colors.white : AppTheme.primaryColor)),
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: content,
    );
  }
}

class _FavoriteToolsSection extends StatelessWidget {
  final bool isMobile;
  const _FavoriteToolsSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tools = favorites.favoriteTools;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star_rounded,
              size: 22,
              color: AppTheme.secondaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Favourite Tools',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 20 : 22,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          tools.isEmpty
              ? 'Tap the star on any tool to pin it here for quick access.'
              : 'Your pinned tools, ready when you need them.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (tools.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 18 : 22,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151B2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.star_outline_rounded,
                    color: AppTheme.secondaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'No favourites yet — open a tool and tap the star icon.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tools.map((tool) {
              return _FavoriteToolChip(
                tool: tool,
                compact: isMobile,
                onTap: () => openPdfTool(context, tool),
                onRemove: () => favorites.toggle(tool.id),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _FavoriteToolChip extends StatelessWidget {
  final PdfTool tool;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteToolChip({
    required this.tool,
    required this.compact,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF172036) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.only(
            left: compact ? 12 : 14,
            right: compact ? 6 : 8,
            top: compact ? 10 : 11,
            bottom: compact ? 10 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.secondaryColor.withOpacity(isDark ? 0.35 : 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: tool.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(tool.icon, size: 15, color: tool.color),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  tool.title,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 12 : 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: AppTheme.secondaryColor,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Remove from favourites',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CvMakerHomeCard extends StatelessWidget {
  const _CvMakerHomeCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;
    final provider = context.watch<CvMakerProvider>();
    final template = provider.selectedTemplate;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.read<ShellNavigationProvider>().requestTab(kCvMakerTabIndex),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF1E2A4A), Color(0xFF2A1F4A)]
                  : const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(isDark ? 0.25 : 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CvCardHeader(isMobile: true),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 140,
                        child: CvPreviewWidget(
                          profile: provider.activeProfile ?? CvProfile.sample(),
                          template: template,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _CvCardHeader(isMobile: false)),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 150,
                        height: 190,
                        child: CvPreviewWidget(
                          profile: provider.activeProfile ?? CvProfile.sample(),
                          template: template,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06);
  }
}

class _CvCardHeader extends StatelessWidget {
  final bool isMobile;
  const _CvCardHeader({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'NEW',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.workspace_premium_rounded, color: Colors.amber.shade200, size: 18),
            const SizedBox(width: 4),
            Text(
              '${cvTemplates.where((t) => t.isPremium).length} premium templates',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'CV Maker',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Create a professional resume with Canva-style templates. Edit live, then export to PDF.',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => context.read<ShellNavigationProvider>().requestTab(kCvMakerTabIndex),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: Text(
            'Start building',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _TopToolsRow extends StatelessWidget {
  final bool isMobile;
  const _TopToolsRow({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final quickTools = allTools
        .where(
          (tool) => const {
            'merge',
            'split',
            'compress',
            'pdf-viewer',
            'pdf-editor',
            'word-to-pdf',
          }.contains(tool.id),
        )
        .toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: quickTools.map((tool) {
        return _QuickToolChip(
          label: tool.title,
          icon: tool.icon,
          color: tool.color,
          compact: isMobile,
          onTap: () => openPdfTool(context, tool),
        );
      }).toList(),
    );
  }
}

class _QuickToolChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  const _QuickToolChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF172036) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 10 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 12 : 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF7C74FF), Color(0xFF9A74FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(isDark ? 0.38 : 0.26),
            blurRadius: 28,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Welcome to PDF Tools',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Create, convert, and manage PDF files with a professional workflow in seconds.',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.92),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderTag(label: 'Fast'),
              _HeaderTag(label: 'Secure'),
              _HeaderTag(label: 'Easy to Use'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderTag extends StatelessWidget {
  final String label;
  const _HeaderTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1A2138) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(height: 10),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHighlights extends StatelessWidget {
  final bool isDark;
  final bool isMobile;

  const _HomeHighlights({
    required this.isDark,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF151E33) : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE5E7EB);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: const [
          _InfoPill(
            icon: Icons.bolt_rounded,
            title: 'Fast Processing',
            subtitle: 'Optimized workflow',
          ),
          _InfoPill(
            icon: Icons.lock_rounded,
            title: 'Private Files',
            subtitle: 'Auto cleanup after use',
          ),
          _InfoPill(
            icon: Icons.workspace_premium_rounded,
            title: 'Professional Quality',
            subtitle: 'Ready for business use',
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoPill({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2741) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          const AdBanner(placement: 'HomeFooter'),
          const SizedBox(height: 18),
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
                child: const Icon(Icons.picture_as_pdf,
                    color: Colors.white, size: 20),
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
          const SizedBox(height: 20),
          LegalPageLinks(isDark: isDark),
          const SizedBox(height: 16),
          Text(
            '© 2026 PDF Tools. All rights reserved. Files are automatically deleted after processing.',
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
