import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/cv_profile.dart';
import '../models/cv_template.dart';

/// Renders a scaled CV preview for gallery thumbnails and the editor.
class CvPreviewWidget extends StatelessWidget {
  final CvProfile profile;
  final CvTemplate template;
  final bool interactive;
  final Color? customColor;
  final String? customFont;

  const CvPreviewWidget({
    super.key,
    required this.profile,
    required this.template,
    this.interactive = false,
    this.customColor,
    this.customFont,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _CvPage(
          profile: profile,
          template: template,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          customColor: customColor,
          customFont: customFont,
        );
      },
    );
  }
}

class _CvPage extends StatelessWidget {
  final CvProfile profile;
  final CvTemplate template;
  final double width;
  final double height;
  final Color? customColor;
  final String? customFont;

  const _CvPage({
    required this.profile,
    required this.template,
    required this.width,
    required this.height,
    this.customColor,
    this.customFont,
  });

  double get _scale => (width / 595).clamp(0.35, 1.0);

  @override
  Widget build(BuildContext context) {
    switch (template.layout) {
      case CvTemplateLayout.sidebarLeft:
        return _SidebarLayout(
          profile: profile,
          template: template,
          sidebarLeft: true,
          scale: _scale,
          customColor: customColor,
          customFont: customFont,
        );
      case CvTemplateLayout.sidebarRight:
        return _SidebarLayout(
          profile: profile,
          template: template,
          sidebarLeft: false,
          scale: _scale,
          customColor: customColor,
          customFont: customFont,
        );
      case CvTemplateLayout.headerBand:
        return _HeaderBandLayout(
          profile: profile,
          template: template,
          scale: _scale,
          customColor: customColor,
          customFont: customFont,
        );
      case CvTemplateLayout.splitColumns:
        return _SplitColumnLayout(
          profile: profile,
          template: template,
          scale: _scale,
          customColor: customColor,
          customFont: customFont,
        );
      case CvTemplateLayout.singleColumn:
        return _SingleColumnLayout(
          profile: profile,
          template: template,
          scale: _scale,
          customColor: customColor,
          customFont: customFont,
        );
    }
  }
}

class _SidebarLayout extends StatelessWidget {
  final CvProfile profile;
  final CvTemplate template;
  final bool sidebarLeft;
  final double scale;
  final Color? customColor;
  final String? customFont;

  const _SidebarLayout({
    required this.profile,
    required this.template,
    required this.sidebarLeft,
    required this.scale,
    this.customColor,
    this.customFont,
  });

  @override
  Widget build(BuildContext context) {
    final prim = customColor ?? template.primaryColor;
    final sidebar = Container(
      width: 140 * scale,
      color: template.id == 'creative-gradient'
          ? null
          : prim,
      decoration: template.id == 'creative-gradient'
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [prim, template.accentColor],
              ),
            )
          : null,
      padding: EdgeInsets.all(12 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(scale: scale, color: Colors.white.withOpacity(0.25), profile: profile),
          SizedBox(height: 10 * scale),
          Text(
            profile.fullName,
            style: _style(scale, 11, FontWeight.w700, Colors.white, font: customFont),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4 * scale),
          Text(
            profile.jobTitle,
            style: _style(scale, 8, FontWeight.w500, Colors.white70, font: customFont),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12 * scale),
          _SidebarBlock(
            scale: scale,
            title: 'Contact',
            lines: [profile.email, profile.phone, profile.location],
            light: true,
            font: customFont,
          ),
          SizedBox(height: 8 * scale),
          _SidebarBlock(
            scale: scale,
            title: 'Skills',
            lines: profile.skills.take(5).toList(),
            light: true,
            font: customFont,
          ),
        ],
      ),
    );

    final main = Expanded(
      child: Container(
        color: template.backgroundColor,
        padding: EdgeInsets.all(14 * scale),
        child: _MainContent(profile: profile, template: template, scale: scale, customColor: customColor, customFont: customFont),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: ColoredBox(
        color: template.backgroundColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: sidebarLeft ? [sidebar, main] : [main, sidebar],
        ),
      ),
    );
  }
}

class _HeaderBandLayout extends StatelessWidget {
  final CvProfile profile;
  final CvTemplate template;
  final double scale;
  final Color? customColor;
  final String? customFont;

