import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../providers/notifications_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../features/cv_maker/providers/cv_maker_provider.dart';
import '../features/cv_maker/screens/cv_maker_home_screen.dart';
import '../providers/shell_navigation_provider.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'premium_screen.dart';
import 'tools_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'static_pages.dart';

Future<void> _shareApplication(BuildContext context) async {
  await Clipboard.setData(const ClipboardData(text: 'Check out PDF Tools at https://pdftools.app'));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'App link copied to clipboard!',
        style: GoogleFonts.poppins(),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF6C63FF),
    ),
  );
}

class AppShellScreen extends StatefulWidget {
  final int initialTab;
  const AppShellScreen({super.key, this.initialTab = 0});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late int _currentIndex;
  final TextEditingController _searchController = TextEditingController();
  ShellNavigationProvider? _shellNav;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.clamp(0, 4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _shellNav = context.read<ShellNavigationProvider>();
      _shellNav!.addListener(_onShellNavRequest);
      context.read<CvMakerProvider>().load();
    });
  }

  void _onShellNavRequest() {
    final pending = _shellNav?.consumePendingTab();
    if (pending != null && mounted) {
      setState(() => _currentIndex = pending.clamp(0, 4));
    }
  }

  @override
  void dispose() {
    _shellNav?.removeListener(_onShellNavRequest);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _navigate(int index) {
    setState(() => _currentIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final unread = context.watch<NotificationsProvider>().unreadCount;
    final pages = [
      const HomeScreen(embeddedInShell: true),
      const ToolsScreen(embeddedInShell: true),
      const CvMakerHomeScreen(),
      const HistoryScreen(embeddedInShell: true),
      _AccountTab(onLogout: _logout),
    ];

    final tabTitles = ['Home', 'Tools', 'CV Maker', 'File History', 'Account'];

    return Scaffold(
      // ── Top Bar ──────────────────────────────────
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          tabTitles[_currentIndex],
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          _NotificationBell(unread: unread),
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ── Sidebar Drawer ───────────────────────────
      drawer: _AppDrawer(
        isDark: isDark,
        currentIndex: _currentIndex,
        searchController: _searchController,
        onNavigate: _navigate,
        onLogout: _logout,
      ),

      // ── Body ─────────────────────────────────────
      body: IndexedStack(index: _currentIndex, children: pages),

      // ── Bottom Nav ───────────────────────────────
      bottomNavigationBar: _ProfessionalBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _ProfessionalBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ProfessionalBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121826) : Colors.white;
    final shadowColor = isDark ? Colors.black45 : Colors.black.withOpacity(0.08);
    final borderColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.06);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            elevation: 0,
            backgroundColor: bg,
            indicatorColor: AppTheme.primaryColor.withOpacity(isDark ? 0.26 : 0.16),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              final selected = states.contains(MaterialState.selected);
              return GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? AppTheme.primaryColor
                    : (isDark ? Colors.white70 : const Color(0xFF6B7280)),
              );
            }),
            iconTheme: MaterialStateProperty.resolveWith((states) {
              final selected = states.contains(MaterialState.selected);
              return IconThemeData(
                size: selected ? 24 : 22,
                color: selected
                    ? AppTheme.primaryColor
                    : (isDark ? Colors.white70 : const Color(0xFF6B7280)),
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.apps_outlined),
                selectedIcon: Icon(Icons.apps_rounded),
                label: 'Tools',
              ),
              NavigationDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description_rounded),
                label: 'CV Maker',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Sidebar Drawer
// ─────────────────────────────────────────────────────────────────
class _AppDrawer extends StatelessWidget {
  final bool isDark;
  final int currentIndex;
  final TextEditingController searchController;
  final void Function(int) onNavigate;
  final Future<void> Function() onLogout;

  const _AppDrawer({
    required this.isDark,
    required this.currentIndex,
    required this.searchController,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF111827) : Colors.white;
    final divColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.06);

