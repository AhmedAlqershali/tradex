import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/shared/navigation/nav_config.dart';
import 'package:ai_saas/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BnScreen extends StatefulWidget {
  final AppType type;

  const BnScreen({super.key, required this.type});

  @override
  State<BnScreen> createState() => _BnScreenState();
}

class _BnScreenState extends State<BnScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final items = NavConfig.getItems(widget.type, AppLocalizations.of(context));
    if (items.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(AppLocalizations.of(context).noScreensAvailable),
        ),
      );
    }
    final selectedIndex = _currentIndex.clamp(0, items.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [for (final item in items) item.widget],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        iconSize: 24.sp,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: List.generate(items.length, (index) {
          final item = items[index];
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.title,
          );
        }),
      ),
    );
  }
}
