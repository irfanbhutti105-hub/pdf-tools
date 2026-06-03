import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/notifications_provider.dart';
import '../core/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<NotificationsProvider>();
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => context.read<NotificationsProvider>().markAllRead(),
              child: Text(
                'Mark all read',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'No notifications',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final n = items[index];
                return ListTile(
                  onTap: () => context.read<NotificationsProvider>().markRead(n.id),
                  tileColor: isDark ? const Color(0xFF1A2138) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  leading: Icon(
                    n.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                    color: n.read ? Colors.grey : AppTheme.primaryColor,
                  ),
                  title: Text(
                    n.title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    n.message,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  trailing: n.read
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.secondaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: items.length,
            ),
    );
  }
}

