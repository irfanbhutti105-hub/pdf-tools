import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/editor_layer.dart';

class _PdfPageData {
  _PdfPageData({required this.raster, required this.layers});

  final PdfRaster raster;
  final List<EditorLayer> layers;

  PdfPageFormat get pageFormat {
    const dpi = _kRasterDpi;
    return PdfPageFormat(
      raster.width / dpi * PdfPageFormat.inch,
      raster.height / dpi * PdfPageFormat.inch,
    );
  }
}

const double _kRasterDpi = 144;

/// Visual PDF editor: pages as canvas with movable text and images (Canva-style)
/// featuring rich typography, alignment, and interactive resizing.
class PdfCanvasEditorScreen extends StatefulWidget {
  final Uint8List bytes;
  final String fileName;

  const PdfCanvasEditorScreen({
    super.key,
    required this.bytes,
    required this.fileName,
  });

  @override
  State<PdfCanvasEditorScreen> createState() => _PdfCanvasEditorScreenState();
}

class _PdfCanvasEditorScreenState extends State<PdfCanvasEditorScreen> {
  final PageController _pageController = PageController();

  static const double _minScale = 0.5;
  static const double _maxScale = 3.0;

  List<_PdfPageData> _pages = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  String? _selectedLayerId;
  bool _exporting = false;
  double _canvasScale = 1.0;

  final List<Color> _palette = [
    Colors.black, Colors.white, Colors.grey, 
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown,
  ];

