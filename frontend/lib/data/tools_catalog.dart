import 'package:flutter/material.dart';

import '../models/pdf_tool.dart';
import 'tools_data.dart';

enum ToolCategory {
  essential,
  organize,
  convert,
  security,
  advanced,
}

class ToolCategoryMeta {
  const ToolCategoryMeta({
    required this.category,
    required this.label,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final ToolCategory category;
  final String label;
  final String description;
  final IconData icon;
  final Color accent;
}

const List<ToolCategoryMeta> toolCategoryOrder = [
  ToolCategoryMeta(
    category: ToolCategory.essential,
    label: 'Essentials',
    description: 'View, edit, merge, and optimize',
    icon: Icons.star_rounded,
    accent: Color(0xFF6C63FF),
  ),
  ToolCategoryMeta(
    category: ToolCategory.organize,
    label: 'Organize',
    description: 'Pages, layout, and structure',
    icon: Icons.dashboard_customize_rounded,
    accent: Color(0xFF8B5CF6),
  ),
  ToolCategoryMeta(
    category: ToolCategory.convert,
    label: 'Convert',
    description: 'Office, images, and web formats',
    icon: Icons.swap_horiz_rounded,
    accent: Color(0xFF3B82F6),
  ),
  ToolCategoryMeta(
    category: ToolCategory.security,
    label: 'Security',
    description: 'Protect, unlock, and redact',
    icon: Icons.shield_rounded,
    accent: Color(0xFF27AE60),
  ),
  ToolCategoryMeta(
    category: ToolCategory.advanced,
    label: 'Advanced',
    description: 'OCR, metadata, and automation',
    icon: Icons.auto_awesome_rounded,
    accent: Color(0xFFE67E22),
  ),
];

const Map<String, ToolCategory> _toolCategoryById = {
  'document-scanner': ToolCategory.essential,
  'pdf-viewer': ToolCategory.essential,
  'pdf-editor': ToolCategory.essential,
  'merge': ToolCategory.essential,
  'split': ToolCategory.essential,
  'compress': ToolCategory.essential,
  'rotate': ToolCategory.organize,
  'organize': ToolCategory.organize,
  'add-page-numbers': ToolCategory.organize,
  'crop': ToolCategory.organize,
  'watermark': ToolCategory.organize,
  'images-to-pdf': ToolCategory.convert,
  'pdf-to-images': ToolCategory.convert,
  'text-to-pdf': ToolCategory.convert,
  'word-to-pdf': ToolCategory.convert,
  'pdf-to-word': ToolCategory.convert,
  'pdf-to-powerpoint': ToolCategory.convert,
  'powerpoint-to-pdf': ToolCategory.convert,
  'pdf-to-excel': ToolCategory.convert,
  'excel-to-pdf': ToolCategory.convert,
  'html-url-to-pdf': ToolCategory.convert,
  'protect': ToolCategory.security,
  'unlock': ToolCategory.security,
  'redact': ToolCategory.security,
  'ocr': ToolCategory.advanced,
  'extract-text': ToolCategory.advanced,
  'info': ToolCategory.advanced,
};

ToolCategory categoryForTool(PdfTool tool) =>
    _toolCategoryById[tool.id] ?? ToolCategory.advanced;

const List<String> featuredToolIds = [
  'document-scanner',
  'merge',
  'compress',
  'pdf-viewer',
  'pdf-editor',
  'word-to-pdf',
  'protect',
];

List<PdfTool> get featuredTools => featuredToolIds
    .map((id) => allTools.where((t) => t.id == id).firstOrNull)
    .whereType<PdfTool>()
    .toList();

List<PdfTool> filterTools({
  required String query,
  ToolCategory? category,
}) {
  final q = query.trim().toLowerCase();
  return allTools.where((tool) {
    final matchesCategory =
        category == null || categoryForTool(tool) == category;
    if (!matchesCategory) return false;
    if (q.isEmpty) return true;
    return tool.title.toLowerCase().contains(q) ||
        tool.subtitle.toLowerCase().contains(q) ||
        tool.id.toLowerCase().contains(q);
  }).toList();
}

Map<ToolCategory, List<PdfTool>> groupToolsByCategory(List<PdfTool> tools) {
  final map = <ToolCategory, List<PdfTool>>{};
  for (final tool in tools) {
    final cat = categoryForTool(tool);
    map.putIfAbsent(cat, () => []).add(tool);
  }
  return map;
}
