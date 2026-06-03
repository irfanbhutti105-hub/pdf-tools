import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_theme.dart';
import '../models/cv_profile.dart';
import '../models/cv_template.dart';
import '../providers/cv_maker_provider.dart';
import '../services/cv_pdf_service.dart';
import '../widgets/cv_preview_widget.dart';
import '../../../screens/premium_screen.dart';

class CvEditorScreen extends StatefulWidget {
  const CvEditorScreen({super.key});

  @override
  State<CvEditorScreen> createState() => _CvEditorScreenState();
}

class _CvEditorScreenState extends State<CvEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _exporting = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final provider = context.read<CvMakerProvider>();
      await CvPdfService.share(
        provider.activeProfile ?? provider.savedProfiles.first, 
        provider.selectedTemplate,
        primaryColor: provider.customPrimaryColor,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CV exported as PDF', style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _patchProfile(CvProfile Function(CvProfile) patch) {
    final provider = context.read<CvMakerProvider>();
    provider.updateProfile(patch(provider.activeProfile ?? provider.savedProfiles.first));
    provider.saveActiveProfile(); // Autosave
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CvMakerProvider>();
    final profile = provider.activeProfile ?? CvProfile.sample();
    final template = provider.selectedTemplate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 860;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit CV', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(
              template.name,
              style: GoogleFonts.poppins(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Personal'),
            Tab(text: 'Experience'),
            Tab(text: 'Education'),
            Tab(text: 'Skills'),
            Tab(text: 'More'),
          ],
        ),
        actions: [
          if (!isWide)
            IconButton(
              tooltip: _showPreview ? 'Hide preview' : 'Show preview',
              onPressed: () => setState(() => _showPreview = !_showPreview),
              icon: Icon(_showPreview ? Icons.edit_note_rounded : Icons.visibility_rounded),
            ),
          IconButton(
            tooltip: 'Export PDF',
            onPressed: _exporting ? null : _exportPdf,
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
          ),
        ],
      ),
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _buildForm(profile)),
                VerticalDivider(width: 1, color: isDark ? Colors.white10 : Colors.black12),
                Expanded(flex: 4, child: _buildPreviewPanel(profile, template, isDark, provider.customPrimaryColor)),
              ],
            )
          : Column(
              children: [
                if (_showPreview)
                  SizedBox(
                    height: 260,
                    child: _buildPreviewPanel(profile, template, isDark, provider.customPrimaryColor),
                  ),
                Expanded(child: _buildForm(profile)),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exporting ? null : _exportPdf,
              icon: const Icon(Icons.download_rounded, size: 20),
              label: Text(
                _exporting ? 'Exporting…' : 'Download PDF',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPanel(CvProfile profile, CvTemplate template, bool isDark, Color? customColor) {
    return Container(
      color: isDark ? const Color(0xFF0F1528) : const Color(0xFFE8ECF4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Preview',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 595 / 842,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CvPreviewWidget(
                    profile: profile, 
                    template: template,
                    customColor: customColor,
                    customFont: context.watch<CvMakerProvider>().customFontFamily,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(CvProfile profile) {
    return TabBarView(
      controller: _tabController,
      children: [
        _PersonalTab(
          profile: profile,
          onChanged: _patchProfile,
        ),
        _ExperienceTab(
          profile: profile,
          onChanged: _patchProfile,
        ),
        _EducationTab(
          profile: profile,
          onChanged: _patchProfile,
        ),
        _SkillsTab(
          profile: profile,
          onChanged: _patchProfile,
        ),
        _MoreTab(
          profile: profile,
          onChanged: _patchProfile,
          onReset: () {
            context.read<CvMakerProvider>().resetToSample();
          },
        ),
      ],
    );
  }
}

class _PersonalTab extends StatelessWidget {
  final CvProfile profile;
  final void Function(CvProfile Function(CvProfile)) onChanged;

  const _PersonalTab({required this.profile, required this.onChanged});

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      onChanged((p) => p.copyWith(photoBase64: b64));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return _FormScroll(
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
                image: profile.photoBase64.isNotEmpty
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(profile.photoBase64)),
                        fit: BoxFit.cover,
                      )
                    : null,
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
              ),
              child: profile.photoBase64.isEmpty
                  ? Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryColor, size: 32)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: profile.photoBase64.isNotEmpty 
              ? () => onChanged((p) => p.copyWith(photoBase64: '')) 
              : _pickImage,
            child: Text(profile.photoBase64.isNotEmpty ? 'Remove photo' : 'Add photo'),
          ),
        ),
        const SizedBox(height: 20),
        _Field(
          label: 'CV Title (Internal)',
          value: profile.title,
          onChanged: (v) => onChanged((p) => p.copyWith(title: v)),
        ),
        _Field(
          label: 'Full name',
          value: profile.fullName,
          onChanged: (v) => onChanged((p) => p.copyWith(fullName: v)),
        ),
        _Field(
          label: 'Job title',
          value: profile.jobTitle,
          onChanged: (v) => onChanged((p) => p.copyWith(jobTitle: v)),
        ),
        _Field(
          label: 'Email',
          value: profile.email,
          keyboard: TextInputType.emailAddress,
          onChanged: (v) => onChanged((p) => p.copyWith(email: v)),
        ),
        _Field(
          label: 'Phone',
          value: profile.phone,
          keyboard: TextInputType.phone,
          onChanged: (v) => onChanged((p) => p.copyWith(phone: v)),
        ),
        _Field(
          label: 'Location',
          value: profile.location,
          onChanged: (v) => onChanged((p) => p.copyWith(location: v)),
        ),
        _Field(
          label: 'Website / Portfolio',
          value: profile.website,
          onChanged: (v) => onChanged((p) => p.copyWith(website: v)),
        ),
        _Field(
          label: 'Professional summary',
          value: profile.summary,
          maxLines: 5,
          onChanged: (v) => onChanged((p) => p.copyWith(summary: v)),
        ),
      ],
    );
  }
}

