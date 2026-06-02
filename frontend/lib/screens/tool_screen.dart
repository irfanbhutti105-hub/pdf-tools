import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import '../core/app_theme.dart';
import '../data/tools_data.dart';
import '../models/pdf_tool.dart';
import '../services/pdf_api_service.dart';
import '../widgets/app_navbar.dart';
import '../widgets/drop_zone_widget.dart';
import '../widgets/processing_panel.dart';
import 'package:dio/dio.dart' as dio;
import 'package:universal_html/html.dart' as html;
import 'package:open_file/open_file.dart';
import 'dart:convert';

class ToolScreen extends StatefulWidget {
  final String toolId;
  const ToolScreen({super.key, required this.toolId});

  @override
  State<ToolScreen> createState() => _ToolScreenState();
}

class _ToolScreenState extends State<ToolScreen> {
  PdfTool? _tool;
  List<PlatformFile> _pickedFiles = [];

  // Options
  String _splitRanges = '';
  bool _splitEveryPage = false;
  String _compressLevel = 'medium';
  int _rotateAngle = 90;
  String _watermarkText = 'CONFIDENTIAL';
  double _watermarkOpacity = 0.3;
  String _password = '';
  String _imageOrientation = 'portrait';
  
  final quill.QuillController _quillController = quill.QuillController.basic();

  // State
  bool _isProcessing = false;
  double _uploadProgress = 0;
  String? _errorMessage;
  bool _done = false;
  List<int>? _resultBytes;

  @override
  void initState() {
    super.initState();
    _tool = allTools.firstWhere(
      (t) => t.id == widget.toolId,
      orElse: () => allTools.first,
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: _tool!.multiFile,
      type: _tool!.acceptedExtensions.contains('pdf')
          ? FileType.custom
          : FileType.image,
      allowedExtensions: _tool!.acceptedExtensions,
      withData: true,
    );
    if (result != null) {
      setState(() {
        _pickedFiles = result.files;
        _errorMessage = null;
        _done = false;
      });
    }
  }

  void _removeFile(int index) {
    setState(() => _pickedFiles.removeAt(index));
  }

