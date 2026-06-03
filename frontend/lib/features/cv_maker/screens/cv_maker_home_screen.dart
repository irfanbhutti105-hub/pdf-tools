import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../data/cv_templates_data.dart';
import '../models/cv_profile.dart';
import '../models/cv_template.dart';
import '../providers/cv_maker_provider.dart';
import '../widgets/cv_preview_widget.dart';
import '../widgets/cv_template_card.dart';
import 'cv_editor_screen.dart';
import '../../../screens/premium_screen.dart';

class CvMakerHomeScreen extends StatefulWidget {
  const CvMakerHomeScreen({super.key});

  @override
  State<CvMakerHomeScreen> createState() => _CvMakerHomeScreenState();
}

class _CvMakerHomeScreenState extends State<CvMakerHomeScreen> {
  String _query = '';
  CvTemplateCategory _filter = CvTemplateCategory.all;
  bool _showPremiumOnly = false;
  bool _showFreeOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CvMakerProvider>().load();
    });
  }

  Future<void> _openTemplate(CvTemplate template) async {
    final provider = context.read<CvMakerProvider>();
    if (!provider.canUseTemplate(template)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      return;
    }
    provider.createNewProfile();
    provider.selectTemplate(template);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CvEditorScreen()),
    );
  }
  
  Future<void> _openSavedProfile(var profile) async {
    final provider = context.read<CvMakerProvider>();
    provider.loadProfile(profile);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CvEditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<CvMakerProvider>();
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final crossAxisCount = size.width > 900 ? 3 : (size.width > 560 ? 2 : 1);

    final templates = filterCvTemplates(
      filter: _filter,
      premiumOnly: _showPremiumOnly ? true : null,
      freeOnly: _showFreeOnly ? true : null,
      query: _query,
    );

    return ColoredBox(
      color: isDark ? const Color(0xFF0D1020) : const Color(0xFFF5F7FF),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 16, isMobile ? 16 : 24, 0),
              child: _HeroBanner(isDark: isDark, isMobile: isMobile)
                  .animate()
                  .fadeIn(duration: 320.ms)
                  .slideY(begin: 0.06),
            ),
          ),
          if (provider.savedProfiles.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 24, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Saved CVs',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.savedProfiles.length,
                        itemBuilder: (context, index) {
                          final profile = provider.savedProfiles[index];
                          return GestureDetector(
                            onTap: () => _openSavedProfile(profile),
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF151B2E) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.description, color: AppTheme.primaryColor, size: 32),
                                  const Spacer(),
                                  Text(
                                    profile.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Updated ${profile.updatedAt.month}/${profile.updatedAt.day}/${profile.updatedAt.year}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 20, isMobile ? 16 : 24, 0),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search templates…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF151B2E) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == CvTemplateCategory.all && !_showPremiumOnly && !_showFreeOnly,
                      onTap: () => setState(() {
                        _filter = CvTemplateCategory.all;
                        _showPremiumOnly = false;
                        _showFreeOnly = false;
                      }),
                    ),
                    _FilterChip(
                      label: 'Free',
                      selected: _showFreeOnly,
                      onTap: () => setState(() {
                        _filter = CvTemplateCategory.all;
                        _showPremiumOnly = false;
                        _showFreeOnly = true;
                      }),
                    ),
                    _FilterChip(
                      label: 'Premium',
                      selected: _showPremiumOnly,
                      onTap: () => setState(() {
                        _filter = CvTemplateCategory.all;
                        _showPremiumOnly = true;
                        _showFreeOnly = false;
                      }),
                      icon: Icons.workspace_premium_rounded,
                    ),
                    _FilterChip(
                      label: 'Modern',
                      selected: _filter == CvTemplateCategory.modern,
                      onTap: () => setState(() {
                        _filter = CvTemplateCategory.modern;
                        _showPremiumOnly = false;
                        _showFreeOnly = false;
                      }),
                    ),
                    _FilterChip(
                      label: 'Classic',
                      selected: _filter == CvTemplateCategory.classic,
                      onTap: () => setState(() {
                        _filter = CvTemplateCategory.classic;
                        _showPremiumOnly = false;
                        _showFreeOnly = false;
                      }),
                    ),
                    _FilterChip(
                      label: 'Creative',
                      selected: _filter == CvTemplateCategory.creative,
                      onTap: () => setState(() {
                        _filter = CvTemplateCategory.creative;
                        _showPremiumOnly = false;
                        _showFreeOnly = false;
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 20, isMobile ? 16 : 24, 32),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isMobile ? 0.72 : 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final template = templates[index];
                  final locked = !provider.canUseTemplate(template);
                  return CvTemplateCard(
                    template: template,
                    locked: locked,
                    onTap: () => _openTemplate(template),
                    preview: CvPreviewWidget(
                      profile: provider.activeProfile ?? CvProfile.sample(),
                      template: template,
                    ),
                  ).animate(delay: (40 * index).ms).fadeIn().slideY(begin: 0.08);
                },
                childCount: templates.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final bool isDark;
  final bool isMobile;

  const _HeroBanner({required this.isDark, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'CV Maker',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isMobile ? 24 : 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Build a professional resume in minutes. Pick a Canva-style template, fill in your details, and export to PDF.',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.92),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag('${cvTemplates.length} templates'),
              _Tag('${cvTemplates.where((t) => t.isPremium).length} premium'),
              _Tag('PDF export'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.white : AppTheme.primaryColor),
              const SizedBox(width: 4),
            ],
            Text(label, style: GoogleFonts.poppins(fontSize: 12)),
          ],
        ),
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: Colors.white,
        labelStyle: GoogleFonts.poppins(
          color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        backgroundColor: isDark ? const Color(0xFF151B2E) : Colors.white,
        side: BorderSide(
          color: selected
              ? AppTheme.primaryColor
              : (isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}
