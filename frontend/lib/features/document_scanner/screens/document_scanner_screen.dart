import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';

import '../../../core/app_theme.dart';
import '../models/scanned_page.dart';
import '../services/document_scanner_service.dart';

class DocumentScannerScreen extends StatefulWidget {
  final bool isActive;

  const DocumentScannerScreen({super.key, required this.isActive});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen>
    with AutomaticKeepAliveClientMixin {
  final List<ScannedPage> _pages = [];
  int _selectedIndex = 0;
  bool _isScanning = false;
  bool _isExporting = false;
  bool _autoStarted = false;

  ScanPageSize _pageSize = ScanPageSize.a4;
  bool _landscape = false;
  double _margin = 20;
  bool _applyFilterToAll = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoScan());
  }

  @override
  void didUpdateWidget(covariant DocumentScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _maybeAutoScan();
    }
  }

  void _maybeAutoScan() {
    if (!widget.isActive || _isScanning || _pages.isNotEmpty || _autoStarted) {
      return;
    }
    _autoStarted = true;
    _startScan();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    try {
      final remaining = 30 - _pages.length;
      if (remaining <= 0) {
        _showMessage('Maximum 30 pages per document.');
        return;
      }

      final scanned = await DocumentScannerService.scanDocuments(
        maxPages: remaining,
        allowGallery: true,
      );

      if (!mounted || scanned.isEmpty) return;

      setState(() {
        for (final bytes in scanned) {
          _pages.add(ScannedPage(
            id: const Uuid().v4(),
            originalBytes: bytes,
          ));
        }
        _selectedIndex = _pages.length - 1;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        e.toString().contains('Permission')
            ? 'Camera permission is required to scan documents.'
            : 'Could not open scanner. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  ScannedPage? get _selectedPage =>
      _pages.isEmpty ? null : _pages[_selectedIndex.clamp(0, _pages.length - 1)];

  void _deletePage(int index) {
    setState(() {
      _pages.removeAt(index);
      if (_pages.isEmpty) {
        _selectedIndex = 0;
        _autoStarted = false;
      } else if (_selectedIndex >= _pages.length) {
        _selectedIndex = _pages.length - 1;
      }
    });
  }

  Future<void> _rotateSelected() async {
    final page = _selectedPage;
    if (page == null) return;
    setState(() => page.rotation = (page.rotation + 1) % 4);
    await page.computeDisplayBytes();
    if (mounted) setState(() {});
  }

  Future<void> _setFilter(ScanFilter filter) async {
    final page = _selectedPage;
    if (page == null) return;

    setState(() {
      if (_applyFilterToAll) {
        for (final p in _pages) {
          p.filter = filter;
        }
      } else {
        page.filter = filter;
      }
    });

    // Compute in background for all affected pages.
    if (_applyFilterToAll) {
      await Future.wait(_pages.map((p) => p.computeDisplayBytes()));
    } else {
      await page.computeDisplayBytes();
    }
    if (mounted) setState(() {});
  }

  Future<void> _exportPdf() async {
    if (_pages.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);

    try {
      // Ensure all pages have their processed bytes ready.
      await Future.wait(_pages.map((p) => p.computeDisplayBytes()));

      final pageBytes = _pages.map((p) => p.displayBytes).toList();
      final pdfBytes = await DocumentScannerService.buildPdf(
        pages: pageBytes,
        pageSize: _pageSize,
        landscape: _landscape,
        marginPt: _margin,
      );

      if (!mounted) return;

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'scanned_document_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) _showMessage('Failed to create PDF: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ScannerSettingsSheet(
        pageSize: _pageSize,
        landscape: _landscape,
        margin: _margin,
        applyFilterToAll: _applyFilterToAll,
        onPageSizeChanged: (v) => setState(() => _pageSize = v),
        onLandscapeChanged: (v) => setState(() => _landscape = v),
        onMarginChanged: (v) => setState(() => _margin = v),
        onApplyFilterToAllChanged: (v) => setState(() => _applyFilterToAll = v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isScanning && _pages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Opening camera…',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    if (_pages.isEmpty) {
      return _EmptyScannerView(
        isScanning: _isScanning,
        onScan: _startScan,
        onSettings: _openSettings,
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PreviewCard(page: _selectedPage!),
                const SizedBox(height: 14),
                _FilterStrip(
                  selected: _selectedPage!.filter,
                  onSelected: _setFilter,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'Pages (${_pages.length})',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _isScanning ? null : _startScan,
                      icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                      label: Text('Add', style: GoogleFonts.poppins()),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _PageThumbnailStrip(
                  pages: _pages,
                  selectedIndex: _selectedIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _pages.removeAt(oldIndex);
                      _pages.insert(newIndex, item);
                      _selectedIndex = newIndex;
                    });
                  },
                  onDelete: _deletePage,
                ),
              ],
            ),
          ),
        ),
        _ScannerActionBar(
          isScanning: _isScanning,
          isExporting: _isExporting,
          onScan: _startScan,
          onRotate: _rotateSelected,
          onSettings: _openSettings,
          onExport: _exportPdf,
          onClear: () {
            setState(() {
              _pages.clear();
              _selectedIndex = 0;
              _autoStarted = false;
            });
          },
        ),
      ],
    );
  }
}

