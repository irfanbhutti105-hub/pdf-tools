import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum ScanFilter {
  original,
  grayscale,
  blackWhite,
  enhanced,
  magic,
}

enum ScanPageSize { a4, letter, legal, auto }

class DocumentScannerService {
  static Future<List<Uint8List>> scanDocuments({
    int maxPages = 20,
    bool allowGallery = true,
  }) async {
    final paths = await CunningDocumentScanner.getPictures(
      noOfPages: maxPages,
      isGalleryImportAllowed: allowGallery,
      iosScannerOptions: const IosScannerOptions(
        imageFormat: IosImageFormat.jpg,
        jpgCompressionQuality: 0.85,
      ),
    );
    if (paths == null || paths.isEmpty) return [];

    final pages = <Uint8List>[];
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        pages.add(await file.readAsBytes());
      }
    }
    return pages;
  }

  static Uint8List applyFilter(Uint8List bytes, ScanFilter filter) {
    if (filter == ScanFilter.original) return bytes;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final img.Image result;
    switch (filter) {
      case ScanFilter.grayscale:
        result = img.grayscale(decoded);
      case ScanFilter.blackWhite:
        final gray = img.grayscale(decoded);
        result = img.luminanceThreshold(
          img.adjustColor(gray, contrast: 1.35, brightness: 0.04),
          threshold: 0.52,
        );
      case ScanFilter.enhanced:
        result = img.adjustColor(
          decoded,
          contrast: 1.22,
          brightness: 0.03,
          saturation: 0.85,
        );
      case ScanFilter.magic:
        final gray = img.grayscale(decoded);
        result = img.normalize(img.contrast(gray, contrast: 145), min: 5, max: 250);
      case ScanFilter.original:
        result = decoded;
    }

    return Uint8List.fromList(img.encodeJpg(result, quality: 90));
  }

  static Uint8List rotateImage(Uint8List bytes, int quarterTurns) {
    final normalized = quarterTurns % 4;
    if (normalized == 0) return bytes;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final rotated = img.copyRotate(decoded, angle: normalized * 90.0);
    return Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
  }

  static Future<Uint8List> buildPdf({
    required List<Uint8List> pages,
    ScanPageSize pageSize = ScanPageSize.a4,
    bool landscape = false,
    double marginPt = 20,
  }) async {
    final pdf = pw.Document();
    final needsAutoSize = pageSize == ScanPageSize.auto;

    for (final pageBytes in pages) {
      final image = pw.MemoryImage(pageBytes);

      PdfPageFormat format;
      if (needsAutoSize) {
        // Only decode when we need the dimensions for auto-sizing.
        final decoded = img.decodeImage(pageBytes);
        if (decoded != null) {
          format = PdfPageFormat(
            decoded.width.toDouble(),
            decoded.height.toDouble(),
            marginAll: marginPt,
          );
        } else {
          format = PdfPageFormat.a4.copyWith(
            marginLeft: marginPt,
            marginRight: marginPt,
            marginTop: marginPt,
            marginBottom: marginPt,
          );
        }
      } else {
        format = switch (pageSize) {
          ScanPageSize.letter => PdfPageFormat.letter,
          ScanPageSize.legal => PdfPageFormat.legal,
          _ => PdfPageFormat.a4,
        };
        if (landscape) format = format.landscape;
        format = format.copyWith(
          marginLeft: marginPt,
          marginRight: marginPt,
          marginTop: marginPt,
          marginBottom: marginPt,
        );
      }

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (_) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    return Uint8List.fromList(await pdf.save());
  }

  static String filterLabel(ScanFilter filter) => switch (filter) {
        ScanFilter.original => 'Original',
        ScanFilter.grayscale => 'Grayscale',
        ScanFilter.blackWhite => 'B & W',
        ScanFilter.enhanced => 'Enhanced',
        ScanFilter.magic => 'Magic',
      };

  static String pageSizeLabel(ScanPageSize size) => switch (size) {
        ScanPageSize.a4 => 'A4',
        ScanPageSize.letter => 'Letter',
        ScanPageSize.legal => 'Legal',
        ScanPageSize.auto => 'Auto fit',
      };
}