    return Drawer(
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Workspace header ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PDF Tools',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        Builder(builder: (ctx) {
                          final isPremium = ctx.watch<CvMakerProvider>().isPremiumUnlocked;
                          return Text(
                            isPremium ? '✨ Premium' : 'Free Plan',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: isPremium ? FontWeight.w700 : FontWeight.w400,
                              color: isPremium
                                  ? Colors.amber.shade600
                                  : (isDark ? Colors.white54 : Colors.black45),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Icon(Icons.unfold_more_rounded,
                      size: 18,
                      color: isDark ? Colors.white38 : Colors.black38),
                ],
              ),
            ),

            Divider(color: divColor, height: 1),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ── Search ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: TextField(
                      controller: searchController,
                      style: GoogleFonts.poppins(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 18,
                            color: isDark ? Colors.white38 : Colors.black38),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  // ── Main nav items ───────────────────────
                  _SideSection(
                    children: [
                      _SideTile(
                        icon: Icons.inbox_rounded,
                        label: 'Home',
                        shortcut: '⌘1',
                        selected: currentIndex == 0,
                        isDark: isDark,
                        onTap: () => onNavigate(0),
                      ),
                _SideTile(
                  icon: Icons.apps_rounded,
                  label: 'Tools',
                  shortcut: '⌘2',
                  selected: currentIndex == 1,
                  isDark: isDark,
                  onTap: () => onNavigate(1),
                ),
                _SideTile(
                  icon: Icons.description_rounded,
                  label: 'CV Maker',
                  shortcut: '⌘3',
                  selected: currentIndex == 2,
                  isDark: isDark,
                  onTap: () => onNavigate(2),
                ),
                _SideTile(
                  icon: Icons.history_rounded,
                  label: 'History',
                  shortcut: '⌘4',
                  selected: currentIndex == 3,
                  isDark: isDark,
                  onTap: () => onNavigate(3),
                ),
                      _SideTile(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications',
                        selected: false,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                _SideTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Account',
                  shortcut: '⌘5',
                  selected: currentIndex == 4,
                  isDark: isDark,
                  onTap: () => onNavigate(4),
                ),
                    ],
                  ),

                  Divider(color: divColor, height: 16),

                  // ── Premium banner ────────────────────────
                  Builder(builder: (ctx) {
                    final isPremium = ctx.watch<CvMakerProvider>().isPremiumUnlocked;
                    if (isPremium) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text('Premium Active ✨',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PremiumScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Upgrade to Premium',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 13),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),

                  Divider(color: divColor, height: 16),

                  // ── Tools section ────────────────────────
                  _SectionLabel(label: 'Tools', isDark: isDark),
                  _SideTile(
                    icon: Icons.call_merge_rounded,
                    label: 'Merge PDF',
                    isDark: isDark,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/tool/merge');
                    },
                  ),
                  _SideTile(
                    icon: Icons.content_cut_rounded,
                    label: 'Split PDF',
                    isDark: isDark,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/tool/split');
                    },
                  ),
                  _SideTile(
                    icon: Icons.compress_rounded,
                    label: 'Compress PDF',
                    isDark: isDark,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/tool/compress');
                    },
                  ),
                  _SideTile(
                    icon: Icons.text_snippet_rounded,
                    label: 'Word to PDF',
                    isDark: isDark,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/tool/word-to-pdf');
                    },
                  ),

                  Divider(color: divColor, height: 16),

                  _SectionLabel(label: 'Company', isDark: isDark),
                  _SideTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About Us',
                    isDark: isDark,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/about');
                    },
                  ),
                  _SideTile(
                    icon: Icons.contact_support_outlined,
                    label: 'Contact Us',
                    isDark: isDark,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/contact');
                    },
                  ),
                  _SideTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    isDark: isDark,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/privacy-policy');
                    },
                  ),
                  _SideTile(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    isDark: isDark,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/terms');
                    },
                  ),
                  _SideTile(
                    icon: Icons.share_rounded,
                    label: 'Share Application',
                    isDark: isDark,
                    selected: false,
                    onTap: () async {
                      Navigator.pop(context);
                      await _shareApplication(context);
                    },
                  ),

                  Divider(color: divColor, height: 1),

                  _SideTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isDark: isDark,
                    selected: false,
                    onTap: () => Navigator.pop(context),
                  ),
                  _SideTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help',
                    isDark: isDark,
                    selected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/contact');
                    },
                  ),
                ],
              ),
            ),

            Divider(color: divColor, height: 1),

            // ── User profile footer ───────────────────
            _DrawerUserFooter(isDark: isDark, onLogout: onLogout),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SideSection extends StatelessWidget {
  final List<Widget> children;
  const _SideSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _SideTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? shortcut;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _SideTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.selected,
    required this.onTap,
    this.shortcut,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isDark
        ? Colors.white.withOpacity(0.08)
        : AppTheme.primaryColor.withOpacity(0.08);
    final textColor = selected
        ? AppTheme.primaryColor
        : (isDark ? Colors.white70 : const Color(0xFF374151));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected ? selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(icon,
                    size: 18,
                    color: selected ? AppTheme.primaryColor : textColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (shortcut != null)
                  Text(
                    shortcut!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerUserFooter extends StatelessWidget {
  final bool isDark;
  final Future<void> Function() onLogout;
  const _DrawerUserFooter({required this.isDark, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService.getUserData(),
        builder: (context, snap) {
          final name = snap.data?['name'] as String? ?? 'Guest';
          final email = snap.data?['email'] as String? ?? '';
          return Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.18),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'G',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.logout_rounded,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.black38),
                tooltip: 'Logout',
                onPressed: () async {
                  Navigator.pop(context);
                  await onLogout();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Notification bell with badge
// ─────────────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  final int unread;
  const _NotificationBell({required this.unread});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      ),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unread > 99 ? '99+' : unread.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Account tab
// ─────────────────────────────────────────────────────────────────

class _AccountTab extends StatelessWidget {
  final Future<void> Function() onLogout;
  const _AccountTab({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cvProvider = context.watch<CvMakerProvider>();
    final isPremium = cvProvider.isPremiumUnlocked;
    final plan = cvProvider.premiumPlan;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person_rounded, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Account',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage session and preferences',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              // ── Premium Status Card ─────────────────────
              isPremium
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded,
                              color: Colors.white, size: 36),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Premium Active ✨',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    )),
                                Text(
                                  plan != null
                                      ? '${plan[0].toUpperCase()}${plan.substring(1)} plan'
                                      : 'All features unlocked',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('Cancel Premium?',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700)),
                                  content: Text(
                                      'This will remove your premium access.',
                                      style: GoogleFonts.poppins()),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Keep'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Cancel Plan',
                                          style: TextStyle(
                                              color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                await context
                                    .read<CvMakerProvider>()
                                    .revokePremium();
                              }
                            },
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white70),
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(fontSize: 12)),
                          ),
                        ],
                      ),
                    )
                  : InkWell(
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (_) => const PremiumScreen())),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.workspace_premium_rounded,
                                color: Colors.white, size: 36),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Upgrade to Premium',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      )),
                                  Text(
                                      'Unlock all templates, colors & more',
                                      style: GoogleFonts.poppins(
                                          color:
                                              Colors.white.withOpacity(0.85),
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    ),

              const SizedBox(height: 24),
              _AccountLinkItem(
                icon: Icons.info_outline_rounded,
                title: 'About Us',
                onTap: () => Navigator.of(context).pushNamed('/about'),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _AccountLinkItem(
                icon: Icons.contact_support_outlined,
                title: 'Contact Us',
                onTap: () => Navigator.of(context).pushNamed('/contact'),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _AccountLinkItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () =>
                    Navigator.of(context).pushNamed('/privacy-policy'),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _AccountLinkItem(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () => Navigator.of(context).pushNamed('/terms'),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _AccountLinkItem(
                icon: Icons.share_rounded,
                title: 'Share Application',
                onTap: () async => await _shareApplication(context),
                isDark: isDark,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountLinkItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;

  const _AccountLinkItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
