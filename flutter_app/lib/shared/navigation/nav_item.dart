import 'package:flutter/material.dart';

class BnItem {
  final Widget widget;
  final String title;
  final IconData icon;
  final IconData activeIcon;

  const BnItem({
    required this.widget,
    required this.title,
    required this.icon,
    required this.activeIcon,
  });
}