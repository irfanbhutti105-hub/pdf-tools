import 'package:flutter/material.dart';

class PdfTool {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color colorLight;
  final String endpoint;
  final bool multiFile;
  final List<String> acceptedExtensions;

  const PdfTool({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.colorLight,
    required this.endpoint,
    this.multiFile = false,
    required this.acceptedExtensions,
  });
}
