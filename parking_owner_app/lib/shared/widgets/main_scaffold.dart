import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;

import '../../core/theme/app_colors.dart';
import '../../shared/models/app_state.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/scan/screens/scan_screen.dart';
import '../../features/vehicle/screens/vehicle_screen.dart';
import '../../features/complex/screens/complex_screen.dart';
import '../../features/communication/screens/communication_screen.dart';

final mainScaffoldKey = GlobalKey<ScaffoldState>();

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  static const _screens = [
    HomeScreen(),
    ScanScreen(),
    VehicleScreen(),
    ComplexScreen(),
    CommunicationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(navIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: mainScaffoldKey,
      endDrawer: const AppDrawer(),
      body: IndexedStack(index: navIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: navIndex,
        isDark: isDark,
        onTap: (i) => ref.read(navIndexProvider.notifier).state = i,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded, label: '홈', index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.camera_alt_rounded, label: '스캔', index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.directions_car_rounded, label: '차량관리', index: 2, current: currentIndex, onTap: onTap, badge: '3'),
              _NavItem(icon: Icons.apartment_rounded, label: '단지관리', index: 3, current: currentIndex, onTap: onTap, badge: '2'),
              _NavItem(icon: Icons.chat_bubble_rounded, label: '소통', index: 4, current: currentIndex, onTap: onTap, badge: '5'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final unselectedColor = isDark ? AppColors.subtextDark : AppColors.subtextLight;
    final color = isSelected ? selectedColor : unselectedColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            badge != null
                ? badges.Badge(
                    badgeContent: Text(
                      badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: AppColors.unregistered,
                      padding: EdgeInsets.all(4),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  )
                : Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
