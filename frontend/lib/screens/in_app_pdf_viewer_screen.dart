import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

import 'pdf_canvas_editor_screen.dart';

/// Full-screen in-app PDF viewer (no external app or browser tab).
class InAppPdfViewerScreen extends StatefulWidget {
  final Uint8List bytes;
  final String fileName;

  const InAppPdfViewerScreen({
    super.key,
    required this.bytes,
    required this.fileName,
  });

  @override
  State<InAppPdfViewerScreen> createState() => _InAppPdfViewerScreenState();
}

class _InAppPdfViewerScreenState extends State<InAppPdfViewerScreen> {
  static const double _minScale = 0.6;
  static const double _maxScale = 3.0;

  double _scale = 1.0;

  void _zoomBy(double factor) {
    setState(() {
      _scale = (_scale * factor).clamp(_minScale, _maxScale);
    });
  }

  void _resetZoom() {
    setState(() => _scale = 1.0);
  }

  void _openEditor() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfCanvasEditorScreen(
          bytes: widget.bytes,
          fileName: widget.fileName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Zoom out',
            icon: const Icon(Icons.zoom_out_rounded),
            onPressed: () => _zoomBy(0.85),
          ),
          IconButton(
            tooltip: 'Reset zoom',
            icon: const Icon(Icons.fit_screen_rounded),
            onPressed: _resetZoom,
          ),
          IconButton(
            tooltip: 'Zoom in',
            icon: const Icon(Icons.zoom_in_rounded),
            onPressed: () => _zoomBy(1.18),
          ),
          IconButton(
            tooltip: 'Edit PDF',
            icon: const Icon(Icons.edit_rounded),
            onPressed: _openEditor,
          ),
        ],
      ),
      body: Transform.scale(
        scale: _scale,
        alignment: Alignment.topCenter,
        child: PdfPreview(
          build: (_) => widget.bytes,
          allowPrinting: false,
          allowSharing: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: kDebugMode,
          scrollViewDecoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          ),
          pdfPreviewPageDecoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