  final List<String> _fontFamilies = [
    'Poppins', 'Roboto', 'Open Sans', 'Helvetica', 'Times', 'Courier'
  ];

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPages() async {
    try {
      final loaded = <_PdfPageData>[];
      await for (final raster in Printing.raster(widget.bytes, dpi: _kRasterDpi)) {
        loaded.add(_PdfPageData(raster: raster, layers: []));
      }
      if (loaded.isEmpty) {
        throw Exception('No pages found in this PDF.');
      }
      if (!mounted) return;
      setState(() {
        _pages = loaded;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _zoomBy(double factor) {
    setState(() {
      _canvasScale = (_canvasScale * factor).clamp(_minScale, _maxScale);
    });
  }

  void _resetZoom() {
    setState(() => _canvasScale = 1.0);
  }

  void _addTextLayer() {
    setState(() {
      _pages[_currentPage].layers.add(
        EditorLayer(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: EditorLayerType.text,
        ),
      );
      _selectedLayerId = _pages[_currentPage].layers.last.id;
    });
  }

  Future<void> _addImageLayer() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
      return;
    }
    setState(() {
      _pages[_currentPage].layers.add(
        EditorLayer(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: EditorLayerType.image,
          relWidth: 0.4,
          relHeight: 0.3,
          imageBytes: result.files.first.bytes,
        ),
      );
      _selectedLayerId = _pages[_currentPage].layers.last.id;
    });
  }

  Future<void> _editTextLayer(EditorLayer layer) async {
    final controller = TextEditingController(text: layer.text);
    
    // Create local copies of state to modify in dialog
    double size = layer.fontSizePt;
    String family = layer.fontFamily;
    bool bold = layer.isBold;
    bool italic = layer.isItalic;
    bool underline = layer.isUnderline;
    TextAlign align = layer.textAlign;
    Color color = layer.color;
    double opacity = layer.opacity;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Typography Options', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx, false)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Text Content',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _fontFamilies.contains(family) ? family : 'Poppins',
                          decoration: const InputDecoration(labelText: 'Font', border: OutlineInputBorder()),
                          items: _fontFamilies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                          onChanged: (v) => setSheetState(() => family = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<TextAlign>(
                          value: align,
                          decoration: const InputDecoration(labelText: 'Alignment', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: TextAlign.left, child: Text('Left')),
                            DropdownMenuItem(value: TextAlign.center, child: Text('Center')),
                            DropdownMenuItem(value: TextAlign.right, child: Text('Right')),
                          ],
                          onChanged: (v) => setSheetState(() => align = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilterChip(
                        label: const Text('B', style: TextStyle(fontWeight: FontWeight.bold)),
                        selected: bold,
                        onSelected: (v) => setSheetState(() => bold = v),
                      ),
                      FilterChip(
                        label: const Text('I', style: TextStyle(fontStyle: FontStyle.italic)),
                        selected: italic,
                        onSelected: (v) => setSheetState(() => italic = v),
                      ),
                      FilterChip(
                        label: const Text('U', style: TextStyle(decoration: TextDecoration.underline)),
                        selected: underline,
                        onSelected: (v) => setSheetState(() => underline = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Size: ${size.round()}', style: GoogleFonts.poppins(fontSize: 13)),
                      Expanded(
                        child: Slider(
                          min: 8, max: 120, value: size,
                          onChanged: (v) => setSheetState(() => size = v),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Opacity: ${(opacity * 100).round()}%', style: GoogleFonts.poppins(fontSize: 13)),
                      Expanded(
                        child: Slider(
                          min: 0.1, max: 1.0, value: opacity,
                          onChanged: (v) => setSheetState(() => opacity = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Color Palette', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _palette.map((c) => GestureDetector(
                      onTap: () => setSheetState(() => color = c),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color == c ? Colors.blueAccent : Colors.grey.withOpacity(0.5),
                            width: color == c ? 3 : 1,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Apply Changes'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        layer.text = controller.text.trim().isEmpty ? 'Text' : controller.text;
        layer.fontSizePt = size;
        layer.fontFamily = family;
        layer.isBold = bold;
        layer.isItalic = italic;
        layer.isUnderline = underline;
        layer.textAlign = align;
        layer.color = color;
        layer.opacity = opacity;
      });
    }
    controller.dispose();
  }

  void _deleteLayer(String layerId) {
    setState(() {
      _pages[_currentPage].layers.removeWhere((l) => l.id == layerId);
      if (_selectedLayerId == layerId) _selectedLayerId = null;
    });
  }

  Future<pw.Font> _getFont(String family, bool bold, bool italic) async {
    switch (family) {
      case 'Times':
        if (bold && italic) return pw.Font.timesBoldItalic();
        if (bold) return pw.Font.timesBold();
        if (italic) return pw.Font.timesItalic();
        return pw.Font.times();
      case 'Courier':
        if (bold && italic) return pw.Font.courierBoldOblique();
        if (bold) return pw.Font.courierBold();
        if (italic) return pw.Font.courierOblique();
        return pw.Font.courier();
      case 'Helvetica':
        if (bold && italic) return pw.Font.helveticaBoldOblique();
        if (bold) return pw.Font.helveticaBold();
        if (italic) return pw.Font.helveticaOblique();
        return pw.Font.helvetica();
      case 'Roboto':
        if (bold && italic) return await PdfGoogleFonts.robotoBoldItalic();
        if (bold) return await PdfGoogleFonts.robotoBold();
        if (italic) return await PdfGoogleFonts.robotoItalic();
        return await PdfGoogleFonts.robotoRegular();
      case 'Open Sans':
        if (bold && italic) return await PdfGoogleFonts.openSansBoldItalic();
        if (bold) return await PdfGoogleFonts.openSansBold();
        if (italic) return await PdfGoogleFonts.openSansItalic();
        return await PdfGoogleFonts.openSansRegular();
      case 'Poppins':
      default:
        if (bold && italic) return await PdfGoogleFonts.poppinsBoldItalic();
        if (bold) return await PdfGoogleFonts.poppinsBold();
        if (italic) return await PdfGoogleFonts.poppinsItalic();
        return await PdfGoogleFonts.poppinsRegular();
    }
  }

  pw.TextAlign _getPdfTextAlign(TextAlign align) {
    switch (align) {
      case TextAlign.center: return pw.TextAlign.center;
      case TextAlign.right: return pw.TextAlign.right;
      case TextAlign.justify: return pw.TextAlign.justify;
      default: return pw.TextAlign.left;
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final doc = pw.Document();
      for (final pageData in _pages) {
        final format = pageData.pageFormat;
        final png = await pageData.raster.toPng();
        
        final pwLayers = <pw.Widget>[
          pw.Image(
            pw.MemoryImage(png),
            width: format.width,
            height: format.height,
            fit: pw.BoxFit.fill,
          ),
        ];

        for (final layer in pageData.layers) {
          if (layer.type == EditorLayerType.text) {
            final font = await _getFont(layer.fontFamily, layer.isBold, layer.isItalic);
            final c = layer.color;
            
            pwLayers.add(
              pw.Positioned(
                left: layer.relX * format.width,
                top: layer.relY * format.height,
                child: pw.Opacity(
                  opacity: layer.opacity,
                  child: pw.Text(
                    layer.text,
                    textAlign: _getPdfTextAlign(layer.textAlign),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: layer.fontSizePt,
                      color: PdfColor(c.red / 255.0, c.green / 255.0, c.blue / 255.0),
                      decoration: layer.isUnderline ? pw.TextDecoration.underline : pw.TextDecoration.none,
                    ),
                  ),
                ),
              ),
            );
          } else if (layer.imageBytes != null) {
            pwLayers.add(
              pw.Positioned(
                left: layer.relX * format.width,
                top: layer.relY * format.height,
                child: pw.Opacity(
                  opacity: layer.opacity,
                  child: pw.SizedBox(
                    width: layer.relWidth * format.width,
                    height: layer.relHeight * format.height,
                    child: pw.Image(
                      pw.MemoryImage(layer.imageBytes!),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ),
            );
          }
        }

        doc.addPage(
          pw.Page(
            pageFormat: format,
            margin: pw.EdgeInsets.zero,
            build: (context) => pw.Stack(children: pwLayers),
          ),
        );
      }

      final bytes = await doc.save();
      if (!mounted) return;
      await Printing.sharePdf(bytes: bytes, filename: widget.fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported — use share/save from the sheet')),
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
    const accent = Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PDF Editor',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (!_loading && _pages.isNotEmpty)
              Text(
                widget.fileName,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Zoom out',
            icon: const Icon(Icons.zoom_out_rounded),
            onPressed: _loading ? null : () => _zoomBy(0.85),
          ),
          IconButton(
            tooltip: 'Fit to screen',
            icon: const Icon(Icons.fit_screen_rounded),
            onPressed: _loading ? null : _resetZoom,
          ),
          IconButton(
            tooltip: 'Zoom in',
            icon: const Icon(Icons.zoom_in_rounded),
            onPressed: _loading ? null : () => _zoomBy(1.18),
          ),
          if (_exporting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              tooltip: 'Export PDF',
              icon: const Icon(Icons.save_alt_rounded),
              onPressed: _loading || _error != null ? null : _exportPdf,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    if (_selectedLayerId != null) {
                      setState(() => _selectedLayerId = null);
                    }
                  },
                  child: Column(
                    children: [
                      _buildPageStrip(isDark, accent),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _pages.length,
                          onPageChanged: (i) => setState(() {
                            _currentPage = i;
                            _selectedLayerId = null;
                          }),
                          itemBuilder: (context, index) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Center(
                                child: Transform.scale(
                                  scale: _canvasScale,
                                  alignment: Alignment.topCenter,
                                  child: _buildPageCanvas(index, isDark),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      _buildToolbar(isDark, accent),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPageStrip(bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Row(
        children: [
          Text(
            'Page ${_currentPage + 1} / ${_pages.length}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _currentPage > 0
                ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    )
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _currentPage < _pages.length - 1
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isDark, Color accent) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _toolChip(
                icon: Icons.text_fields_rounded,
                label: 'Add text',
                color: accent,
                onTap: _addTextLayer,
              ),
              const SizedBox(width: 8),
              _toolChip(
                icon: Icons.image_rounded,
                label: 'Add image',
                color: accent,
                onTap: _addImageLayer,
              ),
              if (_selectedLayerId != null) ...[
                const SizedBox(width: 8),
                Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(width: 8),
                _toolChip(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  color: Colors.blueAccent,
                  onTap: () {
                    final layer = _pages[_currentPage].layers.firstWhere((l) => l.id == _selectedLayerId);
                    if (layer.type == EditorLayerType.text) _editTextLayer(layer);
                  },
                ),
                const SizedBox(width: 8),
                _toolChip(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: Colors.redAccent,
                  onTap: () => _deleteLayer(_selectedLayerId!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageCanvas(int pageIndex, bool isDark) {
    final page = _pages[pageIndex];
    final aspect = page.raster.width / page.raster.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        final w = maxW.clamp(280.0, 520.0);
        final h = w / aspect;

        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Image(
                    image: PdfRasterImage(page.raster),
                    fit: BoxFit.fill,
                  ),
                ),
                ...page.layers.map(
                  (layer) => _buildLayer(layer, w, h, pageIndex),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayer(EditorLayer layer, double pageW, double pageH, int pageIndex) {
    final selected = _selectedLayerId == layer.id;
    final left = layer.relX * pageW;
    final top = layer.relY * pageH;
    final width = layer.relWidth * pageW;
    final height = layer.relHeight * pageH;

    Widget child;
    if (layer.type == EditorLayerType.text) {
      final format = _pages[pageIndex].pageFormat;
      final fontSize = layer.fontSizePt * (pageW / format.width);
      
      final String safeFont = ['Times', 'Helvetica', 'Courier'].contains(layer.fontFamily) 
          ? 'Roboto' // Display fallback for native UI
          : layer.fontFamily;
          
      child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? const Color(0x338B5CF6) : Colors.transparent,
          border: Border.all(
            color: selected ? const Color(0xFF8B5CF6) : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Opacity(
          opacity: layer.opacity,
          child: Text(
            layer.text,
            textAlign: layer.textAlign,
            style: GoogleFonts.getFont(
              safeFont,
              fontSize: fontSize.clamp(8, 200),
              color: layer.color,
              fontWeight: layer.isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: layer.isItalic ? FontStyle.italic : FontStyle.normal,
              decoration: layer.isUnderline ? TextDecoration.underline : TextDecoration.none,
            ).merge(
              TextStyle(
                fontFamily: layer.fontFamily == 'Times' ? 'Times New Roman' : 
                            layer.fontFamily == 'Courier' ? 'Courier New' : 
                            layer.fontFamily == 'Helvetica' ? 'Arial' : null,
              )
            ),
          ),
        ),
      );
    } else {
      child = Opacity(
        opacity: layer.opacity,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? const Color(0xFF8B5CF6) : Colors.transparent,
              width: selected ? 2 : 1,
            ),
          ),
          child: layer.imageBytes != null
              ? Image.memory(layer.imageBytes!, fit: BoxFit.contain)
              : const Icon(Icons.broken_image_outlined),
        ),
      );
    }

    return Positioned(
      left: left,
      top: top,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _selectedLayerId = layer.id);
            },
            onDoubleTap: () {
              if (layer.type == EditorLayerType.text) _editTextLayer(layer);
            },
            onPanUpdate: (details) {
              setState(() {
                layer.relX = (layer.relX + details.delta.dx / pageW).clamp(-0.1, 1.0);
                layer.relY = (layer.relY + details.delta.dy / pageH).clamp(-0.1, 1.0);
                _selectedLayerId = layer.id;
              });
            },
            child: child,
          ),
          if (selected)
            Positioned(
              right: -10,
              bottom: -10,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    if (layer.type == EditorLayerType.image) {
                      layer.relWidth = (layer.relWidth + details.delta.dx / pageW).clamp(0.05, 1.0);
                      layer.relHeight = (layer.relHeight + details.delta.dy / pageH).clamp(0.05, 1.0);
                    } else if (layer.type == EditorLayerType.text) {
                      // Scale text dynamically based on downward diagonal drag
                      layer.fontSizePt = (layer.fontSizePt + details.delta.dy * 0.5).clamp(8.0, 120.0);
                    }
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Icon(Icons.open_in_full_rounded, size: 14, color: Color(0xFF8B5CF6)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
