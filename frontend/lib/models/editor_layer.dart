import 'dart:typed_data';

import 'package:flutter/material.dart';

enum EditorLayerType { text, image }

/// Overlay on a PDF page (positions are 0–1 relative to page size).
class EditorLayer {
  EditorLayer({
    required this.id,
    required this.type,
    this.relX = 0.25,
    this.relY = 0.35,
    this.relWidth = 0.35,
    this.relHeight = 0.2,
    this.text = 'Double-tap to edit',
    this.fontSizePt = 16,
    this.color = Colors.black,
    this.imageBytes,
  });

  final String id;
  final EditorLayerType type;
  double relX;
  double relY;
  double relWidth;
  double relHeight;
  String text;
  double fontSizePt;
  Color color;
  Uint8List? imageBytes;

  EditorLayer copyWith({
    String? text,
    double? fontSizePt,
    Color? color,
    Uint8List? imageBytes,
  }) {
    return EditorLayer(
      id: id,
      type: type,
      relX: relX,
      relY: relY,
      relWidth: relWidth,
      relHeight: relHeight,
      text: text ?? this.text,
      fontSizePt: fontSizePt ?? this.fontSizePt,
      color: color ?? this.color,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
}
