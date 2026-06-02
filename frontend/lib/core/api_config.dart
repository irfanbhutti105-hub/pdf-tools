const String baseUrl = 'http://localhost:8000';

class ApiEndpoints {
  static const String merge = '$baseUrl/api/pdf/merge';
  static const String split = '$baseUrl/api/pdf/split';
  static const String compress = '$baseUrl/api/pdf/compress';
  static const String rotate = '$baseUrl/api/pdf/rotate';
  static const String watermark = '$baseUrl/api/pdf/watermark';
  static const String protect = '$baseUrl/api/pdf/protect';
  static const String unlock = '$baseUrl/api/pdf/unlock';
  static const String imagesToPdf = '$baseUrl/api/pdf/images-to-pdf';
  static const String pdfToImages = '$baseUrl/api/pdf/pdf-to-images';
  static const String info = '$baseUrl/api/pdf/info';
  static const String extractText = '$baseUrl/api/pdf/extract-text';
  static const String textToPdf = '$baseUrl/api/pdf/text-to-pdf';
}
