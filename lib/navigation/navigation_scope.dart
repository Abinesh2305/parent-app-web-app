import 'package:flutter/material.dart';

class NavigationScope extends InheritedWidget {
  final void Function(int index) goToTab;

  const NavigationScope({
    super.key,
    required this.goToTab,
    required super.child,
  });

  static NavigationScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NavigationScope>();
  }

  @override
  bool updateShouldNotify(NavigationScope oldWidget) => false;
}
