import 'package:flutter/material.dart';

import '../models/cv_template.dart';

const List<CvTemplate> cvTemplates = [
  CvTemplate(
    id: 'modern-edge',
    name: 'Modern Edge',
    description: 'Bold sidebar with clean typography',
    category: CvTemplateCategory.modern,
    layout: CvTemplateLayout.sidebarLeft,
    primaryColor: Color(0xFF6C63FF),
    accentColor: Color(0xFFEEEDFF),
    backgroundColor: Colors.white,
    textColor: Color(0xFF1A1A2E),
    tags: ['Popular', 'ATS-friendly'],
  ),
  CvTemplate(
    id: 'classic-pro',
    name: 'Classic Professional',
    description: 'Timeless header band for corporate roles',
    category: CvTemplateCategory.classic,
    layout: CvTemplateLayout.headerBand,
    primaryColor: Color(0xFF1E3A5F),
    accentColor: Color(0xFFE8EEF4),
    backgroundColor: Colors.white,
    textColor: Color(0xFF1A1A2E),
    tags: ['Corporate'],
  ),
  CvTemplate(
    id: 'clean-minimal',
    name: 'Clean Minimal',
    description: 'Spacious layout with subtle accents',
    category: CvTemplateCategory.minimal,
    layout: CvTemplateLayout.singleColumn,
    primaryColor: Color(0xFF374151),
    accentColor: Color(0xFFF3F4F6),
    backgroundColor: Colors.white,
    textColor: Color(0xFF111827),
    tags: ['Minimal'],
  ),
  CvTemplate(
    id: 'compact-one',
    name: 'Compact One',
    description: 'Fit more on one page — great for juniors',
    category: CvTemplateCategory.modern,
    layout: CvTemplateLayout.singleColumn,
    primaryColor: Color(0xFF0EA5E9),
    accentColor: Color(0xFFE0F2FE),
    backgroundColor: Colors.white,
    textColor: Color(0xFF0F172A),
    tags: ['One page'],
  ),
  CvTemplate(
    id: 'executive-gold',
    name: 'Executive Gold',
    description: 'Premium dark header with gold highlights',
    category: CvTemplateCategory.classic,
    layout: CvTemplateLayout.headerBand,
    primaryColor: Color(0xFF1A1A2E),
    accentColor: Color(0xFFD4AF37),
    backgroundColor: Colors.white,
    textColor: Color(0xFF1A1A2E),
    isPremium: true,
    tags: ['Premium', 'Executive'],
  ),
  CvTemplate(
    id: 'creative-gradient',
    name: 'Creative Gradient',
    description: 'Vibrant gradient sidebar for creatives',
    category: CvTemplateCategory.creative,
    layout: CvTemplateLayout.sidebarLeft,
    primaryColor: Color(0xFFEC4899),
    accentColor: Color(0xFF8B5CF6),
    backgroundColor: Colors.white,
    textColor: Color(0xFF1F2937),
    isPremium: true,
    tags: ['Premium', 'Creative'],
  ),
  CvTemplate(
    id: 'tech-stack',
    name: 'Tech Stack',
    description: 'Developer-focused with skills emphasis',
    category: CvTemplateCategory.modern,
    layout: CvTemplateLayout.sidebarRight,
    primaryColor: Color(0xFF10B981),
    accentColor: Color(0xFF064E3B),
    backgroundColor: Color(0xFFFAFAFA),
    textColor: Color(0xFF111827),
    isPremium: true,
    tags: ['Premium', 'Tech'],
  ),
  CvTemplate(
    id: 'elegant-serif',
    name: 'Elegant Serif',
    description: 'Refined typography for senior roles',
    category: CvTemplateCategory.classic,
    layout: CvTemplateLayout.splitColumns,
    primaryColor: Color(0xFF7C2D12),
    accentColor: Color(0xFFFEF3C7),
    backgroundColor: Color(0xFFFFFBF5),
    textColor: Color(0xFF292524),
    isPremium: true,
    tags: ['Premium', 'Senior'],
  ),
  CvTemplate(
    id: 'portfolio-pro',
    name: 'Portfolio Pro',
    description: 'Two-column showcase with photo slot',
    category: CvTemplateCategory.creative,
    layout: CvTemplateLayout.splitColumns,
    primaryColor: Color(0xFF6366F1),
    accentColor: Color(0xFFEEF2FF),
    backgroundColor: Colors.white,
    textColor: Color(0xFF1E1B4B),
    isPremium: true,
    tags: ['Premium', 'Portfolio'],
  ),
  CvTemplate(
    id: 'designer-studio',
    name: 'Designer Studio',
    description: 'Asymmetric layout with bold color blocks',
    category: CvTemplateCategory.creative,
    layout: CvTemplateLayout.sidebarRight,
    primaryColor: Color(0xFFF97316),
    accentColor: Color(0xFF1E293B),
    backgroundColor: Colors.white,
    textColor: Color(0xFF0F172A),
    isPremium: true,
    tags: ['Premium', 'Designer'],
  ),
];

CvTemplate? cvTemplateById(String id) {
  for (final t in cvTemplates) {
    if (t.id == id) return t;
  }
  return null;
}

List<CvTemplate> filterCvTemplates({
  CvTemplateCategory filter = CvTemplateCategory.all,
  bool? premiumOnly,
  bool? freeOnly,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  return cvTemplates.where((t) {
    if (filter != CvTemplateCategory.all && t.category != filter) return false;
    if (premiumOnly == true && !t.isPremium) return false;
    if (freeOnly == true && t.isPremium) return false;
    if (q.isNotEmpty &&
        !t.name.toLowerCase().contains(q) &&
        !t.description.toLowerCase().contains(q) &&
        !t.tags.any((tag) => tag.toLowerCase().contains(q))) {
      return false;
    }
    return true;
  }).toList();
}
