import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../models/pdf_tool.dart';

/// Premium tool tile used on Home and Tools screens.
class ToolCard extends StatefulWidget {
  final PdfTool tool;
  final int index;
  final bool featured;

  const ToolCard({
    super.key,
    required this.tool,
    required this.index,
    this.featured = false,
  });

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tool = widget.tool;
    final elevated = _hovered || _pressed;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => Navigator.pushNamed(context, '/tool/${tool.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: elevated
              ? (Matrix4.identity()..translate(0.0, -5.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: tool.color.withOpacity(elevated ? 0.28 : 0.12),
                blurRadius: elevated ? 28 : 14,
                offset: Offset(0, elevated ? 14 : 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Base surface
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF151B2E) : Colors.white,
                      border: Border.all(
                        color: elevated
                            ? tool.color.withOpacity(0.45)
                            : (isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.06)),
                      ),
                    ),
                  ),
                ),
                // Accent wash
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          tool.color.withOpacity(isDark ? 0.35 : 0.22),
                          tool.color.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Top accent line
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tool.color.withOpacity(0.15),
                          tool.color,
                          tool.color.withOpacity(0.15),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(widget.featured ? 16 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IconBadge(tool: tool, elevated: elevated),
                          const Spacer(),
                          _OpenButton(tool: tool, visible: elevated || !kIsWeb),
                        ],
                      ),
                      SizedBox(height: widget.featured ? 14 : 12),
                      Text(
                        tool.title,
                        style: GoogleFonts.poppins(
                          fontSize: widget.featured ? 15 : 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: isDark ? Colors.white : const Color(0xFF121826),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          tool.subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            height: 1.4,
                            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                          ),
                          maxLines: widget.featured ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.featured) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tool.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Popular',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: tool.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (35 * widget.index).ms, duration: 380.ms)
        .slideY(begin: 0.12, curve: Curves.easeOutCubic);
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.tool, required this.elevated});

  final PdfTool tool;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tool.color.withOpacity(elevated ? 0.95 : 0.85),
            tool.color.withOpacity(0.55),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: tool.color.withOpacity(elevated ? 0.4 : 0.25),
            blurRadius: elevated ? 16 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(tool.icon, color: Colors.white, size: 24),
    );
  }
}

class _OpenButton extends StatelessWidget {
  const _OpenButton({required this.tool, required this.visible});

  final PdfTool tool;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: visible ? 1 : 0.35,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: visible ? 1 : 0.92,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: visible
                ? tool.color
                : tool.color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: tool.color.withOpacity(0.2)),
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 15,
            color: visible ? Colors.white : tool.color,
          ),
        ),
      ),
    );
  }
}

/// Wide featured card for horizontal carousel.
class FeaturedToolCard extends StatelessWidget {
  final PdfTool tool;
  final VoidCallback onTap;
  final double height;

  const FeaturedToolCard({
    super.key,
    required this.tool,
    required this.onTap,
    this.height = 176,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: 260,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tool.color,
                Color.lerp(tool.color, AppTheme.primaryDark, 0.35)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: tool.color.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(tool.icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                Text(
                  tool.title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  tool.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.3,
                    color: Colors.white.withOpacity(0.88),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Open tool',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(isDark ? 1 : 0.95),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
