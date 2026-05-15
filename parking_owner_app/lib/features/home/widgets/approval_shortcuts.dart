import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ApprovalShortcuts extends StatelessWidget {
  final bool isDark;
  const ApprovalShortcuts({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final shadow = isDark ? null : [BoxShadow(color: AppColors.primaryLight.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: '승인 대기', isDark: isDark, actionLabel: '전체보기'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ApprovalCard(
                icon: Icons.directions_car_rounded,
                label: '차량 등록 요청',
                count: 3,
                color: AppColors.accentLight,
                cardBg: cardBg,
                shadow: shadow,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ApprovalCard(
                icon: Icons.person_add_rounded,
                label: '입주민 가입 요청',
                count: 2,
                color: AppColors.visitor,
                cardBg: cardBg,
                shadow: shadow,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Color cardBg;
  final List<BoxShadow>? shadow;
  final bool isDark;

  const _ApprovalCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.cardBg,
    required this.shadow,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: shadow,
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.subtextDark : AppColors.subtextLight)),
                  const SizedBox(height: 2),
                  Text('$count건', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color, height: 1.2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final String? actionLabel;

  const _SectionHeader({required this.title, required this.isDark, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
        const Spacer(),
        if (actionLabel != null)
          Text(actionLabel!, style: const TextStyle(fontSize: 10, color: AppColors.accentLight)),
      ],
    );
  }
}
