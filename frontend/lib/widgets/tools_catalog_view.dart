import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../core/open_tool.dart';
import '../data/tools_catalog.dart';
import '../data/tools_data.dart';
import '../models/pdf_tool.dart';
import 'tool_card.dart';
import 'tools_grid.dart';

/// Searchable, categorized tools layout for the Tools tab.
class ToolsCatalogView extends StatelessWidget {
  final List<PdfTool> tools;
  final bool isWide;
  final bool showFeatured;
  final String searchQuery;

  const ToolsCatalogView({
    super.key,
    required this.tools,
    required this.isWide,
    this.showFeatured = true,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = groupToolsByCategory(tools);
    final showSections = searchQuery.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFeatured && searchQuery.trim().isEmpty) ...[
          _SectionLabel(
            title: 'Popular picks',
            subtitle: 'Fast access to the tools people use most',
            icon: Icons.bolt_rounded,
            accent: AppTheme.primaryColor,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final cardHeight = (176 * textScale).clamp(176.0, 210.0);

              return SizedBox(
                width: constraints.maxWidth,
                height: cardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.hardEdge,
                  itemCount: featuredTools.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final tool = featuredTools[i];
                    return FeaturedToolCard(
                      tool: tool,
                      height: cardHeight,
                      onTap: () => openPdfTool(context, tool),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 28),
        ],
        if (tools.isEmpty)
          _EmptySearchState(isDark: isDark)
        else if (showSections)
          ...toolCategoryOrder.map((meta) {
            final sectionTools = grouped[meta.category];
            if (sectionTools == null || sectionTools.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    title: meta.label,
                    subtitle: meta.description,
                    icon: meta.icon,
                    accent: meta.accent,
                    isDark: isDark,
                    count: sectionTools.length,
                  ),
                  const SizedBox(height: 14),
                  ToolsGrid(
                    tools: sectionTools,
                    isWide: isWide,
                    startIndex: allTools.indexOf(sectionTools.first),
                  ),
                ],
              ),
            );
          })
        else
          ToolsGrid(
            tools: tools,
            isWide: isWide,
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.isDark,
    this.count,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withOpacity(isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF121826),
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          Text(
            'No tools match your search',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF121826),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another keyword like merge, convert, or protect',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
