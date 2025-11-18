import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String studentName;
  final String language;
  final VoidCallback onSwitch;
  final VoidCallback? onProfileTap;
  final VoidCallback onTranslate;
  final VoidCallback onToggleTheme;
  final bool showProfileButton;

  const TopNavBar({
    super.key,
    required this.studentName,
    required this.language,
    required this.onSwitch,
    this.onProfileTap,
    required this.onTranslate,
    required this.onToggleTheme,
    this.showProfileButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return AppBar(
      backgroundColor: cs.primary,
      elevation: 0,

      // LEFT SIDE
      leadingWidth: 120,
      leading: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (showProfileButton)
            IconButton(
              onPressed: onProfileTap,
              icon: Icon(Icons.home, color: Colors.white),
            ),
          IconButton(
            onPressed: onSwitch,
            icon: Icon(Icons.swap_horiz, color: Colors.white),
          ),
        ],
      ),

      // CENTER
      title: LayoutBuilder(
        builder: (context, constraints) {
          return Text(
            studentName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: constraints.maxWidth > 150 ? 20 : 16,
            ),
          );
        },
      ),
      centerTitle: true,

      // RIGHT SIDE
      actions: [
        IconButton(
          icon: Icon(
            brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode,
            color: Colors.white,
          ),
          onPressed: onToggleTheme,
        ),
        IconButton(
          icon: Text(
            language == 'ta' ? 'A' : 'த',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          onPressed: onTranslate,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