class _EmptyScannerView extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onScan;
  final VoidCallback onSettings;

  const _EmptyScannerView({
    required this.isScanning,
    required this.onScan,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onSettings,
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Scanner settings',
            ),
          ),
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.15),
                  AppTheme.secondaryColor.withOpacity(0.12),
                ],
              ),
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              size: 56,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Document Scanner',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan receipts, notes, IDs, and contracts with edge detection, filters, and multi-page PDF export.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 28),
          _FeatureChips(isDark: isDark),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isScanning ? null : onScan,
              icon: isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_rounded),
              label: Text(
                isScanning ? 'Opening camera…' : 'Scan document',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChips extends StatelessWidget {
  final bool isDark;
  const _FeatureChips({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const features = [
      ('Auto crop', Icons.crop_free_rounded),
      ('Multi-page', Icons.layers_rounded),
      ('Filters', Icons.auto_fix_high_rounded),
      ('Reorder', Icons.swap_vert_rounded),
      ('PDF export', Icons.picture_as_pdf_rounded),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: features
          .map(
            (f) => Chip(
              avatar: Icon(f.$2, size: 16, color: AppTheme.primaryColor),
              label: Text(f.$1, style: GoogleFonts.poppins(fontSize: 12)),
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.06)
                  : AppTheme.primaryColor.withOpacity(0.08),
              side: BorderSide.none,
            ),
          )
          .toList(),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final ScannedPage page;
  const _PreviewCard({required this.page});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2235) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              page.displayBytes,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
            if (page.isProcessing)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  final ScanFilter selected;
  final ValueChanged<ScanFilter> onSelected;

  const _FilterStrip({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ScanFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = ScanFilter.values[index];
          final isSelected = filter == selected;
          return ChoiceChip(
            label: Text(
              DocumentScannerService.filterLabel(filter),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : null,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(filter),
            selectedColor: AppTheme.primaryColor,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white10
                : Colors.black.withOpacity(0.04),
          );
        },
      ),
    );
  }
}

class _PageThumbnailStrip extends StatelessWidget {
  final List<ScannedPage> pages;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onDelete;

  const _PageThumbnailStrip({
    required this.pages,
    required this.selectedIndex,
    required this.onSelect,
    required this.onReorder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pages.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final page = pages[index];
        final selected = index == selectedIndex;
        return Material(
          key: ValueKey(page.id),
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Container(
              width: 48,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? AppTheme.primaryColor : Colors.transparent,
                  width: 2,
                ),
                image: DecorationImage(
                  image: MemoryImage(page.displayBytes),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(
              'Page ${index + 1}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              DocumentScannerService.filterLabel(page.filter),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.drag_handle_rounded, color: Colors.grey.shade500),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => onDelete(index),
                ),
              ],
            ),
            selected: selected,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => onSelect(index),
          ),
        );
      },
    );
  }
}

class _ScannerActionBar extends StatelessWidget {
  final bool isScanning;
  final bool isExporting;
  final VoidCallback onScan;
  final VoidCallback onRotate;
  final VoidCallback onSettings;
  final VoidCallback onExport;
  final VoidCallback onClear;

  const _ScannerActionBar({
    required this.isScanning,
    required this.isExporting,
    required this.onScan,
    required this.onRotate,
    required this.onSettings,
    required this.onExport,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121826) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _ActionIcon(
              icon: Icons.photo_camera_rounded,
              label: 'Scan',
              onTap: isScanning ? null : onScan,
            ),
            _ActionIcon(icon: Icons.rotate_right_rounded, label: 'Rotate', onTap: onRotate),
            _ActionIcon(icon: Icons.tune_rounded, label: 'Settings', onTap: onSettings),
            _ActionIcon(icon: Icons.delete_sweep_rounded, label: 'Clear', onTap: onClear),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isExporting ? null : onExport,
                icon: isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: Text(
                  isExporting ? 'Creating…' : 'Export PDF',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionIcon({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: onTap == null ? Colors.grey : AppTheme.primaryColor),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.poppins(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ScannerSettingsSheet extends StatelessWidget {
  final ScanPageSize pageSize;
  final bool landscape;
  final double margin;
  final bool applyFilterToAll;
  final ValueChanged<ScanPageSize> onPageSizeChanged;
  final ValueChanged<bool> onLandscapeChanged;
  final ValueChanged<double> onMarginChanged;
  final ValueChanged<bool> onApplyFilterToAllChanged;

  const _ScannerSettingsSheet({
    required this.pageSize,
    required this.landscape,
    required this.margin,
    required this.applyFilterToAll,
    required this.onPageSizeChanged,
    required this.onLandscapeChanged,
    required this.onMarginChanged,
    required this.onApplyFilterToAllChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Scanner settings', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Text('Page size', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ScanPageSize.values.map((size) {
              return ChoiceChip(
                label: Text(DocumentScannerService.pageSizeLabel(size)),
                selected: pageSize == size,
                onSelected: (_) => onPageSizeChanged(size),
              );
            }).toList(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Landscape orientation', style: GoogleFonts.poppins()),
            value: landscape,
            onChanged: onLandscapeChanged,
          ),
          Text('Margin (${margin.round()} pt)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          Slider(
            value: margin,
            min: 0,
            max: 48,
            divisions: 12,
            label: margin.round().toString(),
            onChanged: onMarginChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Apply filter to all pages', style: GoogleFonts.poppins()),
            subtitle: Text('When off, filters apply only to the selected page.',
                style: GoogleFonts.poppins(fontSize: 12)),
            value: applyFilterToAll,
            onChanged: onApplyFilterToAllChanged,
          ),
        ],
      ),
    );
  }
}