class _ExperienceTab extends StatelessWidget {
  final CvProfile profile;
  final void Function(CvProfile Function(CvProfile)) onChanged;

  const _ExperienceTab({required this.profile, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _FormScroll(
      children: [
        for (var i = 0; i < profile.experience.length; i++)
          _ExperienceCard(
            index: i,
            exp: profile.experience[i],
            onChanged: (exp) {
              final list = List<CvExperience>.from(profile.experience);
              list[i] = exp;
              onChanged((p) => p.copyWith(experience: list));
            },
            onRemove: profile.experience.length > 1
                ? () {
                    final list = List<CvExperience>.from(profile.experience)..removeAt(i);
                    onChanged((p) => p.copyWith(experience: list));
                  }
                : null,
          ),
        OutlinedButton.icon(
          onPressed: () {
            final list = List<CvExperience>.from(profile.experience)
              ..add(CvExperience());
            onChanged((p) => p.copyWith(experience: list));
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add experience'),
        ),
      ],
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final int index;
  final CvExperience exp;
  final ValueChanged<CvExperience> onChanged;
  final VoidCallback? onRemove;

  const _ExperienceCard({
    required this.index,
    required this.exp,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Role ${index + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
            ],
          ),
          _Field(
            label: 'Job title',
            value: exp.role,
            onChanged: (v) => onChanged(CvExperience(
              role: v,
              company: exp.company,
              period: exp.period,
              description: exp.description,
            )),
          ),
          _Field(
            label: 'Company',
            value: exp.company,
            onChanged: (v) => onChanged(CvExperience(
              role: exp.role,
              company: v,
              period: exp.period,
              description: exp.description,
            )),
          ),
          _Field(
            label: 'Period',
            value: exp.period,
            hint: 'e.g. 2020 — Present',
            onChanged: (v) => onChanged(CvExperience(
              role: exp.role,
              company: exp.company,
              period: v,
              description: exp.description,
            )),
          ),
          _Field(
            label: 'Description',
            value: exp.description,
            maxLines: 4,
            onChanged: (v) => onChanged(CvExperience(
              role: exp.role,
              company: exp.company,
              period: exp.period,
              description: v,
            )),
          ),
        ],
      ),
    );
  }
}

class _EducationTab extends StatelessWidget {
  final CvProfile profile;
  final void Function(CvProfile Function(CvProfile)) onChanged;

  const _EducationTab({required this.profile, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _FormScroll(
      children: [
        for (var i = 0; i < profile.education.length; i++)
          _EducationCard(
            edu: profile.education[i],
            onChanged: (edu) {
              final list = List<CvEducation>.from(profile.education);
              list[i] = edu;
              onChanged((p) => p.copyWith(education: list));
            },
            onRemove: profile.education.length > 1
                ? () {
                    final list = List<CvEducation>.from(profile.education)..removeAt(i);
                    onChanged((p) => p.copyWith(education: list));
                  }
                : null,
          ),
        OutlinedButton.icon(
          onPressed: () {
            final list = List<CvEducation>.from(profile.education)..add(CvEducation());
            onChanged((p) => p.copyWith(education: list));
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add education'),
        ),
      ],
    );
  }
}

class _EducationCard extends StatelessWidget {
  final CvEducation edu;
  final ValueChanged<CvEducation> onChanged;
  final VoidCallback? onRemove;

  const _EducationCard({
    required this.edu,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          if (onRemove != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ),
          _Field(
            label: 'Degree',
            value: edu.degree,
            onChanged: (v) => onChanged(CvEducation(degree: v, school: edu.school, period: edu.period)),
          ),
          _Field(
            label: 'School / University',
            value: edu.school,
            onChanged: (v) => onChanged(CvEducation(degree: edu.degree, school: v, period: edu.period)),
          ),
          _Field(
            label: 'Period',
            value: edu.period,
            onChanged: (v) => onChanged(CvEducation(degree: edu.degree, school: edu.school, period: v)),
          ),
        ],
      ),
    );
  }
}

class _SkillsTab extends StatefulWidget {
  final CvProfile profile;
  final void Function(CvProfile Function(CvProfile)) onChanged;

