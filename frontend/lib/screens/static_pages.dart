import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';

/// Tappable links to legal / company pages — reuse in footer, drawer, etc.
class LegalPageLinks extends StatelessWidget {
  final bool isDark;
  final bool vertical;
  final MainAxisAlignment alignment;

  const LegalPageLinks({
    super.key,
    required this.isDark,
    this.vertical = false,
    this.alignment = MainAxisAlignment.center,
  });

  static const _routes = [
    ('About Us', '/about'),
    ('Contact Us', '/contact'),
    ('Privacy Policy', '/privacy-policy'),
    ('Terms & Conditions', '/terms'),
  ];

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _routes
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LegalLink(
                  label: entry.$1,
                  route: entry.$2,
                  isDark: isDark,
                ),
              ),
            )
            .toList(),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        for (var i = 0; i < _routes.length; i++) ...[
          _LegalLink(label: _routes[i].$1, route: _routes[i].$2, isDark: isDark),
          if (i < _routes.length - 1)
            Text(
              '•',
              style: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 12,
              ),
            ),
        ],
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String route;
  final bool isDark;

  const _LegalLink({
    required this.label,
    required this.route,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(route),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : AppTheme.primaryColor,
            decoration: TextDecoration.underline,
            decorationColor: isDark ? Colors.white38 : AppTheme.primaryColor.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

class _StaticPageScaffold extends StatelessWidget {
  final String title;
  final Widget content;

  const _StaticPageScaffold({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: size.width > 720 ? 680 : double.infinity),
            child: DefaultTextStyle(
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                height: 1.65,
                color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _headingStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: isDark ? Colors.white : const Color(0xFF111827),
  );
}

Widget _section(String title, String body, BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: _headingStyle(context)),
      const SizedBox(height: 8),
      Text(body),
      const SizedBox(height: 24),
    ],
  );
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StaticPageScaffold(
      title: 'Privacy Policy',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last updated: June 3, 2026',
            style: GoogleFonts.poppins(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white38
                  : Colors.black45,
            ),
          ),
          const SizedBox(height: 24),
          _section(
            '1. Information We Collect',
            'We collect minimal information needed to operate PDF Tools. When you upload a file, we process it temporarily to complete your request. We may collect account details (name, email) if you register, usage analytics to improve the service, and technical data such as browser type and device information.',
            context,
          ),
          _section(
            '2. How We Use Your Data',
            'Your data is used solely to provide PDF processing services, maintain and improve the platform, communicate service updates, and ensure security. We do not sell your personal information to third parties.',
            context,
          ),
          _section(
            '3. File Handling & Retention',
            'Uploaded files are processed on secure servers and automatically deleted after processing is complete — typically within one hour. We do not retain your documents longer than necessary.',
            context,
          ),
          _section(
            '4. Data Security',
            'All data is transmitted over HTTPS. We apply industry-standard security measures including encryption in transit, access controls, and regular security reviews.',
            context,
          ),
          _section(
            '5. Cookies & Analytics',
            'We use essential cookies to keep you signed in and remember preferences. Optional analytics help us understand how tools are used so we can improve the experience.',
            context,
          ),
          _section(
            '6. Your Rights',
            'You may request access to, correction of, or deletion of your personal data at any time. Contact us at support@pdftools.app for privacy-related requests.',
            context,
          ),
          _section(
            '7. Changes to This Policy',
            'We may update this Privacy Policy from time to time. Continued use of PDF Tools after changes are posted constitutes acceptance of the revised policy.',
            context,
          ),
        ],
      ),
    );
  }
}

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StaticPageScaffold(
      title: 'Terms & Conditions',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last updated: June 3, 2026',
            style: GoogleFonts.poppins(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white38
                  : Colors.black45,
            ),
          ),
          const SizedBox(height: 24),
          _section(
            '1. Acceptance of Terms',
            'By accessing or using PDF Tools, you agree to these Terms & Conditions and our Privacy Policy. If you do not agree, please do not use the service.',
            context,
          ),
          _section(
            '2. Service Description',
            'PDF Tools provides online document processing features including merge, split, compress, convert, and related utilities. Features may change or be updated without prior notice.',
            context,
          ),
          _section(
            '3. Acceptable Use',
            'You agree to use PDF Tools only for lawful purposes. You must not upload content that infringes copyright, contains malware, or violates any applicable law. You are solely responsible for the files you upload and process.',
            context,
          ),
          _section(
            '4. Intellectual Property',
            'The PDF Tools platform, branding, and software are owned by us. You retain ownership of your uploaded files. We do not claim any rights over your documents.',
            context,
          ),
          _section(
            '5. Disclaimer of Warranties',
            'The service is provided "as is" without warranties of any kind. We do not guarantee uninterrupted or error-free operation, nor that results will meet your specific requirements.',
            context,
          ),
          _section(
            '6. Limitation of Liability',
            'To the fullest extent permitted by law, PDF Tools shall not be liable for any indirect, incidental, or consequential damages arising from your use of the service, including loss of data or business interruption.',
            context,
          ),
          _section(
            '7. Account Termination',
            'We reserve the right to suspend or terminate accounts that violate these terms or abuse the service. You may delete your account at any time from the Account tab.',
            context,
          ),
          _section(
            '8. Governing Law',
            'These terms are governed by applicable local laws. Disputes shall be resolved in the jurisdiction where PDF Tools operates.',
            context,
          ),
        ],
      ),
    );
  }
}

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _StaticPageScaffold(
      title: 'About Us',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'PDF Tools Workspace',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Professional PDF tools — free, fast, and secure',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _section(
            'Our Mission',
            'We built PDF Tools to give everyone access to powerful document utilities without installing heavy software. Whether you merge reports, compress invoices, or convert files on the go, our goal is a seamless experience on every device.',
            context,
          ),
          _section(
            'What We Offer',
            'Our platform includes merge, split, compress, convert, rotate, watermark, and many more tools — all in one workspace. Files are processed quickly and deleted automatically to protect your privacy.',
            context,
          ),
          _section(
            'Our Values',
            'Privacy first: your files are never stored longer than needed. Speed matters: optimized processing keeps wait times low. Accessibility: a clean interface that works on desktop, tablet, and mobile.',
            context,
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatChip(icon: Icons.speed_rounded, label: 'Fast processing', isDark: isDark),
              _StatChip(icon: Icons.lock_outline_rounded, label: 'Secure uploads', isDark: isDark),
              _StatChip(icon: Icons.devices_rounded, label: 'Cross-platform', isDark: isDark),
              _StatChip(icon: Icons.auto_delete_outlined, label: 'Auto file cleanup', isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : AppTheme.primaryColor.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _sending = false);
    _nameController.clear();
    _emailController.clear();
    _subjectController.clear();
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Message sent! We\'ll get back to you within 1–2 business days.',
          style: GoogleFonts.poppins(),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _StaticPageScaffold(
      title: 'Contact Us',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Have a question, feature request, or need help? Fill out the form below or reach us through any of the channels listed.',
          ),
          const SizedBox(height: 32),
          Text('Send a Message', style: _headingStyle(context)),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _ContactField(
                  controller: _nameController,
                  label: 'Your Name',
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 14),
                _ContactField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!v.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _ContactField(
                  controller: _subjectController,
                  label: 'Subject',
                  icon: Icons.subject_rounded,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter a subject' : null,
                ),
                const SizedBox(height: 14),
                _ContactField(
                  controller: _messageController,
                  label: 'Message',
                  icon: Icons.message_outlined,
                  maxLines: 5,
                  validator: (v) =>
                      v == null || v.trim().length < 10
                          ? 'Please enter at least 10 characters'
                          : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _submit,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _sending ? 'Sending…' : 'Send Message',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Text('Other Ways to Reach Us', style: _headingStyle(context)),
          const SizedBox(height: 16),
          _ContactItem(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'support@pdftools.app',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _ContactItem(
            icon: Icons.schedule_rounded,
            title: 'Support Hours',
            subtitle: 'Monday – Friday, 9:00 AM – 5:00 PM EST',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _ContactItem(
            icon: Icons.location_on_outlined,
            title: 'Office',
            subtitle: '123 Tech Boulevard, Suite 400\nNew York, NY 10001',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ContactField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ContactField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _ContactItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 24, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}
