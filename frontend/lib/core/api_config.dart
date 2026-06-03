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

  // New endpoints
  static const String wordToPdf = '$baseUrl/api/pdf/word-to-pdf';
  static const String pdfToWord = '$baseUrl/api/pdf/pdf-to-word';
  static const String pdfToExcel = '$baseUrl/api/pdf/pdf-to-excel';
  static const String excelToPdf = '$baseUrl/api/pdf/excel-to-pdf';
  static const String powerpointToPdf = '$baseUrl/api/pdf/powerpoint-to-pdf';
  static const String pdfToPowerpoint = '$baseUrl/api/pdf/pdf-to-powerpoint';
  static const String htmlUrlToPdf = '$baseUrl/api/pdf/html-url-to-pdf';
  static const String organize = '$baseUrl/api/pdf/organize';
  static const String addPageNumbers = '$baseUrl/api/pdf/add-page-numbers';
  static const String ocr = '$baseUrl/api/pdf/ocr';
  static const String crop = '$baseUrl/api/pdf/crop';
  static const String redact = '$baseUrl/api/pdf/redact';
}
