import 'package:flutter/material.dart';

class DrawerMenuItem {
  final String title;
  final IconData icon;
  final String route;

  DrawerMenuItem(
      {required this.title, required this.icon, required this.route});
}

List<DrawerMenuItem> drawerMenuItems = [
  DrawerMenuItem(title: 'Profile', icon: Icons.person, route: '/profile'),
  DrawerMenuItem(title: 'Settings', icon: Icons.settings, route: '/settings'),
  // Add more menu items here
];