  Future<void> _process() async {
    final bool hasText = _tool!.id == 'text-to-pdf' && !_quillController.document.isEmpty();
    if (_pickedFiles.isEmpty && !hasText) {
      setState(() => _errorMessage = 'Please select at least one file or enter some text.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _uploadProgress = 0;
      _errorMessage = null;
      _done = false;
      _resultBytes = null;
    });

    try {
      await _processFiles();
      setState(() => _done = true);
    } catch (e) {
      String err = e.toString();
      if (e is dio.DioException && e.response?.data != null) {
        try {
          final data = e.response!.data;
          if (data is List<int>) {
            final str = utf8.decode(data);
            final json = jsonDecode(str);
            if (json['detail'] != null) {
              err = json['detail'].toString();
            }
          } else if (data is String) {
            final json = jsonDecode(data);
            if (json['detail'] != null) err = json['detail'].toString();
          }
        } catch (_) {}
      }
      setState(() => _errorMessage = err.replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processFiles() async {
    List<PlatformFile> files = _pickedFiles.where((f) => f.bytes != null).toList();
    
    if (_tool!.id == 'text-to-pdf' && !_quillController.document.isEmpty()) {
      final delta = _quillController.document.toDelta().toJson();
      final converter = QuillDeltaToHtmlConverter(
        List.castFrom(delta),
        ConverterOptions.forEmail(),
      );
      final html = converter.convert();
      final bytes = utf8.encode(html);
      files = [PlatformFile(name: 'input.txt', size: bytes.length, bytes: bytes)];
    }

    if (files.isEmpty) {
      throw Exception('Could not read file data. Please try again.');
    }

    onProgress(int sent, int total) {
      setState(() => _uploadProgress = sent / total);
    }

    dio.Response? response;

    switch (_tool!.id) {
      case 'merge':
        response = await PdfApiService.mergePdfs(files, onSendProgress: onProgress);
        break;
      case 'split':
        response = await PdfApiService.splitPdf(
          files.first,
          ranges: _splitRanges.isEmpty ? null : _splitRanges,
          everyPage: _splitEveryPage,
          onSendProgress: onProgress,
        );
        break;
      case 'compress':
        response = await PdfApiService.compressPdf(files.first,
            level: _compressLevel, onSendProgress: onProgress);
        break;
      case 'rotate':
        response = await PdfApiService.rotatePdf(files.first,
            angle: _rotateAngle, onSendProgress: onProgress);
        break;
      case 'watermark':
        response = await PdfApiService.watermarkPdf(files.first,
            text: _watermarkText,
            opacity: _watermarkOpacity,
            onSendProgress: onProgress);
        break;
      case 'protect':
        response = await PdfApiService.protectPdf(files.first,
            password: _password, onSendProgress: onProgress);
        break;
      case 'unlock':
        response = await PdfApiService.unlockPdf(files.first,
            password: _password, onSendProgress: onProgress);
        break;
      case 'images-to-pdf':
        response = await PdfApiService.imagesToPdf(files,
            orientation: _imageOrientation, onSendProgress: onProgress);
        break;
      case 'pdf-to-images':
        response = await PdfApiService.pdfToImages(files.first, onSendProgress: onProgress);
        break;
      case 'extract-text':
        response = await PdfApiService.extractText(files.first);
        break;
      case 'text-to-pdf':
        response = await PdfApiService.textToPdf(files.first, onSendProgress: onProgress);
        break;
      case 'info':
        response = await PdfApiService.getPdfInfo(files.first);
        break;
    }

    if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
      if (response.data is List<int>) {
        _resultBytes = response.data as List<int>;
      } else if (response.data is String) {
        _resultBytes = (response.data as String).codeUnits;
      } else {
        // For info and extract-text, which return JSON, we could convert it to string
        _resultBytes = utf8.encode(jsonEncode(response.data));
      }
    } else if (response != null) {
      throw Exception('Server returned an error: ${response.statusCode}');
    }
  }

  Future<void> _downloadResult() async {
    if (_resultBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file to download.')),
        );
      }
      return;
    }
    
    final outName = _getOutputName();

    if (kIsWeb) {
      final blob = html.Blob([_resultBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', outName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save processed file',
        fileName: outName,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(_resultBytes!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to $outputFile'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  OpenFile.open(outputFile);
                },
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tool == null) {
      return const Scaffold(body: Center(child: Text('Tool not found')));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 900;

    final hasInput = _pickedFiles.isNotEmpty || (_tool!.id == 'text-to-pdf' && !_quillController.document.isEmpty());

    Widget body;
    if (_isProcessing || _done || _errorMessage != null) {
      body = _buildProcessingState(isDark);
    } else if (hasInput) {
      body = _buildSelectedState(isDark, isWide);
    } else {
      body = _buildInitialState(isDark, isWide);
    }

    return Scaffold(
      appBar: AppNavbar(isWide: isWide),
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: body,
    );
  }

  Widget _buildProcessingState(bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProcessingPanel(
              isProcessing: _isProcessing,
              progress: _uploadProgress,
              isDone: _done,
              error: _errorMessage,
              toolColor: _tool!.color,
              outputFileName: _getOutputName(),
              onDownload: _downloadResult,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _done = false;
                  _errorMessage = null;
                  _pickedFiles.clear();
                  _quillController.clear();
                  _resultBytes = null;
                });
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Tool'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(bool isDark, bool isWide) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(_tool!.icon, size: 80, color: _tool!.color),
              const SizedBox(height: 24),
              Text(
                _tool!.title,
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _tool!.subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              if (_tool!.id == 'text-to-pdf')
                Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                        ),
                        child: Column(
                          children: [
                            quill.QuillSimpleToolbar(
                              controller: _quillController,
                              config: const quill.QuillSimpleToolbarConfig(
                                showFontFamily: false,
                                showSearchButton: false,
                                showSubscript: false,
                                showSuperscript: false,
                              ),
                            ),
                            Container(
                              height: 300,
                              padding: const EdgeInsets.all(16),
                              child: quill.QuillEditor.basic(
                                controller: _quillController,
                                config: const quill.QuillEditorConfig(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('OR', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

              InkWell(
                onTap: _pickFiles,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: isWide ? 400 : double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: _tool!.color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _tool!.color.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open_rounded, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          'Select ${_tool!.acceptedExtensions.join('/').toUpperCase()}',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'or drop files here',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        ),
      ),
    );
  }

  Widget _buildSelectedState(bool isDark, bool isWide) {
    final leftContent = Container(
      padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Home',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _pickedFiles.clear();
                      _quillController.clear();
                    });
                  },
                  child: Text(
                    _tool!.title,
                    style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                Text('Options', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 32),
            if (_tool!.id == 'text-to-pdf' && !_quillController.document.isEmpty())
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      quill.QuillSimpleToolbar(
                        controller: _quillController,
                        config: const quill.QuillSimpleToolbarConfig(
                          showFontFamily: false,
                          showSearchButton: false,
                          showSubscript: false,
                          showSuperscript: false,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: quill.QuillEditor.basic(
                            controller: _quillController,
                            config: const quill.QuillEditorConfig(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: _pickedFiles.length,
                  itemBuilder: (context, i) {
                    final f = _pickedFiles[i];
                    return _FileChip(
                      key: ObjectKey(f),
                      file: f,
                      isDark: isDark,
                      showDragHandle: _tool!.multiFile && _pickedFiles.length > 1,
                      index: i,
                      onRemove: () => _removeFile(i),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _pickedFiles.removeAt(oldIndex);
                      _pickedFiles.insert(newIndex, item);
                    });
                  },
                ),
              ),
            if (_tool!.multiFile || _pickedFiles.isEmpty) ...[
              const SizedBox(height: 24),
              Center(
                child: FloatingActionButton(
                  onPressed: _pickFiles,
                  backgroundColor: isDark ? Colors.white10 : Colors.white,
                  elevation: 2,
                  child: Icon(Icons.add_rounded, color: _tool!.color, size: 32),
                ),
              ),
            ]
          ],
        ).animate().fadeIn(),
    );

    final rightSidebar = Container(
      width: isWide ? 380 : double.infinity,
      height: isWide ? double.infinity : null,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_tool!.icon, color: _tool!.color, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _tool!.title,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ..._buildOptions(isDark),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _process,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tool!.color,
                  disabledBackgroundColor: _tool!.color.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text(
                        _tool!.title,
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(children: [Expanded(flex: 3, child: leftContent), rightSidebar]);
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 500, child: leftContent),
            rightSidebar,
          ],
        ),
      );
    }
  }

