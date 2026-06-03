import 'package:dio/dio.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';

class HistoryService {
  // ─── Get File History ─────────────────────────

  static Future<List<FileHistoryItem>> getHistory({int limit = 50}) async {
    try {
      final response = await AuthService.authorizedRequest<Map<String, dynamic>>(
        method: 'GET',
        path: '/api/history/',
        queryParameters: {'limit': limit},
      );

      final items = (response.data!['items'] as List)
          .map((item) => FileHistoryItem.fromJson(item))
          .toList();

      return items;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Download File from History ───────────────

  static Future<void> downloadFromHistory(String jobId, String filename) async {
    try {
      final response = await AuthService.authorizedRequest<List<int>>(
        method: 'GET',
        path: '/api/history/$jobId/download',
        responseType: ResponseType.bytes,
      );

      // Download file
      if (kIsWeb) {
        final blob = html.Blob([response.data!]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // For mobile/desktop - implement file saving
        throw UnimplementedError(
            'File download not implemented for this platform');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Delete File from History ─────────────────

  static Future<void> deleteFromHistory(String jobId) async {
    try {
      await AuthService.authorizedRequest<void>(
        method: 'DELETE',
        path: '/api/history/$jobId',
      );
    } catch (e) {
      rethrow;
    }
  }

  // ─── Error Handling ───────────────────────────

  static String _handleError(DioException e) {
    if (e.response?.data != null) {
      try {
        final data = e.response!.data;
        if (data is Map && data['detail'] != null) {
          return data['detail'].toString();
        }
      } catch (_) {}
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please try again.';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          return 'Authentication required';
        }
        if (e.response?.statusCode == 403) {
          return 'Access denied';
        }
        if (e.response?.statusCode == 404) {
          return 'File not found';
        }
        if (e.response?.statusCode == 410) {
          return 'File has expired';
        }
        return 'Server error. Please try again later.';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Network error. Please check your connection.';
    }
  }
}
