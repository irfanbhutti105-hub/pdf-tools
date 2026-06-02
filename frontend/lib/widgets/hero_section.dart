import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: isWide ? 80 : 48,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0F0F1A),
                  const Color(0xFF1A1040),
                  const Color(0xFF0F1A2A),
                ]
              : [
                  const Color(0xFFEEEDFF),
                  const Color(0xFFF8F9FF),
                  const Color(0xFFE6F4FC),
                ],
        ),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: _HeroText()),
                const SizedBox(width: 60),
                Expanded(child: _HeroIllustration()),
              ],
            )
          : Column(
              children: [
                _HeroText(),
                const SizedBox(height: 40),
                _HeroIllustration(),
              ],
            ),
    );
  }
}

class _HeroText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '100% Free • No Registration Required',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.2, curve: Curves.easeOut),

        const SizedBox(height: 24),

        // Headline
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 46,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
            children: [
              const TextSpan(text: 'All-in-One\n'),
              const TextSpan(text: 'PDF '),
              TextSpan(
                text: 'Tools',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ).createShader(
                      const Rect.fromLTWH(0, 0, 200, 70),
                    ),
                ),
              ),
              const TextSpan(text: '\nfor Everyone'),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 700.ms)
            .slideY(begin: 0.2, curve: Curves.easeOut),

        const SizedBox(height: 20),

        Text(
          'Merge, split, compress, convert and protect your PDFs.\nFast, secure, and completely free — right in your browser.',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
            height: 1.7,
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms),

        const SizedBox(height: 36),

        // CTA buttons
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Scrollable.ensureVisible(context);
              },
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text('Get Started Free'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text('Watch Demo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                side: const BorderSide(color: AppTheme.primaryColor),
                foregroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),
          ],
        ),

        const SizedBox(height: 36),

        // Stats
        Wrap(
          spacing: 32,
          runSpacing: 16,
          children: [
            _StatChip(value: '11+', label: 'PDF Tools'),
            _StatChip(value: '100%', label: 'Free'),
            _StatChip(value: '🔒', label: 'Secure'),
          ],
        ).animate().fadeIn(delay: 800.ms),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _HeroIllustration extends StatefulWidget {
  @override
  State<_HeroIllustration> createState() => _HeroIllustrationState();
}

class _HeroIllustrationState extends State<_HeroIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _float.value),
        child: child,
      ),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            // Center icon
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PDF Tools',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Merge • Split • Compress • Convert',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 800.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
