import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String studentName;
  final String language;
  final VoidCallback onSwitch;
  final VoidCallback onProfileTap;
  final VoidCallback onTranslate;
  final VoidCallback onToggleTheme;

  const TopNavBar({
    super.key,
    required this.studentName,
    required this.language,
    required this.onSwitch,
    required this.onProfileTap,
    required this.onTranslate,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return AppBar(
      backgroundColor: cs.primary,
      elevation: 0,

      // 🔥 LEFT AREA (FIXED)
      leadingWidth: 140,
      leading: Row(
        children: [
          _tapIcon(Icons.home, onProfileTap),
          _tapIcon(Icons.swap_horiz, onSwitch),
        ],
      ),

      // 🔥 CENTER
      title: Text(
        studentName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,

      // 🔥 RIGHT
      actions: [
        _tapIcon(
          isLight ? Icons.dark_mode : Icons.light_mode,
          onToggleTheme,
        ),
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTranslate,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              language == 'ta' ? 'A' : 'த',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tapIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
