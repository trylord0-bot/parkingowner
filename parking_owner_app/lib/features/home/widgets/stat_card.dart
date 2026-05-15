import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;
  final String badge;
  final Color badgeBg;
  final bool isDark;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.badge,
    required this.badgeBg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: AppColors.primaryLight.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Positioned(top: 0, right: 0, child: Text(icon, style: const TextStyle(fontSize: 20))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.subtextDark : AppColors.subtextLight)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color, height: 1),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                child: Text(badge, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
