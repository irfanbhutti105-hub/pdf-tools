import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProcessingPanel extends StatelessWidget {
  final bool isProcessing;
  final double progress;
  final bool isDone;
  final String? error;
  final Color toolColor;
  final String outputFileName;
  final VoidCallback? onDownload;

  const ProcessingPanel({
    super.key,
    required this.isProcessing,
    required this.progress,
    required this.isDone,
    required this.error,
    required this.toolColor,
    required this.outputFileName,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Error state
    if (error != null) {
      return _Panel(
        isDark: isDark,
        borderColor: Colors.redAccent.withOpacity(0.4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Processing Failed',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                  Text(
                    error!,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.redAccent.withOpacity(0.8)),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Processing state
    if (isProcessing) {
      return _Panel(
        isDark: isDark,
        borderColor: toolColor.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: toolColor,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Processing your file…',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: toolColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                minHeight: 6,
                backgroundColor:
                    isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(toolColor),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait. Your file is being processed on the server.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    // Done state
    if (isDone) {
      return _Panel(
        isDark: isDark,
        borderColor: const Color(0xFF43C6AC).withOpacity(0.4),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43C6AC).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF43C6AC), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processing Complete! 🎉',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF43C6AC),
                        ),
                      ),
                      Text(
                        outputFileName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43C6AC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '🔒 Your file will be auto-deleted from our servers in 1 hour.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _Panel extends StatelessWidget {
  final bool isDark;
  final Color borderColor;
  final Widget child;
  const _Panel(
      {required this.isDark, required this.borderColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
