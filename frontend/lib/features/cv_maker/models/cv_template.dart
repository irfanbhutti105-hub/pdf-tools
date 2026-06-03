import 'package:flutter/material.dart';

enum CvTemplateCategory { all, modern, classic, creative, minimal }

enum CvTemplateLayout {
  sidebarLeft,
  sidebarRight,
  headerBand,
  singleColumn,
  splitColumns,
}

class CvTemplate {
  final String id;
  final String name;
  final String description;
  final CvTemplateCategory category;
  final CvTemplateLayout layout;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;
  final bool isPremium;
  final List<String> tags;

  const CvTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.layout,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
    this.isPremium = false,
    this.tags = const [],
  });
}