  const _SkillsTab({required this.profile, required this.onChanged});

  @override
  State<_SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends State<_SkillsTab> {
  final _skillCtrl = TextEditingController();

  @override
  void dispose() {
    _skillCtrl.dispose();
    super.dispose();
  }

  void _addSkill() {
    final s = _skillCtrl.text.trim();
    if (s.isEmpty) return;
    final list = List<String>.from(widget.profile.skills)..add(s);
    widget.onChanged((p) => p.copyWith(skills: list));
    _skillCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return _FormScroll(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillCtrl,
                decoration: const InputDecoration(
                  labelText: 'Add skill',
                  hintText: 'e.g. Flutter',
                ),
                onSubmitted: (_) => _addSkill(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addSkill,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.profile.skills.map((s) {
            return InputChip(
              label: Text(s),
              onDeleted: () {
                final list = List<String>.from(widget.profile.skills)..remove(s);
                widget.onChanged((p) => p.copyWith(skills: list));
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MoreTab extends StatefulWidget {
  final CvProfile profile;
  final void Function(CvProfile Function(CvProfile)) onChanged;
  final VoidCallback onReset;

  const _MoreTab({
    required this.profile,
    required this.onChanged,
    required this.onReset,
  });

  @override
  State<_MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<_MoreTab> {
  final _langCtrl = TextEditingController();

  @override
  void dispose() {
    _langCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormScroll(
      children: [
        Text('Languages', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _langCtrl,
                decoration: const InputDecoration(hintText: 'e.g. English (Fluent)'),
                onSubmitted: (v) {
                  if (v.trim().isEmpty) return;
                  final list = List<String>.from(widget.profile.languages)..add(v.trim());
                  widget.onChanged((p) => p.copyWith(languages: list));
                  _langCtrl.clear();
                },
              ),
            ),
            IconButton.filled(
              onPressed: () {
                final v = _langCtrl.text.trim();
                if (v.isEmpty) return;
                final list = List<String>.from(widget.profile.languages)..add(v);
                widget.onChanged((p) => p.copyWith(languages: list));
                _langCtrl.clear();
              },
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.profile.languages.map(
          (l) => ListTile(
            title: Text(l),
            trailing: IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () {
                final list = List<String>.from(widget.profile.languages)..remove(l);
                widget.onChanged((p) => p.copyWith(languages: list));
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Custom Style (Premium)', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final c in [
              const Color(0xFF6C63FF),
              const Color(0xFF1E3A5F),
              const Color(0xFF0EA5E9),
              const Color(0xFFEC4899),
              const Color(0xFF10B981),
              const Color(0xFF7C2D12),
            ])
              GestureDetector(
                onTap: () {
                  final provider = context.read<CvMakerProvider>();
                  if (provider.isPremiumUnlocked) {
                    provider.updateCustomStyle(color: c);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PremiumScreen()),
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.read<CvMakerProvider>().customPrimaryColor == c 
                          ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Typography (Premium)', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Builder(
          builder: (ctx) {
            final provider = ctx.watch<CvMakerProvider>();
            final currentFont = provider.customFontFamily ?? 'Roboto';
            final fonts = ['Roboto', 'Open Sans', 'Lora', 'Playfair Display', 'Merriweather', 'Lato'];

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fonts.map((font) {
                final isSelected = currentFont == font;
                return ActionChip(
                  label: Text(font),
                  backgroundColor: isSelected 
                      ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF6C63FF) : const Color(0xFFE0E7FF)) 
                      : null,
                  labelStyle: GoogleFonts.getFont(
                    font,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected 
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF6C63FF))
                        : null,
                  ),
                  onPressed: () {
                    if (provider.isPremiumUnlocked) {
                      provider.updateCustomStyle(fontFamily: font);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PremiumScreen()),
                      );
                    }
                  },
                );
              }).toList(),
            );
          }
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: widget.onReset,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reset to sample data'),
        ),
      ],
    );
  }
}

class _FormScroll extends StatelessWidget {
  final List<Widget> children;

  const _FormScroll({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }
}

class _Field extends StatefulWidget {
  final String label;
  final String value;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboard;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.keyboard,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_Field oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && widget.value != oldWidget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controller,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboard,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
