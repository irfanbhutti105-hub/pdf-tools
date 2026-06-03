import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../data/tools_catalog.dart';
import '../data/tools_data.dart';
import '../models/pdf_tool.dart';
import '../providers/theme_provider.dart';
import '../widgets/tools_catalog_view.dart';

class ToolsScreen extends StatefulWidget {
  final bool embeddedInShell;
  const ToolsScreen({super.key, this.embeddedInShell = true});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  ToolCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PdfTool> get _filteredTools => filterTools(
        query: _query,
        category: _selectedCategory,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;
    final isMobile = size.width < 700;
    final horizontal = isWide ? 80.0 : 20.0;

    return ColoredBox(
      color: isDark ? const Color(0xFF0D1020) : const Color(0xFFF5F7FF),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                isMobile ? 16 : 24,
                horizontal,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ToolsHeroHeader(
                    isDark: isDark,
                    isMobile: isMobile,
                    toolCount: allTools.length,
                  ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08),
                  const SizedBox(height: 20),
                  _SearchBar(
                    controller: _searchController,
                    isDark: isDark,
                    onChanged: (v) => setState(() => _query = v),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ).animate().fadeIn(delay: 80.ms, duration: 320.ms),
                  const SizedBox(height: 16),
                  _CategoryFilterRow(
                    isDark: isDark,
                    selected: _selectedCategory,
                    onSelected: (cat) => setState(() => _selectedCategory = cat),
                  ).animate().fadeIn(delay: 120.ms, duration: 320.ms),
                  const SizedBox(height: 24),
                  ToolsCatalogView(
                    tools: _filteredTools,
                    isWide: isWide,
                    searchQuery: _query,
                    showFeatured: _selectedCategory == null,
                  ),
                  SizedBox(height: isMobile ? 32 : 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolsHeroHeader extends StatelessWidget {
  const _ToolsHeroHeader({
    required this.isDark,
    required this.isMobile,
    required this.toolCount,
  });

  final bool isDark;
  final bool isMobile;
  final int toolCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1A1F3A), Color(0xFF252B4A)]
              : const [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -24,
            right: -16,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(isDark ? 0.06 : 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryColor.withOpacity(0.15),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.12 : 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.95),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Professional PDF workspace',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'All PDF Tools',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 26 : 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$toolCount powerful tools to merge, convert, secure, and perfect your documents.',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 13 : 14.5,
                  height: 1.45,
                  color: Colors.white.withOpacity(0.88),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    icon: Icons.bolt_rounded,
                    label: 'Fast processing',
                  ),
                  _StatChip(
                    icon: Icons.lock_outline_rounded,
                    label: 'Secure uploads',
                  ),
                  _StatChip(
                    icon: Icons.devices_rounded,
                    label: 'Works everywhere',
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.95)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isDark,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF121826),
      ),
      decoration: InputDecoration(
        hintText: 'Search tools — merge, convert, OCR…',
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: onClear,
            );
          },
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF151B2E) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.isDark,
    required this.selected,
    required this.onSelected,
  });

  final bool isDark;
  final ToolCategory? selected;
  final ValueChanged<ToolCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'All',
            selected: selected == null,
            accent: AppTheme.primaryColor,
            isDark: isDark,
            onTap: () => onSelected(null),
          ),
          ...toolCategoryOrder.map(
            (meta) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                label: meta.label,
                selected: selected == meta.category,
                accent: meta.accent,
                isDark: isDark,
                onTap: () => onSelected(meta.category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? accent.withOpacity(isDark ? 0.28 : 0.14)
                : (isDark ? const Color(0xFF151B2E) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? accent.withOpacity(0.6)
                  : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? accent
                  : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
            ),
          ),
        ),
      ),
    );
  }
}
