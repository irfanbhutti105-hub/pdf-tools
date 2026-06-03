import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../features/cv_maker/providers/cv_maker_provider.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _yearlySelected = true;
  bool _purchasing = false;

  static const _monthlyPrice = 4.99;
  static const _yearlyPrice = 39.99;
  static const _yearlyMonthly = 3.33;

  Future<void> _purchase() async {
    setState(() => _purchasing = true);
    try {
      await context.read<CvMakerProvider>().purchasePremium(
        plan: _yearlySelected ? 'yearly' : 'monthly',
      );
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 38),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              'You\'re Premium! 🎉',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'All premium templates, custom colors, and unlimited CV versions are now unlocked.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // go back
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Start Creating', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = context.watch<CvMakerProvider>().isPremiumUnlocked;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FF),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  if (isPremium) _buildAlreadyPremium(isDark),
                  if (!isPremium) ...[
                    _buildHeroSection(isDark),
                    const SizedBox(height: 28),
                    _buildFeaturesList(isDark),
                    const SizedBox(height: 28),
                    _buildPlanToggle(isDark),
                    const SizedBox(height: 16),
                    _buildPricingCards(isDark),
                    const SizedBox(height: 24),
                    _buildPurchaseButton(isDark),
                    const SizedBox(height: 16),
                    _buildDisclaimer(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 200,
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FF),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9B59B6), Color(0xFFFF6B6B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 10),
                Text(
                  'Go Premium',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Unlock the full CV Maker experience',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildAlreadyPremium(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re already Premium! ✨',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All features are unlocked. Enjoy the full CV Maker experience.',
                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildHeroSection(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          'Everything you need to build a standout CV',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'One-time unlock or flexible monthly/yearly subscription',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildFeaturesList(bool isDark) {
    final features = [
      (Icons.palette_rounded, 'Custom accent colors', 'Choose from 6 premium color palettes'),
      (Icons.photo_camera_rounded, 'Photo on CV', 'Add your professional headshot'),
      (Icons.layers_rounded, '8 Premium templates', 'Exclusive professional layouts'),
      (Icons.copy_all_rounded, 'Unlimited CV versions', 'Save and manage multiple resumes'),
      (Icons.picture_as_pdf_rounded, 'PDF export', 'Export polished, high-quality PDFs'),
      (Icons.cloud_upload_rounded, 'Cloud sync (coming soon)', 'Access your CVs on any device'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B30) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: features.asMap().entries.map((entry) {
          final i = entry.key;
          final f = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(f.$1, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.$2, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13.5)),
                          Text(
                            f.$3,
                            style: GoogleFonts.poppins(fontSize: 11.5, color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF6C63FF), size: 22),
                  ],
                ),
              ),
              if (i < features.length - 1)
                Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.06);
  }

  Widget _buildPlanToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2740) : const Color(0xFFEEEEFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _PlanToggleButton(
            label: 'Monthly',
            selected: !_yearlySelected,
            onTap: () => setState(() => _yearlySelected = false),
            isDark: isDark,
          ),
          _PlanToggleButton(
            label: 'Yearly  🔥 33% off',
            selected: _yearlySelected,
            onTap: () => setState(() => _yearlySelected = true),
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildPricingCards(bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _yearlySelected
          ? _PriceCard(
              key: const ValueKey('yearly'),
              label: 'Yearly',
              price: '\$$_yearlyPrice',
              sub: '\$$_yearlyMonthly / month, billed annually',
              badge: 'BEST VALUE',
              isDark: isDark,
            )
          : _PriceCard(
              key: const ValueKey('monthly'),
              label: 'Monthly',
              price: '\$$_monthlyPrice',
              sub: 'billed each month, cancel anytime',
              isDark: isDark,
            ),
    );
  }

  Widget _buildPurchaseButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: _purchasing ? null : _purchase,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          disabledBackgroundColor: const Color(0xFF6C63FF).withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _purchasing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    _yearlySelected
                        ? 'Get Premium — \$$_yearlyPrice/yr'
                        : 'Get Premium — \$$_monthlyPrice/mo',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.08);
  }

  Widget _buildDisclaimer() {
    return Text(
      'Secure payment · Cancel anytime · No hidden fees',
      style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
      textAlign: TextAlign.center,
    );
  }
}

class _PlanToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _PlanToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6C63FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: selected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String label;
  final String price;
  final String sub;
  final String? badge;
  final bool isDark;

  const _PriceCard({
    super.key,
    required this.label,
    required this.price,
    required this.sub,
    this.badge,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (badge != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
