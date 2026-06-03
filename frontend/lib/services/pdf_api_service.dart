import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../core/api_config.dart';

class PdfApiService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
    headers: {'Accept': 'application/json'},
  ));

  /// Merge multiple PDF files
  static Future<Response> mergePdfs(
    List<PlatformFile> files, {
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData();
    for (final file in files) {
      formData.files.add(MapEntry(
        'files',
        MultipartFile.fromBytes(file.bytes!, filename: file.name),
      ));
    }
    return _dio.post(
      ApiEndpoints.merge,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Split a PDF file
  static Future<Response> splitPdf(
    PlatformFile file, {
    String? ranges,
    bool everyPage = false,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      if (ranges != null) 'ranges': ranges,
      'every_page': everyPage.toString(),
    });
    return _dio.post(
      ApiEndpoints.split,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Compress a PDF file
  static Future<Response> compressPdf(
    PlatformFile file, {
    String level = 'medium',
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'level': level,
    });
    return _dio.post(
      ApiEndpoints.compress,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Rotate PDF pages
  static Future<Response> rotatePdf(
    PlatformFile file, {
    int angle = 90,
    String? pages,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'angle': angle.toString(),
      if (pages != null) 'pages': pages,
    });
    return _dio.post(
      ApiEndpoints.rotate,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Add watermark to PDF
  static Future<Response> watermarkPdf(
    PlatformFile file, {
    String text = 'CONFIDENTIAL',
    double opacity = 0.3,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'watermark_text': text,
      'opacity': opacity.toString(),
    });
    return _dio.post(
      ApiEndpoints.watermark,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Protect PDF with password
  static Future<Response> protectPdf(
    PlatformFile file, {
    required String password,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'password': password,
    });
    return _dio.post(
      ApiEndpoints.protect,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Unlock / remove password from PDF
  static Future<Response> unlockPdf(
    PlatformFile file, {
    required String password,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'password': password,
    });
    return _dio.post(
      ApiEndpoints.unlock,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Convert images to PDF
  static Future<Response> imagesToPdf(
    List<PlatformFile> files, {
    String orientation = 'portrait',
    int margin = 20,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData();
    for (final file in files) {
      formData.files.add(MapEntry(
        'files',
        MultipartFile.fromBytes(file.bytes!, filename: file.name),
      ));
    }
    formData.fields.addAll([
      MapEntry('orientation', orientation),
      MapEntry('margin', margin.toString()),
    ]);
    return _dio.post(
      ApiEndpoints.imagesToPdf,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Convert PDF pages to images (ZIP)
  static Future<Response> pdfToImages(
    PlatformFile file, {
    int dpi = 150,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'dpi': dpi.toString(),
    });
    return _dio.post(
      ApiEndpoints.pdfToImages,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Get PDF metadata info
  static Future<Response> getPdfInfo(PlatformFile file) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    return _dio.post(ApiEndpoints.info, data: formData);
  }

  /// Extract text from PDF
  static Future<Response> extractText(PlatformFile file) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    return _dio.post(ApiEndpoints.extractText, data: formData);
  }

  /// Convert Text to PDF
  static Future<Response> textToPdf(
    PlatformFile file, {
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    return _dio.post(
      ApiEndpoints.textToPdf,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Convert Word to PDF
  static Future<Response> wordToPdf(
    PlatformFile file, {
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    return _dio.post(
      ApiEndpoints.wordToPdf,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Convert PDF to Word
  static Future<Response> pdfToWord(
    PlatformFile file, {
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    return _dio.post(
      ApiEndpoints.pdfToWord,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Convert PDF to Excel
  static Future<Response> pdfToExcel(
    PlatformFile file, {
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    return _dio.post(
      ApiEndpoints.pdfToExcel,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Convert Excel to PDF
  static Future<Response> excelToPdf(
    PlatformFile file, {
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    return _dio.post(
      ApiEndpoints.excelToPdf,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Convert PowerPoint to PDF
  static Future<Response> powerpointToPdf(
    PlatformFile file, {
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    return _dio.post(
      ApiEndpoints.powerpointToPdf,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Convert PDF to PowerPoint
  static Future<Response> pdfToPowerpoint(
    PlatformFile file, {
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
    });
    return _dio.post(
      ApiEndpoints.pdfToPowerpoint,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Convert HTML URL to PDF
  static Future<Response> htmlUrlToPdf(
    String url, {
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'url': url,
    });
    return _dio.post(
      ApiEndpoints.htmlUrlToPdf,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Organize/Reorder PDF pages
  static Future<Response> organizePdf(
    PlatformFile file, {
    required String pageOrder,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'page_order': pageOrder,
    });
    return _dio.post(
      ApiEndpoints.organize,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Add page numbers to PDF
  static Future<Response> addPageNumbers(
    PlatformFile file, {
    String position = 'bottom-center',
    int startNumber = 1,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'position': position,
      'start_number': startNumber.toString(),
    });
    return _dio.post(
      ApiEndpoints.addPageNumbers,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Perform OCR on PDF
  static Future<Response> ocrPdf(
    PlatformFile file, {
    String language = 'eng',
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'language': language,
    });
    return _dio.post(
      ApiEndpoints.ocr,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Crop PDF margins
  static Future<Response> cropPdf(
    PlatformFile file, {
    double left = 0,
    double bottom = 0,
    double right = 0,
    double top = 0,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'left': left.toString(),
      'bottom': bottom.toString(),
      'right': right.toString(),
      'top': top.toString(),
    });
    return _dio.post(
      ApiEndpoints.crop,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }

  /// Redact sensitive information from PDF
  static Future<Response> redactPdf(
    PlatformFile file, {
    required String searchTerms,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      'search_terms': searchTerms,
    });
    return _dio.post(
      ApiEndpoints.redact,
      data: formData,
      options: Options(responseType: ResponseType.bytes),
      onSendProgress: onSendProgress,
    );
  }
}
