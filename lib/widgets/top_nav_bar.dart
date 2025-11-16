import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String studentName;
  final String language;
  final VoidCallback onSwitch;
  final VoidCallback? onProfileTap;
  final VoidCallback onLogout;
  final VoidCallback onTranslate;
  final VoidCallback onToggleTheme; // ADDED
  final bool showProfileButton;

  const TopNavBar({
    super.key,
    required this.studentName,
    required this.language,
    required this.onSwitch,
    this.onProfileTap,
    required this.onLogout,
    required this.onTranslate,
    required this.onToggleTheme, // ADDED
    this.showProfileButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return AppBar(
      backgroundColor: cs.primary,
      elevation: 0,
      leading: showProfileButton
          ? GestureDetector(
              onTap: onProfileTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.home, color: cs.primary),
                ),
              ),
            )
          : null,
      title: Text(
        studentName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // SWITCH USER
        IconButton(
          icon: const Icon(Icons.swap_horiz, color: Colors.white),
          tooltip: 'Switch User',
          onPressed: onSwitch,
        ),

        // LANGUAGE TOGGLE (A <-> த)
        IconButton(
          icon: Text(
            language == 'ta' ? 'A' : 'த',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          tooltip: 'Translate',
          onPressed: onTranslate,
        ),

        // THEME SWITCHER (Light / Dark / System)
        IconButton(
          icon: Icon(
            brightness == Brightness.light
                ? Icons.dark_mode // currently light → show dark mode icon
                : Icons.light_mode, // currently dark → show light mode icon
            color: Colors.white,
          ),
          tooltip: 'Toggle Theme',
          onPressed: onToggleTheme,
        ),

        // LOGOUT
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Logout',
          onPressed: onLogout,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
