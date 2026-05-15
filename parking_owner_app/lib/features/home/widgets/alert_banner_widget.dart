import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AlertBannerWidget extends StatelessWidget {
  final int count;
  final bool isDark;
  const AlertBannerWidget({super.key, required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.unregistered.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.unregistered.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Text('🚨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('미등록 차량 $count대 감지', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.unregistered)),
                const SizedBox(height: 2),
                Text(
                  '즉시 확인이 필요한 차량이 있습니다.',
                  style: TextStyle(fontSize: 10, color: isDark ? AppColors.subtextDark : AppColors.subtextLight),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.unregistered,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('확인', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