  String _getOutputName() {
    switch (_tool!.id) {
      case 'merge':
        return 'merged.pdf';
      case 'split':
        return 'split_pages.zip';
      case 'compress':
        return 'compressed.pdf';
      case 'rotate':
        return 'rotated.pdf';
      case 'watermark':
        return 'watermarked.pdf';
      case 'protect':
        return 'protected.pdf';
      case 'unlock':
        return 'unlocked.pdf';
      case 'images-to-pdf':
        return 'images_to_pdf.pdf';
      case 'pdf-to-images':
        return 'pdf_pages.zip';
      case 'text-to-pdf':
        return 'text_to_pdf.pdf';
      case 'info':
        return 'pdf_info.json';
      case 'extract-text':
        return 'extracted_text.json';
      default:
        return 'output.pdf';
    }
  }





  List<Widget> _buildOptions(bool isDark) {
    final labelStyle = GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white70 : Colors.black87,
    );

    switch (_tool!.id) {
      case 'split':
        return [
          Text('Split Mode', style: labelStyle),
          const SizedBox(height: 10),
          _OptionToggle(
            label: 'Split every page into separate PDFs',
            value: _splitEveryPage,
            onChanged: (v) => setState(() => _splitEveryPage = v),
          ),
          if (!_splitEveryPage) ...[
            const SizedBox(height: 16),
            Text('Page Ranges', style: labelStyle),
            const SizedBox(height: 8),
            _StyledTextField(
              hint: 'e.g. 1-3, 5, 7-9',
              onChanged: (v) => _splitRanges = v,
              isDark: isDark,
            ),
          ],
        ];

      case 'compress':
        return [
          Text('Compression Level', style: labelStyle),
          const SizedBox(height: 12),
          ...[
            ('low', 'Low — best quality'),
            ('medium', 'Medium — balanced'),
            ('high', 'High — smallest file'),
          ].map((opt) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(opt.$2, style: GoogleFonts.poppins(fontSize: 13)),
                value: opt.$1,
                groupValue: _compressLevel,
                activeColor: _tool!.color,
                onChanged: (v) => setState(() => _compressLevel = v!),
              )),
        ];

