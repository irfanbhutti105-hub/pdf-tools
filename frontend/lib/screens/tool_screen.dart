import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../data/tools_data.dart';
import '../models/pdf_tool.dart';
import '../providers/favorites_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/theme_provider.dart';
import '../services/pdf_api_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/processing_panel.dart';
import 'in_app_pdf_viewer_screen.dart';
import 'notifications_screen.dart';
import 'pdf_canvas_editor_screen.dart';
import 'package:dio/dio.dart' as dio;
import 'package:universal_html/html.dart' as html;
import 'package:open_file/open_file.dart';
import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart' as q2h;

class ToolScreen extends StatefulWidget {
  final String toolId;
  final Uint8List? initialPdfBytes;
  final String? initialPdfName;

  const ToolScreen({
    super.key,
    required this.toolId,
    this.initialPdfBytes,
    this.initialPdfName,
  });

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

  // New tool options (mutable)
  String _htmlUrl = '';
  String _pageOrder = '';
  String _pageNumberPosition = 'bottom-center';
  int _pageNumberStart = 1;
  String _ocrLanguage = 'eng';
  double _cropLeft = 0;
  double _cropRight = 0;
  double _cropTop = 0;
  double _cropBottom = 0;
  String _redactTerms = '';

  final TextEditingController _textController = TextEditingController();
  late final quill.QuillController _quillController;
  int _selectedInputTab = 0; // 0 = Upload File, 1 = Rich Text Editor

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
    if (_tool!.id == 'pdf-editor') {
      _selectedInputTab = 1;
    }
    _quillController = quill.QuillController.basic();

