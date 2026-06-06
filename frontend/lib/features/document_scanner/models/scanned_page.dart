
import 'package:flutter/foundation.dart';

import '../services/document_scanner_service.dart';

class ScannedPage {
  ScannedPage({
    required this.id,
    required this.originalBytes,
    ScanFilter filter = ScanFilter.original,
    int rotation = 0,
  })  : _filter = filter,
        _rotation = rotation;

  final String id;
  final Uint8List originalBytes;

  ScanFilter _filter;
  ScanFilter get filter => _filter;
  set filter(ScanFilter value) {
    if (_filter == value) return;
    _filter = value;
    _invalidateCache();
  }

  int _rotation;
  int get rotation => _rotation;
  set rotation(int value) {
    if (_rotation == value) return;
    _rotation = value;
    _invalidateCache();
  }

  // Cached processed bytes — recomputed only when filter/rotation change.
  Uint8List? _cachedDisplayBytes;
  bool _isComputing = false;

  /// Returns the cached display bytes, or the original if not yet computed.
  Uint8List get displayBytes => _cachedDisplayBytes ?? originalBytes;

  /// Whether a background computation is currently running.
  bool get isProcessing => _isComputing;

  void _invalidateCache() {
    _cachedDisplayBytes = null;
  }

  /// Compute the filtered+rotated image in a background isolate.
  /// Returns the processed bytes. The caller should call setState after await.
  Future<Uint8List> computeDisplayBytes() async {
    // Return cache if still valid.
    if (_cachedDisplayBytes != null) return _cachedDisplayBytes!;

    // Skip if no processing needed.
    if (_filter == ScanFilter.original && _rotation == 0) {
      _cachedDisplayBytes = originalBytes;
      return originalBytes;
    }

    _isComputing = true;

    try {
      final result = await compute(
        _processImageIsolate,
        _ProcessRequest(
          bytes: originalBytes,
          filter: _filter,
          rotation: _rotation,
        ),
      );
      _cachedDisplayBytes = result;
      return result;
    } finally {
      _isComputing = false;
    }
  }
}

/// Data class sent to the isolate — must be a top-level function.
class _ProcessRequest {
  final Uint8List bytes;
  final ScanFilter filter;
  final int rotation;
  const _ProcessRequest({
    required this.bytes,
    required this.filter,
    required this.rotation,
  });
}

/// Top-level function executed in a separate isolate.
Uint8List _processImageIsolate(_ProcessRequest req) {
  var bytes = DocumentScannerService.applyFilter(req.bytes, req.filter);
  if (req.rotation != 0) {
    bytes = DocumentScannerService.rotateImage(bytes, req.rotation);
  }
  return bytes;
}