      case 'rotate':
        return [
          Text('Rotation Angle', style: labelStyle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [90, 180, 270].map((angle) {
              final selected = _rotateAngle == angle;
              return ChoiceChip(
                label: Text('$angle°'),
                selected: selected,
                selectedColor: _tool!.color,
                labelStyle: GoogleFonts.poppins(
                  color: selected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _rotateAngle = angle),
              );
            }).toList(),
          ),
        ];

      case 'watermark':
        return [
          Text('Watermark Text', style: labelStyle),
          const SizedBox(height: 8),
          _StyledTextField(
            hint: 'CONFIDENTIAL',
            initialValue: _watermarkText,
            onChanged: (v) => _watermarkText = v,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Text('Opacity: ${(_watermarkOpacity * 100).round()}%', style: labelStyle),
          Slider(
            value: _watermarkOpacity,
            min: 0.05,
            max: 1.0,
            divisions: 19,
            activeColor: _tool!.color,
            onChanged: (v) => setState(() => _watermarkOpacity = v),
          ),
        ];

      case 'protect':
      case 'unlock':
        return [
          Text('Password', style: labelStyle),
          const SizedBox(height: 8),
          _StyledTextField(
            hint: 'Enter password',
            onChanged: (v) => _password = v,
            isDark: isDark,
            obscure: true,
          ),
        ];

      case 'images-to-pdf':
        return [
          Text('Orientation', style: labelStyle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ('portrait', 'Portrait'),
              ('landscape', 'Landscape'),
            ].map((opt) {
              final selected = _imageOrientation == opt.$1;
              return ChoiceChip(
                label: Text(opt.$2),
                selected: selected,
                selectedColor: _tool!.color,
                labelStyle: GoogleFonts.poppins(
                  color: selected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) =>
                    setState(() => _imageOrientation = opt.$1),
              );
            }).toList(),
          ),
        ];

      default:
        return [];
    }
  }
}

// ─── Supporting Widgets ──────────────────────

class _FileChip extends StatelessWidget {
  final PlatformFile file;
  final bool isDark;
  final VoidCallback onRemove;
  final bool showDragHandle;
  final int? index;

  const _FileChip({
    super.key,
    required this.file,
    required this.isDark,
    required this.onRemove,
    this.showDragHandle = false,
    this.index,
  });

  String get _size {
    final bytes = file.size;
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          if (showDragHandle && index != null)
            ReorderableDragStartListener(
              index: index!,
              child: const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Icon(Icons.drag_indicator_rounded, size: 20, color: Colors.grey),
              ),
            ),
          const Icon(Icons.insert_drive_file_rounded,
              size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _size,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _OptionToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _OptionToggle(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: GoogleFonts.poppins(fontSize: 13)),
        ),
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final String hint;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final bool isDark;
  final bool obscure;
  final int maxLines;
  
  const _StyledTextField({
    super.key,
    required this.hint,
    this.initialValue,
    required this.onChanged,
    required this.isDark,
    this.obscure = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      obscureText: obscure,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: isDark ? Colors.white30 : Colors.black26,
        ),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
