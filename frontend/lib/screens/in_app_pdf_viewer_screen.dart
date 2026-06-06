import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'pdf_canvas_editor_screen.dart';

/// Full-screen in-app PDF viewer featuring smooth pinch-to-zoom, panning,
/// native text selection/copying, and text annotations (Highlight/Underline).
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
  late PdfViewerController _pdfViewerController;
  PdfAnnotationMode _annotationMode = PdfAnnotationMode.none;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
  }

  void _zoomOut() {
    _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
  }
  
  void _setAnnotationMode(PdfAnnotationMode mode) {
    setState(() {
      if (_annotationMode == mode) {
        _annotationMode = PdfAnnotationMode.none; // Toggle off
      } else {
        _annotationMode = mode;
      }
      _pdfViewerController.annotationMode = _annotationMode;
    });
  }

  void _openEditor() async {
    // Preserve any newly drawn annotations by saving the document first
    List<int> bytesToPass = widget.bytes;
    try {
      final savedBytes = await _pdfViewerController.saveDocument();
      bytesToPass = savedBytes;
    } catch (e) {
      // Ignore if failed, use original bytes
    }
    
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfCanvasEditorScreen(
          bytes: Uint8List.fromList(bytesToPass),
          fileName: widget.fileName,
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final bytes = await _pdfViewerController.saveDocument();
      if (!mounted) return;
      await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: widget.fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annotated PDF exported!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
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
            onPressed: _zoomOut,
          ),
          IconButton(
            tooltip: 'Zoom in',
            icon: const Icon(Icons.zoom_in_rounded),
            onPressed: _zoomIn,
          ),
          if (_exporting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              tooltip: 'Export/Save Annotated PDF',
              icon: const Icon(Icons.save_alt_rounded),
              onPressed: _exportPdf,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SfPdfViewerTheme(
              data: SfPdfViewerThemeData(
                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              ),
              child: SfPdfViewer.memory(
                widget.bytes,
                controller: _pdfViewerController,
                enableTextSelection: true,
                canShowScrollHead: true,
                canShowScrollStatus: true,
              ),
            ),
          ),
          _buildToolbar(isDark),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isDark) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _annotationBtn(
              icon: Icons.highlight_rounded,
              label: 'Highlight',
              mode: PdfAnnotationMode.highlight,
              color: Colors.yellow.shade800,
            ),
            _annotationBtn(
              icon: Icons.format_underline_rounded,
              label: 'Underline',
              mode: PdfAnnotationMode.underline,
              color: Colors.blueAccent,
            ),
            _annotationBtn(
              icon: Icons.format_strikethrough_rounded,
              label: 'Strike',
              mode: PdfAnnotationMode.strikethrough,
              color: Colors.redAccent,
            ),
            Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3)),
            _annotationBtn(
              icon: Icons.add_photo_alternate_outlined,
              label: 'Add Overlay',
              mode: PdfAnnotationMode.none, // Just a visual distinct button
              color: const Color(0xFF8B5CF6),
              isOverlayBtn: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _annotationBtn({
    required IconData icon,
    required String label,
    required PdfAnnotationMode mode,
    required Color color,
    bool isOverlayBtn = false,
  }) {
    final bool isSelected = !isOverlayBtn && _annotationMode == mode;
    
    return InkWell(
      onTap: isOverlayBtn ? _openEditor : () => _setAnnotationMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected || isOverlayBtn ? color : Colors.grey, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected || isOverlayBtn ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