  const _HeaderBandLayout({
    required this.profile,
    required this.template,
    required this.scale,
    this.customColor,
    this.customFont,
  });

  @override
  Widget build(BuildContext context) {
    final prim = customColor ?? template.primaryColor;
    final isExecutive = template.id == 'executive-gold';
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: ColoredBox(
        color: template.backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 14 * scale,
              ),
              color: prim,
              child: Row(
                children: [
                  _Avatar(scale: scale, color: Colors.white.withOpacity(0.25), profile: profile),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                    profile.fullName,
                    style: _style(
                      scale,
                      14,
                      FontWeight.w700,
                      isExecutive ? template.accentColor : Colors.white,
                    ),
                  ),
                  SizedBox(height: 3 * scale),
                  Text(
                    profile.jobTitle,
                    style: _style(
                      scale,
                      9,
                      FontWeight.w500,
                      isExecutive ? Colors.white70 : Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Text(
                    '${profile.email}  •  ${profile.phone}  •  ${profile.location}',
                    style: _style(scale, 7, FontWeight.w400, Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ]
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(14 * scale),
              child: _MainContent(
                profile: profile,
                template: template,
                scale: scale,
                customColor: customColor,
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _SplitColumnLayout extends StatelessWidget {
  final CvProfile profile;
  final CvTemplate template;
  final double scale;
  final Color? customColor;
  final String? customFont;

  const _SplitColumnLayout({
    required this.profile,
    required this.template,
    required this.scale,
    this.customColor,
    this.customFont,
  });

  @override
  Widget build(BuildContext context) {
    final prim = customColor ?? template.primaryColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: ColoredBox(
        color: template.backgroundColor,
        child: Padding(
          padding: EdgeInsets.all(12 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(scale: scale, color: prim.withOpacity(0.15), profile: profile),
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: _style(scale, 13, FontWeight.w700, prim),
                        ),
                        Text(
                          profile.jobTitle,
                          style: _style(scale, 9, FontWeight.w500, template.textColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10 * scale),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _MainContent(
                        profile: profile,
                        template: template,
                        scale: scale,
                        showSkills: false,
                        customColor: customColor,
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('Skills', template, scale, customColor: customColor),
                          ...profile.skills.take(6).map(
                                (s) => Padding(
                                  padding: EdgeInsets.only(bottom: 3 * scale),
                                  child: Text(
                                    '• $s',
                                    style: _style(scale, 7.5, FontWeight.w500, template.textColor),
                                  ),
                                ),
                              ),
                          SizedBox(height: 8 * scale),
                          _SectionTitle('Languages', template, scale, customColor: customColor),
                          ...profile.languages.map(
                            (l) => Text(
                              l,
                              style: _style(scale, 7, FontWeight.w400, template.textColor.withOpacity(0.8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SingleColumnLayout extends StatelessWidget {
  final CvProfile profile;
  final CvTemplate template;
  final double scale;
  final Color? customColor;
  final String? customFont;

  const _SingleColumnLayout({
    required this.profile,
    required this.template,
    required this.scale,
    this.customColor,
    this.customFont,
  });

  @override
  Widget build(BuildContext context) {
    final prim = customColor ?? template.primaryColor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: ColoredBox(
        color: template.backgroundColor,
        child: Padding(
          padding: EdgeInsets.all(14 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(scale: scale, color: prim.withOpacity(0.15), profile: profile),
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: _style(scale, 13, FontWeight.w700, prim, font: customFont),
                        ),
                        Text(
                          profile.jobTitle,
                          style: _style(scale, 9, FontWeight.w500, template.textColor, font: customFont),
                        ),
                      ]
                    )
                  )
                ]
              ),
              SizedBox(height: 4 * scale),
              Text(
                '${profile.email} · ${profile.phone} · ${profile.location}',
                style: _style(scale, 7, FontWeight.w400, template.textColor.withOpacity(0.7), font: customFont),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2 * scale),
              Container(
                height: 2 * scale,
                width: 40 * scale,
                color: prim,
              ),
              SizedBox(height: 8 * scale),
              Expanded(
                child: _MainContent(
                  profile: profile,
                  template: template,
                  scale: scale,
                  customColor: customColor,
                  customFont: customFont,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  final CvProfile profile;
  final CvTemplate template;
  final double scale;
  final bool showSkills;
  final Color? customColor;
  final String? customFont;

  const _MainContent({
    required this.profile,
    required this.template,
    required this.scale,
    this.showSkills = true,
    this.customColor,
    this.customFont,
  });

  @override
  Widget build(BuildContext context) {
    final prim = customColor ?? template.primaryColor;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.summary.isNotEmpty) ...[
            _SectionTitle('Summary', template, scale, customColor: customColor),
            Text(
              profile.summary,
              style: _style(scale, 7.5, FontWeight.w400, template.textColor.withOpacity(0.85), font: customFont),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8 * scale),
          ],
          _SectionTitle('Experience', template, scale, customColor: customColor),
          ...profile.experience.take(2).map(
                (exp) => Padding(
                  padding: EdgeInsets.only(bottom: 6 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.role,
                        style: _style(scale, 8.5, FontWeight.w700, template.textColor, font: customFont),
                      ),
                      Text(
                        '${exp.company} · ${exp.period}',
                        style: _style(scale, 7, FontWeight.w500, prim, font: customFont),
                      ),
                      Text(
                        exp.description,
                        style: _style(scale, 7, FontWeight.w400, template.textColor.withOpacity(0.75), font: customFont),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          SizedBox(height: 6 * scale),
          _SectionTitle('Education', template, scale, customColor: customColor),
          ...profile.education.take(1).map(
                (edu) => Text(
                  '${edu.degree}\n${edu.school} · ${edu.period}',
                  style: _style(scale, 7, FontWeight.w400, template.textColor.withOpacity(0.8), font: customFont),
                ),
              ),
          if (showSkills && profile.skills.isNotEmpty) ...[
            SizedBox(height: 6 * scale),
            _SectionTitle('Skills', template, scale, customColor: customColor),
            Wrap(
              spacing: 4 * scale,
              runSpacing: 4 * scale,
              children: profile.skills
                  .take(6)
                  .map(
                    (s) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6 * scale,
                        vertical: 2 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: prim.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s,
                        style: _style(scale, 6.5, FontWeight.w600, prim, font: customFont),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final CvTemplate template;
  final double scale;
  final Color? customColor;

  const _SectionTitle(this.title, this.template, this.scale, {this.customColor});

  @override
  Widget build(BuildContext context) {
    final prim = customColor ?? template.primaryColor;
    return Padding(
      padding: EdgeInsets.only(bottom: 4 * scale, top: 2 * scale),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 7.5 * scale,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: prim,
        ),
      ),
    );
  }
}

class _SidebarBlock extends StatelessWidget {
  final double scale;
  final String title;
  final List<String> lines;
  final bool light;
  final String? font;

  const _SidebarBlock({
    required this.scale,
    required this.title,
    required this.lines,
    this.light = false,
    this.font,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: _style(scale, 7, FontWeight.w700, light ? Colors.white70 : Colors.black54, font: font),
        ),
        SizedBox(height: 4 * scale),
        ...lines.where((l) => l.isNotEmpty).take(3).map(
              (l) => Padding(
                padding: EdgeInsets.only(bottom: 2 * scale),
                child: Text(
                  l,
                  style: _style(scale, 6.5, FontWeight.w400, light ? Colors.white : Colors.black87, font: font),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final double scale;
  final Color color;
  final CvProfile? profile;

  const _Avatar({required this.scale, required this.color, this.profile});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profile != null && profile!.photoBase64.isNotEmpty;
    return Container(
      width: 36 * scale,
      height: 36 * scale,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8 * scale),
        image: hasPhoto 
          ? DecorationImage(
              image: MemoryImage(base64Decode(profile!.photoBase64)), 
              fit: BoxFit.cover
            ) 
          : null,
      ),
      child: hasPhoto ? null : Icon(Icons.person_rounded, color: Colors.white54, size: 20 * scale),
    );
  }
}

TextStyle _style(double scale, double size, FontWeight weight, Color color, {String? font}) {
  return GoogleFonts.getFont(
    font ?? 'Poppins',
    fontSize: size * scale,
    fontWeight: weight,
    color: color,
    height: 1.25,
  );
}