    if (_tool!.id == 'pdf-editor' &&
        widget.initialPdfBytes != null &&
        widget.initialPdfBytes!.isNotEmpty) {
      final name = widget.initialPdfName ?? 'document.pdf';
      _pickedFiles = [
        PlatformFile(
          name: name,
          size: widget.initialPdfBytes!.length,
          bytes: widget.initialPdfBytes,
        ),
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openCanvasEditor(_pickedFiles.first);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    // Determine file type and extensions
    FileType fileType;
    List<String>? allowedExtensions;

    if (_tool!.acceptedExtensions.isEmpty) {
      // No file picking for this tool (e.g., html-url-to-pdf)
      return;
    } else if (_tool!.acceptedExtensions.contains('pdf')) {
      fileType = FileType.custom;
      allowedExtensions = _tool!.acceptedExtensions;
    } else if (_tool!.acceptedExtensions
        .any((ext) => ['jpg', 'jpeg', 'png'].contains(ext))) {
      fileType = FileType.image;
      allowedExtensions = null; // Don't pass extensions for FileType.image
    } else {
      fileType = FileType.custom;
      allowedExtensions = _tool!.acceptedExtensions;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: _tool!.multiFile,
      type: fileType,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result != null) {
      setState(() {
        _pickedFiles = result.files;
        _errorMessage = null;
        _done = false;
      });
      if (_tool!.id == 'pdf-viewer') {
        final file = result.files.firstOrNull;
        if (file?.bytes != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openPdfInApp(file!);
          });
        }
      } else if (_tool!.id == 'pdf-editor') {
        final file = result.files.firstOrNull;
        if (file?.bytes != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openCanvasEditor(file!);
          });
        }
      }
    }
  }

  void _removeFile(int index) {
    setState(() => _pickedFiles.removeAt(index));
  }

  Future<void> _process() async {
    bool canProcess = false;
    if (_tool!.id == 'pdf-viewer') {
      if (_pickedFiles.isNotEmpty && _pickedFiles.first.bytes != null) {
        _openPdfInApp(_pickedFiles.first);
      } else {
        setState(() => _errorMessage = 'Please select a PDF file to view.');
      }
      return;
    }
    if (_tool!.id == 'text-to-pdf' || _tool!.id == 'pdf-editor') {
      if (_selectedInputTab == 0 && _tool!.id == 'text-to-pdf') {
        canProcess = _pickedFiles.isNotEmpty;
      } else {
        canProcess = _quillController.document.toPlainText().trim().isNotEmpty;
      }
    } else if (_tool!.id == 'html-url-to-pdf') {
      // For HTML to PDF, we need a URL
      canProcess = _htmlUrl.trim().isNotEmpty;
    } else {
      canProcess = _pickedFiles.isNotEmpty;
    }

    if (!canProcess) {
      String errorMsg;
      if (_tool!.id == 'text-to-pdf') {
        errorMsg = _selectedInputTab == 0
            ? 'Please select a text or Excel file to convert.'
            : 'Please enter some text in the editor.';
      } else if (_tool!.id == 'html-url-to-pdf') {
        errorMsg = 'Please enter a valid URL.';
      } else {
        errorMsg = 'Please select at least one file.';
      }
      setState(() => _errorMessage = errorMsg);
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
    List<PlatformFile> files = [];

    // Special handling for HTML URL to PDF - no files needed
    if (_tool!.id == 'html-url-to-pdf') {
      if (_htmlUrl.isEmpty) {
        throw Exception('Please enter a valid URL');
      }

      onProgress(int sent, int total) {
        setState(() => _uploadProgress = sent / total);
      }

      final response = await PdfApiService.htmlUrlToPdf(_htmlUrl,
          onSendProgress: onProgress);

      if (response.data != null) {
        setState(() => _resultBytes = response.data);
      }
      return;
    }

    // Handle other tools that need files
    if (_tool!.id == 'text-to-pdf' || _tool!.id == 'pdf-editor') {
      if (_tool!.id == 'text-to-pdf' && _selectedInputTab == 0) {
        files = _pickedFiles.where((f) => f.bytes != null).toList();
      } else {
        final deltaJson = _quillController.document.toDelta().toJson();
        final converter = q2h.QuillDeltaToHtmlConverter(
          List.castFrom(deltaJson),
          q2h.ConverterOptions.forEmail(),
        );
        final htmlContent = converter.convert();
        final fullHtml =
            '<html><head><meta charset="utf-8"></head><body>$htmlContent</body></html>';
        final bytes = utf8.encode(fullHtml);
        files = [
          PlatformFile(name: 'rich_text.html', size: bytes.length, bytes: bytes)
        ];
      }
    } else {
      files = _pickedFiles.where((f) => f.bytes != null).toList();
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
        response =
            await PdfApiService.mergePdfs(files, onSendProgress: onProgress);
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
        response = await PdfApiService.pdfToImages(files.first,
            onSendProgress: onProgress);
        break;
      case 'extract-text':
        response = await PdfApiService.extractText(files.first);
        break;
      case 'text-to-pdf':
      case 'pdf-editor':
        response = await PdfApiService.textToPdf(files.first,
            onSendProgress: onProgress);
        break;
      case 'info':
        response = await PdfApiService.getPdfInfo(files.first);
        break;
      // New tools
      case 'word-to-pdf':
        response = await PdfApiService.wordToPdf(files.first,
            onSendProgress: onProgress);
        break;
      case 'pdf-to-word':
        response = await PdfApiService.pdfToWord(files.first,
            onSendProgress: onProgress);
        break;
      case 'pdf-to-excel':
        response = await PdfApiService.pdfToExcel(files.first,
            onSendProgress: onProgress);
        break;
      case 'excel-to-pdf':
        response = await PdfApiService.excelToPdf(files.first,
            onSendProgress: onProgress);
        break;
      case 'powerpoint-to-pdf':
        response = await PdfApiService.powerpointToPdf(files.first,
            onSendProgress: onProgress);
        break;
      case 'pdf-to-powerpoint':
        response = await PdfApiService.pdfToPowerpoint(files.first,
            onSendProgress: onProgress);
        break;
      case 'organize':
        response = await PdfApiService.organizePdf(files.first,
            pageOrder: _pageOrder, onSendProgress: onProgress);
        break;
      case 'add-page-numbers':
        response = await PdfApiService.addPageNumbers(files.first,
            position: _pageNumberPosition,
            startNumber: _pageNumberStart,
            onSendProgress: onProgress);
        break;
      case 'ocr':
        response = await PdfApiService.ocrPdf(files.first,
            language: _ocrLanguage, onSendProgress: onProgress);
        break;
      case 'crop':
        response = await PdfApiService.cropPdf(files.first,
            left: _cropLeft,
            right: _cropRight,
            top: _cropTop,
            bottom: _cropBottom,
            onSendProgress: onProgress);
        break;
      case 'redact':
        response = await PdfApiService.redactPdf(files.first,
            searchTerms: _redactTerms, onSendProgress: onProgress);
        break;
    }

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 201)) {
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

  void _openCanvasEditor(PlatformFile file) {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() => _errorMessage = 'Please select a valid PDF file.');
      return;
    }
    setState(() => _errorMessage = null);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfCanvasEditorScreen(
          bytes: Uint8List.fromList(bytes),
          fileName: file.name.isNotEmpty ? file.name : 'document.pdf',
        ),
      ),
    );
  }

  void _openPdfInApp(PlatformFile file) {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() => _errorMessage = 'Please select a valid PDF file.');
      return;
    }
    setState(() => _errorMessage = null);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InAppPdfViewerScreen(
          bytes: Uint8List.fromList(bytes),
          fileName: file.name.isNotEmpty ? file.name : 'document.pdf',
        ),
      ),
    );
  }

  Future<void> _importPdfTextToEditor() async {
    if (_pickedFiles.isEmpty || _pickedFiles.first.bytes == null) {
      setState(() => _errorMessage = 'Select a PDF file to import text from.');
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      final response = await PdfApiService.extractText(_pickedFiles.first);
      dynamic data = response.data;
      if (data is List<int>) {
        data = jsonDecode(utf8.decode(data));
      } else if (data is String) {
        data = jsonDecode(data);
      }
      final pages = (data as Map<String, dynamic>)['pages'] as List<dynamic>;
      final text = pages
          .map((p) => (p as Map<String, dynamic>)['text'] as String? ?? '')
          .join('\n\n');
      final docLength = _quillController.document.length;
      _quillController.replaceText(
        0,
        docLength > 0 ? docLength - 1 : 0,
        text.trim().isEmpty ? '(No extractable text in this PDF)' : text,
        null,
      );
      setState(() => _selectedInputTab = 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF text imported into editor')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
      html.AnchorElement(href: url)
        ..setAttribute('download', outName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else if (Platform.isAndroid || Platform.isIOS) {
      try {
        await Printing.sharePdf(
          bytes: Uint8List.fromList(_resultBytes!),
          filename: outName,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing file: $e')),
          );
        }
      }
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
    final isMobile = MediaQuery.of(context).size.width < 700;
    final hasOptions = _buildOptions(isDark).isNotEmpty;
    final unread = context.watch<NotificationsProvider>().unreadCount;
    final isThemeDark = context.watch<ThemeProvider>().isDark;
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite = favorites.isFavorite(_tool!.id);

    final hasInput = _pickedFiles.isNotEmpty ||
        (_tool!.id == 'text-to-pdf' && _textController.text.isNotEmpty) ||
        (_tool!.id == 'html-url-to-pdf' && _htmlUrl.isNotEmpty);

    Widget body;
    if (_isProcessing || _done || _errorMessage != null) {
      body = _buildProcessingState(isDark);
    } else if (_tool!.id == 'text-to-pdf' || _tool!.id == 'pdf-editor') {
      body = _buildTextToPdfScreen(isDark, isWide);
    } else if (_tool!.id == 'pdf-viewer') {
      body = _buildPdfViewerScreen(isDark, isWide);
    } else if (_tool!.id == 'html-url-to-pdf') {
      body = _buildHtmlToPdfScreen(isDark, isWide);
    } else if (hasInput) {
      body = _buildSelectedState(isDark, isWide);
    } else {
      body = _buildInitialState(isDark, isWide);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Icon(_tool!.icon, color: _tool!.color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tool!.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 17 : 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isFavorite
                ? 'Remove from favourites'
                : 'Add to favourites',
            onPressed: () => favorites.toggle(_tool!.id),
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFavorite ? AppTheme.secondaryColor : null,
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (unread > 0)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : unread.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: isThemeDark ? 'Light mode' : 'Dark mode',
            icon: Icon(isThemeDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          if (!isWide && hasOptions)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Tool options',
              onPressed: () => _showOptionsBottomSheet(isDark),
            ),
        ],
      ),
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const AdBanner(placement: 'ToolTop'),
          const SizedBox(height: 10),
          Expanded(child: body),
        ],
      ),
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
                  _textController.clear();
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_tool!.icon, size: 80, color: _tool!.color),
              const SizedBox(height: 24),
              Text(
                _tool!.title,
                style: GoogleFonts.poppins(
                  fontSize: isWide ? 48 : 30,
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
                  fontSize: isWide ? 20 : 15,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_tool!.id == 'text-to-pdf')
                Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 300,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.05)),
                        ),
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter your text here...',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('OR',
                          style: GoogleFonts.poppins(
                              color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              if (_tool!.acceptedExtensions.isNotEmpty)
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
                        const Icon(Icons.folder_open_rounded,
                            color: Colors.white, size: 26),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Select ${_tool!.acceptedExtensions.join('/').toUpperCase()}',
                            style: GoogleFonts.poppins(
                              fontSize: isWide ? 22 : 17,
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
              if (_tool!.acceptedExtensions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'or drop files here',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        ),
      ),
    );
  }

  Widget _buildHtmlToPdfScreen(bool isDark, bool isWide) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
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
              Text(
                'Enter Website URL',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _htmlUrl = v),
                style: GoogleFonts.poppins(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'https://example.com',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  filled: true,
                  fillColor:
                      isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _tool!.color, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: _htmlUrl.trim().isEmpty ? null : _process,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tool!.color,
                    disabledBackgroundColor: _tool!.color.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Convert to PDF',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        ),
      ),
    );
  }

  Widget _buildSelectedState(bool isDark, bool isWide) {
    final options = _buildOptions(isDark);
    final showInlineOptions = !isWide && options.isNotEmpty;

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
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: Colors.grey),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _pickedFiles.clear();
                    _textController.clear();
                  });
                },
                child: Text(
                  _tool!.title,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: Colors.grey),
              Text('Options',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 32),
          if (_tool!.id == 'text-to-pdf' && _textController.text.isNotEmpty)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.05)),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter your text here...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    border: InputBorder.none,
                  ),
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
          if (showInlineOptions) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: options,
                  ),
                ),
              ),
            ),
          ],
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
                mainAxisSize: MainAxisSize.min,
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
              border: Border(
                  top: BorderSide(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.05))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _process,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tool!.color,
                  disabledBackgroundColor: _tool!.color.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.white))
                    : Text(
                        _tool!.title,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(
          children: [Expanded(flex: 3, child: leftContent), rightSidebar]);
    } else {
      return Column(
        children: [
          Expanded(child: leftContent),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AdBanner(placement: 'ToolBeforeAction'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _process,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tool!.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _tool!.title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      case 'pdf-editor':
        return 'edited.pdf';
      case 'pdf-viewer':
        return 'document.pdf';
      case 'info':
        return 'pdf_info.json';
      case 'extract-text':
        return 'extracted_text.json';
      // New tools
      case 'word-to-pdf':
        return 'word_to_pdf.pdf';
      case 'pdf-to-word':
        return 'pdf_to_word.docx';
      case 'pdf-to-excel':
        return 'pdf_to_excel.xlsx';
      case 'excel-to-pdf':
        return 'excel_to_pdf.pdf';
      case 'powerpoint-to-pdf':
        return 'powerpoint_to_pdf.pdf';
      case 'pdf-to-powerpoint':
        return 'pdf_to_powerpoint.pptx';
      case 'html-url-to-pdf':
        return 'webpage.pdf';
      case 'organize':
        return 'organized.pdf';
      case 'add-page-numbers':
        return 'numbered.pdf';
      case 'ocr':
        return 'ocr_result.pdf';
      case 'crop':
        return 'cropped.pdf';
      case 'redact':
        return 'redacted.pdf';
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
          Text('Opacity: ${(_watermarkOpacity * 100).round()}%',
              style: labelStyle),
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
                onSelected: (_) => setState(() => _imageOrientation = opt.$1),
              );
            }).toList(),
          ),
        ];

      case 'organize':
        return [
          Text('Page Order', style: labelStyle),
          const SizedBox(height: 8),
          _StyledTextField(
            hint: 'e.g. 3, 1, 2, 5, 4',
            onChanged: (v) => _pageOrder = v,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter page numbers separated by commas in the order you want.\n'
            'Leave empty to keep the original page order.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ];

      case 'add-page-numbers':
        return [
          Text('Position', style: labelStyle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ('bottom-center', 'Bottom Center'),
              ('bottom-left', 'Bottom Left'),
              ('bottom-right', 'Bottom Right'),
              ('top-center', 'Top Center'),
            ].map((opt) {
              final selected = _pageNumberPosition == opt.$1;
              return ChoiceChip(
                label: Text(opt.$2),
                selected: selected,
                selectedColor: _tool!.color,
                labelStyle: GoogleFonts.poppins(
                  color: selected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                onSelected: (_) =>
                    setState(() => _pageNumberPosition = opt.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Start Number: $_pageNumberStart', style: labelStyle),
          Slider(
            value: _pageNumberStart.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: _tool!.color,
            onChanged: (v) =>
                setState(() => _pageNumberStart = v.round()),
          ),
        ];

      case 'ocr':
        return [
          Text('OCR Language', style: labelStyle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ('eng', 'English'),
              ('fra', 'French'),
              ('deu', 'German'),
              ('spa', 'Spanish'),
              ('ara', 'Arabic'),
              ('urd', 'Urdu'),
            ].map((opt) {
              final selected = _ocrLanguage == opt.$1;
              return ChoiceChip(
                label: Text(opt.$2),
                selected: selected,
                selectedColor: _tool!.color,
                labelStyle: GoogleFonts.poppins(
                  color: selected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                onSelected: (_) =>
                    setState(() => _ocrLanguage = opt.$1),
              );
            }).toList(),
          ),
        ];

      case 'crop':
        return [
          Text('Crop Margins (points)', style: labelStyle),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StyledTextField(
                  hint: 'Left',
                  initialValue: _cropLeft.toString(),
                  onChanged: (v) =>
                      _cropLeft = double.tryParse(v) ?? 0,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StyledTextField(
                  hint: 'Right',
                  initialValue: _cropRight.toString(),
                  onChanged: (v) =>
                      _cropRight = double.tryParse(v) ?? 0,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StyledTextField(
                  hint: 'Top',
                  initialValue: _cropTop.toString(),
                  onChanged: (v) =>
                      _cropTop = double.tryParse(v) ?? 0,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StyledTextField(
                  hint: 'Bottom',
                  initialValue: _cropBottom.toString(),
                  onChanged: (v) =>
                      _cropBottom = double.tryParse(v) ?? 0,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ];

      case 'redact':
        return [
          Text('Search Terms', style: labelStyle),
          const SizedBox(height: 8),
          _StyledTextField(
            hint: 'e.g. SSN, email, phone',
            onChanged: (v) => _redactTerms = v,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          Text(
            'Comma-separated terms to redact from the PDF.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ];

      case 'html-url-to-pdf':
        return [
          Text('Website URL', style: labelStyle),
          const SizedBox(height: 8),
          _StyledTextField(
            hint: 'https://example.com',
            onChanged: (v) => _htmlUrl = v,
            isDark: isDark,
          ),
        ];

      default:
        return [];
    }
  }

  Widget _buildPdfViewerScreen(bool isDark, bool isWide) {
    final hasFile = _pickedFiles.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              Icon(_tool!.icon, size: 72, color: _tool!.color),
              const SizedBox(height: 20),
              Text(
                _tool!.title,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _tool!.subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!hasFile)
                InkWell(
                  onTap: _pickFiles,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: _tool!.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _tool!.color.withOpacity(0.35)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.upload_file_rounded,
                            color: _tool!.color, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          'Select PDF file',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: _tool!.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, color: _tool!.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pickedFiles.first.name,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => setState(() => _pickedFiles.clear()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPdfInApp(_pickedFiles.first),
                    icon: const Icon(Icons.visibility_rounded, color: Colors.white),
                    label: Text(
                      'View PDF',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tool!.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Opens in the app after you select. Use zoom or edit in the toolbar.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _pickFiles,
                  child: const Text('Choose another file'),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfEditorLanding(bool isDark) {
    final hasFile = _pickedFiles.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _tool!.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _tool!.color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Icon(Icons.design_services_rounded, size: 48, color: _tool!.color),
              const SizedBox(height: 12),
              Text(
                'Visual PDF canvas',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Open your PDF on a page canvas. Drag text and images on top, then export — similar to Canva.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (!hasFile)
          InkWell(
            onTap: _pickFiles,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.upload_file_rounded, color: _tool!.color, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Upload PDF to edit',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: _tool!.color,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.picture_as_pdf_rounded, color: _tool!.color),
            title: Text(
              _pickedFiles.first.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(() => _pickedFiles.clear()),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _openCanvasEditor(_pickedFiles.first),
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              label: Text(
                'Open canvas editor',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _tool!.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _pickFiles,
            child: const Text('Choose another file'),
          ),
        ],
      ],
    );
  }

  Widget _buildTextToPdfScreen(bool isDark, bool isWide) {
    final isEditor = _tool!.id == 'pdf-editor';

    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumbs
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
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: Colors.grey),
                  Text(
                    _tool!.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title & Subtitle
              Text(
                _tool!.title,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tool!.subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),

              if (isEditor) ...[
                _buildPdfEditorLanding(isDark),
              ] else ...[
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabButton(
                          0, 'Upload File', Icons.upload_file_rounded, isDark),
                      _buildTabButton(1, 'Rich Text Editor',
                          Icons.edit_note_rounded, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_selectedInputTab == 0) ...[
                  if (_pickedFiles.isEmpty)
                    _buildUploadArea(isDark, isWide)
                  else
                    _buildUploadedFileCard(isDark),
                ] else ...[
                  _buildRichTextEditor(isDark),
                ],
              ],

              if (!isEditor) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _process,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tool!.color,
                      disabledBackgroundColor: _tool!.color.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Convert to PDF',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ).animate().fadeIn(duration: 300.ms),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon, bool isDark) {
    final isSelected = _selectedInputTab == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedInputTab = index;
        _errorMessage = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _tool!.color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _tool!.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea(bool isDark, bool isWide) {
    return InkWell(
      onTap: _pickFiles,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded, color: _tool!.color, size: 64),
            const SizedBox(height: 16),
            Text(
              'Select a file to convert',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supports Excel (.xlsx, .xls) and Plain Text (.txt)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedFileCard(bool isDark) {
    final file = _pickedFiles.first;
    final extension = file.name.split('.').last.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _tool!.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              file.name.endsWith('.txt')
                  ? Icons.text_snippet_rounded
                  : Icons.table_chart_rounded,
              color: _tool!.color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$extension File • ${(file.size / 1024).toStringAsFixed(1)} KB',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _pickedFiles.clear()),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildRichTextEditor(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quill Toolbar
          quill.QuillSimpleToolbar(
            controller: _quillController,
            config: quill.QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: true,
              showColorButton: true,
              showBackgroundColorButton: true,
              showListNumbers: true,
              showListBullets: true,
              showListCheck: false,
              showCodeBlock: true,
              showQuote: true,
              showIndent: true,
              showLink: true,
              showUndo: true,
              showRedo: true,
              showSubscript: false,
              showSuperscript: false,
              multiRowsDisplay: true,
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Quill Editor
          SizedBox(
            height: 350,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: quill.QuillEditor.basic(
                controller: _quillController,
                config: const quill.QuillEditorConfig(
                  placeholder: 'Write your outstanding PDF content here...',
                  padding: EdgeInsets.zero,
                  autoFocus: false,
                  expands: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsBottomSheet(bool isDark) {
    final options = _buildOptions(isDark);
    if (options.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(_tool!.icon, color: _tool!.color, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        '${_tool!.title} options',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...options,
                ],
              ),
            ),
          ),
        );
      },
    );
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
                child: Icon(Icons.drag_indicator_rounded,
                    size: 20, color: Colors.grey),
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
            icon: const Icon(Icons.close_rounded,
                size: 18, color: Colors.redAccent),
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
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
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
