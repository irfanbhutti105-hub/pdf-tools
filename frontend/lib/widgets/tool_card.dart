import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pdf_tool.dart';

class ToolCard extends StatefulWidget {
  final PdfTool tool;
  final int index;
  const ToolCard({super.key, required this.tool, required this.index});

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tool = widget.tool;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/tool/${tool.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: _hovered
              ? (Matrix4.identity()..translate(0.0, -4.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16213E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? tool.color.withOpacity(0.5)
                  : (isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.07)),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: tool.color.withOpacity(0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with gradient background
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _hovered
                      ? tool.color.withOpacity(0.18)
                      : tool.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  tool.icon,
                  color: tool.color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                tool.title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                tool.subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: isDark ? Colors.white54 : Colors.black45,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Arrow chip
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hovered ? 1.0 : 0.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tool.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: tool.color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (40 * widget.index).ms, duration: 400.ms)
        .slideY(begin: 0.15, curve: Curves.easeOut);
  }
}
