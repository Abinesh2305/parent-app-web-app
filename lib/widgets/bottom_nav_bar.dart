import 'package:flutter/material.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;

    // Full item list — Profile is logical index 0 (hidden)
    final allItems = [
      _HiddenNavItem(), // index 0 = Profile (not displayed)
      _NavItem(icon: Icons.book, label: t.homework), // 1
      _NavItem(icon: Icons.notifications, label: t.notifications), // 2
      _NavItem(icon: Icons.grid_view, label: t.menu, isCenter: true), // 3
      _NavItem(icon: Icons.calendar_month, label: t.attendance), // 4
      _NavItem(icon: Icons.currency_rupee, label: t.fees), // 5
    ];

    // Visible items (skip hidden profile)
    final visibleItems = allItems.sublist(1);

    // When in profile (index 0) => no tab selected (null selection)
    final visibleSelectedIndex = (currentIndex == 0)
        ? null
        : (currentIndex - 1).clamp(0, visibleItems.length - 1);

    void handleTap(int uiIndex) {
      // Shift by +1 because index 0 = Profile
      final actualIndex = uiIndex + 1;
      onTap(actualIndex);
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        // Use safe default when profile (Flutter requires valid int)
        currentIndex: visibleSelectedIndex ?? 0,
        onTap: handleTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,

        // IMPORTANT: hide default labels because we render our own (so we can wrap)
        showSelectedLabels: false,
        showUnselectedLabels: false,

        items: List.generate(visibleItems.length, (i) {
          final item = visibleItems[i];
          final isActive = (visibleSelectedIndex == i);

          // reusable label widget to allow wrapping, multi-line, center alignment
          Widget buildLabel() {
            return Container(
              padding: const EdgeInsets.only(top: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown, // Auto-shrink text to fit one line
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.visible, // Keep full text
                  style: TextStyle(
                    color:
                        isActive ? Colors.white : Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }

          if (item.isCenter) {
            return BottomNavigationBarItem(
              // Put both the circular icon and label inside the icon widget
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (isActive)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Icon(
                      item.icon,
                      size: 28,
                      color: isActive ? colorScheme.primary : Colors.white,
                    ),
                  ),
                  buildLabel(),
                ],
              ),
              label: '',
            );
          } else {
            return BottomNavigationBarItem(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color:
                        isActive ? Colors.white : Colors.white.withOpacity(0.6),
                  ),
                  buildLabel(),
                ],
              ),
              label: '',
            );
          }
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool isCenter;
  const _NavItem({
    required this.icon,
    required this.label,
    this.isCenter = false,
  });
}

class _HiddenNavItem extends _NavItem {
  const _HiddenNavItem()
      : super(icon: Icons.person, label: '', isCenter: false);
}
