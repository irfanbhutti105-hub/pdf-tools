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
}
