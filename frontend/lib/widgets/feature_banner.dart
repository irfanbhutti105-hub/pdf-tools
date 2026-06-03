import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class FeatureBanner extends StatelessWidget {
  const FeatureBanner({super.key});

  static const _features = [
    (
      icon: Icons.security_rounded,
      color: Color(0xFF43C6AC),
      title: 'Secure & Private',
      desc:
          'Files are encrypted in transit and auto-deleted after processing. We never store your data.',
    ),
    (
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFB347),
      title: 'Lightning Fast',
      desc:
          'Optimised processing engine handles large PDFs in seconds, not minutes.',
    ),
    (
      icon: Icons.devices_rounded,
      color: Color(0xFF6C63FF),
      title: 'Works Everywhere',
      desc:
          'Use on any device — desktop, tablet, or mobile. No installation required.',
    ),
    (
      icon: Icons.cloud_done_rounded,
      color: Color(0xFFFF6584),
      title: 'No Sign-Up Needed',
      desc:
          'Jump straight in. All core tools are free with no account required.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: 64,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12122A) : const Color(0xFFF3F3FF),
      ),
      child: Column(
        children: [
          Text(
            'Why Choose PDF Tools?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            'Built for speed, security, and simplicity.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 48),
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _features
                      .asMap()
                      .entries
                      .map((e) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: _FeatureCard(
                                icon: e.value.icon,
                                color: e.value.color,
                                title: e.value.title,
                                desc: e.value.desc,
                                index: e.key,
                              ),
                            ),
                          ))
                      .toList(),
                )
              : Column(
                  children: _features
                      .asMap()
                      .entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _FeatureCard(
                              icon: e.value.icon,
                              color: e.value.color,
                              title: e.value.title,
                              desc: e.value.desc,
                              index: e.key,
                            ),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final int index;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.index,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? widget.color.withOpacity(0.5)
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon, color: widget.color, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.desc,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.6,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: (100 * widget.index).ms)
          .slideY(begin: 0.2, curve: Curves.easeOut),
    );
  }
}
