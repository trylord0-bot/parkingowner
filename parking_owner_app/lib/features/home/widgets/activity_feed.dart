import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/app_state.dart';

class ActivityFeed extends ConsumerWidget {
  final bool isDark;
  const ActivityFeed({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(mockEntryLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('최근 입출차', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
            const Spacer(),
            Text('전체보기', style: const TextStyle(fontSize: 10, color: AppColors.accentLight)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark ? null : [BoxShadow(color: AppColors.primaryLight.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              for (int i = 0; i < logs.length; i++) ...[
                _ActivityItem(log: logs[i], isDark: isDark),
                if (i < logs.length - 1)
                  Divider(
                    height: 1,
                    color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withOpacity(0.08),
                    indent: 56,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final EntryLog log;
  final bool isDark;

  const _ActivityItem({required this.log, required this.isDark});

  Color get _typeColor {
    switch (log.type) {
      case VehicleType.registered: return AppColors.registered;
      case VehicleType.visitor: return AppColors.visitor;
      case VehicleType.unregistered: return AppColors.unregistered;
    }
  }

  String get _typeLabel {
    switch (log.type) {
      case VehicleType.registered: return '등록';
      case VehicleType.visitor: return '방문';
      case VehicleType.unregistered: return '미등록';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(10)),
            child: Icon(log.isEntry ? Icons.login_rounded : Icons.logout_rounded, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.vehiclePlate,
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(8)),
                      child: Text(_typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      log.isEntry ? '입차' : '출차',
                      style: TextStyle(fontSize: 10, color: isDark ? AppColors.subtextDark : AppColors.subtextLight),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(_timeAgo(log.timestamp), style: TextStyle(fontSize: 10, color: isDark ? AppColors.subtextDark : AppColors.subtextLight)),
        ],
      ),
    );
  }
}
