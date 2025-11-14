import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String studentName;
  final VoidCallback onSwitch;
  final VoidCallback? onProfileTap;
  final VoidCallback onLogout;
  final VoidCallback onTranslate;
  final bool showProfileButton;

  const TopNavBar({
    super.key,
    required this.studentName,
    required this.onSwitch,
    this.onProfileTap,
    required this.onLogout,
    required this.onTranslate,
    this.showProfileButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: colorScheme.primary,
      elevation: 0,
      leading: showProfileButton
          ? GestureDetector(
              onTap: onProfileTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.home, color: colorScheme.primary),
                ),
              ),
            )
          : null, // hide if false
      title: Text(
        studentName,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.swap_horiz, color: Colors.white),
          tooltip: 'Switch User',
          onPressed: onSwitch,
        ),
        IconButton(
          icon: const Text(
            'த',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          tooltip: 'Translate',
          onPressed: onTranslate,
        ),
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
