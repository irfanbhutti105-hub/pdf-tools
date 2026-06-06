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
    this.fontFamily = 'Poppins',
    this.fontSizePt = 16,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.textAlign = TextAlign.left,
    this.color = Colors.black,
    this.opacity = 1.0,
    this.imageBytes,
  });

  final String id;
  final EditorLayerType type;
  double relX;
  double relY;
  double relWidth;
  double relHeight;
  String text;
  String fontFamily;
  double fontSizePt;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  TextAlign textAlign;
  Color color;
  double opacity;
  Uint8List? imageBytes;

  EditorLayer copyWith({
    String? text,
    String? fontFamily,
    double? fontSizePt,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    TextAlign? textAlign,
    Color? color,
    double? opacity,
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
      fontFamily: fontFamily ?? this.fontFamily,
      fontSizePt: fontSizePt ?? this.fontSizePt,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      textAlign: textAlign ?? this.textAlign,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
}
