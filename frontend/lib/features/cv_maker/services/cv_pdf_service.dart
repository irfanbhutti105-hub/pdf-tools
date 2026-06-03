import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cv_profile.dart';
import '../models/cv_template.dart';

class CvPdfService {
  static Future<Uint8List> generate(CvProfile profile, CvTemplate template, {Color? primaryColor}) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => _buildPage(profile, template, primaryColor),
      ),
    );
    return doc.save();
  }

  static Future<void> share(CvProfile profile, CvTemplate template, {Color? primaryColor}) async {
    final bytes = await generate(profile, template, primaryColor: primaryColor);
    final name = profile.fullName.trim().isEmpty
        ? 'my_cv'
        : profile.fullName.trim().replaceAll(' ', '_').toLowerCase();
    await Printing.sharePdf(bytes: bytes, filename: '${name}_cv.pdf');
  }

  static pw.Widget _buildPage(CvProfile profile, CvTemplate template, Color? customColor) {
    switch (template.layout) {
      case CvTemplateLayout.sidebarLeft:
        return _sidebarPage(profile, template, left: true, customColor: customColor);
      case CvTemplateLayout.sidebarRight:
        return _sidebarPage(profile, template, left: false, customColor: customColor);
      case CvTemplateLayout.headerBand:
        return _headerPage(profile, template, customColor: customColor);
      case CvTemplateLayout.splitColumns:
        return _splitPage(profile, template, customColor: customColor);
      case CvTemplateLayout.singleColumn:
        return _singlePage(profile, template, customColor: customColor);
    }
  }

  static PdfColor _c(Color c) => PdfColor.fromInt(c.value);

  static pw.Widget _sidebarPage(CvProfile profile, CvTemplate template, {required bool left, Color? customColor}) {
    final prim = customColor ?? template.primaryColor;
    
    pw.Widget photoWidget = pw.SizedBox();
    if (profile.photoBase64.isNotEmpty) {
      photoWidget = pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        width: 100,
        height: 100,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          image: pw.DecorationImage(
            image: pw.MemoryImage(base64Decode(profile.photoBase64)),
            fit: pw.BoxFit.cover,
          ),
        ),
      );
    }
    
    final sidebar = pw.Container(
      width: 170,
      color: _c(prim),
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          photoWidget,
          pw.Text(
            profile.fullName,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            profile.jobTitle,
            style: pw.TextStyle(color: PdfColors.grey300, fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          _pdfSection('Contact', [
            profile.email,
            profile.phone,
            profile.location,
            profile.website,
          ], light: true),
          pw.SizedBox(height: 12),
          _pdfSection('Skills', profile.skills, light: true),
          if (profile.languages.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _pdfSection('Languages', profile.languages, light: true),
          ],
        ],
      ),
    );

    final body = pw.Expanded(
      child: pw.Container(
        color: _c(template.backgroundColor),
        padding: const pw.EdgeInsets.all(28),
        child: _pdfMain(profile, template, customColor),
      ),
    );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: left ? [sidebar, body] : [body, sidebar],
    );
  }

  static pw.Widget _headerPage(CvProfile profile, CvTemplate template, {Color? customColor}) {
    final prim = customColor ?? template.primaryColor;
    final isExecutive = template.id == 'executive-gold';
    
    pw.Widget photoWidget = pw.SizedBox();
    if (profile.photoBase64.isNotEmpty) {
      photoWidget = pw.Container(
        margin: const pw.EdgeInsets.only(right: 20),
        width: 80,
        height: 80,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          image: pw.DecorationImage(
            image: pw.MemoryImage(base64Decode(profile.photoBase64)),
            fit: pw.BoxFit.cover,
          ),
        ),
      );
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          color: _c(prim),
          child: pw.Row(
            children: [
              photoWidget,
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile.fullName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: isExecutive ? _c(template.accentColor) : PdfColors.white,
                      ),
                    ),
              pw.SizedBox(height: 4),
              pw.Text(
                profile.jobTitle,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey300,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${profile.email}  •  ${profile.phone}  •  ${profile.location}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400),
              ),
            ],
          ),
          )
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: _pdfMain(profile, template, customColor),
          ),
        ),
      ],
    );
  }

  static pw.Widget _splitPage(CvProfile profile, CvTemplate template, {Color? customColor}) {
    final prim = customColor ?? template.primaryColor;
    
    pw.Widget photoWidget = pw.SizedBox();
    if (profile.photoBase64.isNotEmpty) {
      photoWidget = pw.Container(
        margin: const pw.EdgeInsets.only(right: 20),
        width: 70,
        height: 70,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          image: pw.DecorationImage(
            image: pw.MemoryImage(base64Decode(profile.photoBase64)),
            fit: pw.BoxFit.cover,
          ),
        ),
      );
    }
    
    return pw.Padding(
      padding: const pw.EdgeInsets.all(28),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              photoWidget,
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile.fullName,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _c(prim),
                      ),
                    ),
                    pw.Text(profile.jobTitle, style: const pw.TextStyle(fontSize: 11)),
                  ]
                )
              )
            ]
          ),
          pw.SizedBox(height: 16),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 3, child: _pdfMain(profile, template, customColor, showSkills: false)),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfHeading('Skills', template, customColor),
                      ...profile.skills.map((s) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 3),
                            child: pw.Text('• $s', style: const pw.TextStyle(fontSize: 9)),
                          )),
                      pw.SizedBox(height: 12),
                      _pdfHeading('Languages', template, customColor),
                      ...profile.languages.map((l) => pw.Text(l, style: const pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _singlePage(CvProfile profile, CvTemplate template, {Color? customColor}) {
    final prim = customColor ?? template.primaryColor;
    
    pw.Widget photoWidget = pw.SizedBox();
    if (profile.photoBase64.isNotEmpty) {
      photoWidget = pw.Container(
        margin: const pw.EdgeInsets.only(right: 20),
        width: 60,
        height: 60,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          image: pw.DecorationImage(
            image: pw.MemoryImage(base64Decode(profile.photoBase64)),
            fit: pw.BoxFit.cover,
          ),
        ),
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(32),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              photoWidget,
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile.fullName,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _c(prim),
                      ),
                    ),
                    pw.Text(profile.jobTitle, style: const pw.TextStyle(fontSize: 11)),
                  ]
                )
              )
            ]
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${profile.email} · ${profile.phone} · ${profile.location}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 6),
          pw.Container(height: 2, width: 48, color: _c(prim)),
          pw.SizedBox(height: 14),
          pw.Expanded(child: _pdfMain(profile, template, customColor)),
        ],
      ),
    );
  }

  static pw.Widget _pdfMain(CvProfile profile, CvTemplate template, Color? customColor, {bool showSkills = true}) {
    final prim = customColor ?? template.primaryColor;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (profile.summary.isNotEmpty) ...[
          _pdfHeading('Summary', template, customColor),
          pw.Text(profile.summary, style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.4)),
          pw.SizedBox(height: 12),
        ],
        _pdfHeading('Experience', template, customColor),
        ...profile.experience.expand((exp) => [
              pw.Text(
                exp.role,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${exp.company} · ${exp.period}',
                style: pw.TextStyle(fontSize: 9, color: _c(prim)),
              ),
              pw.Text(
                exp.description,
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.35),
              ),
              pw.SizedBox(height: 8),
            ]),
        _pdfHeading('Education', template, customColor),
        ...profile.education.map(
          (edu) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              '${edu.degree}\n${edu.school} · ${edu.period}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ),
        if (showSkills && profile.skills.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _pdfHeading('Skills', template, customColor),
          pw.Wrap(
            spacing: 6,
            runSpacing: 4,
            children: profile.skills
                .map(
                  (s) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(s, style: const pw.TextStyle(fontSize: 8)),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  static pw.Widget _pdfHeading(String title, CvTemplate template, Color? customColor) {
    final prim = customColor ?? template.primaryColor;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6, top: 4),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 1,
          color: _c(prim),
        ),
      ),
    );
  }

  static pw.Widget _pdfSection(String title, List<String> lines, {bool light = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: light ? PdfColors.grey400 : PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        ...lines.where((l) => l.isNotEmpty).map(
              (l) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  l,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: light ? PdfColors.white : PdfColors.black,
                  ),
                ),
              ),
            ),
      ],
    );
  }
}