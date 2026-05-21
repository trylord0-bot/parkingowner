import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/app_state.dart';
import '../../../shared/widgets/main_scaffold.dart';
import '../widgets/stat_card.dart';
import '../widgets/alert_banner_widget.dart';
import '../widgets/approval_shortcuts.dart';
import '../widgets/activity_feed.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vehicles = ref.watch(mockVehiclesProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;

    final registered = vehicles
        .where((v) => v.type == VehicleType.registered)
        .length;
    final visitor = vehicles.where((v) => v.type == VehicleType.visitor).length;
    final unregistered = vehicles
        .where((v) => v.type == VehicleType.unregistered)
        .length;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          _HomeHeader(
            isDark: isDark,
            complexName: user?.displayComplexName ?? '단지 미설정',
            roleName: _roleName(user?.role),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  await Future.delayed(const Duration(milliseconds: 800)),
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _StatGrid(
                    registered: registered,
                    visitor: visitor,
                    unregistered: unregistered,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  if (unregistered > 0) ...[
                    AlertBannerWidget(count: unregistered, isDark: isDark),
                    const SizedBox(height: 12),
                  ],
                  ApprovalShortcuts(isDark: isDark),
                  const SizedBox(height: 12),
                  ActivityFeed(isDark: isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final bool isDark;
  final String complexName;
  final String roleName;

  const _HomeHeader({
    required this.isDark,
    required this.complexName,
    required this.roleName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ParkingOwner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.apartment_rounded,
                      color: Colors.white60,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        complexName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        roleName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => mainScaffoldKey.currentState?.openEndDrawer(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HamLine(),
                  const SizedBox(height: 4),
                  _HamLine(),
                  const SizedBox(height: 4),
                  _HamLine(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _roleName(UserRole? role) {
  switch (role) {
    case UserRole.appAdmin:
      return '앱 관리자';
    case UserRole.complexManager:
      return '단지 관리자';
    case UserRole.attendant:
      return '주차 관리원';
    case UserRole.resident:
      return '세대원';
    case null:
      return '단지 관리자';
  }
}

class _HamLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      width: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final int registered;
  final int visitor;
  final int unregistered;
  final bool isDark;

  const _StatGrid({
    required this.registered,
    required this.visitor,
    required this.unregistered,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: '실시간 현황', isDark: isDark),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: '등록 차량',
                value: '$registered',
                icon: '🚗',
                color: AppColors.registered,
                badge: '정기',
                badgeBg: AppColors.registeredBg,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: '방문 차량',
                value: '$visitor',
                icon: '🔔',
                color: AppColors.visitor,
                badge: '일시',
                badgeBg: AppColors.visitorBg,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: '미등록 감지',
                value: '$unregistered',
                icon: '⚠️',
                color: AppColors.unregistered,
                badge: '경고',
                badgeBg: AppColors.unregisteredBg,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _SlotCard(isDark: isDark)),
          ],
        ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  final bool isDark;
  const _SlotCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const used = 142;
    const total = 200;
    const ratio = used / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primaryLight.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '주차 현황',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.subtextDark
                            : AppColors.subtextLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$used',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Text('🏢', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryDark.withOpacity(0.12)
                  : AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: ratio,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2D6098), const Color(0xFF78B8E8)]
                        : [AppColors.primaryLight, AppColors.accentLight],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$used대',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                ),
              ),
              Text(
                '/ $total대',
                style: TextStyle(
                  fontSize: 9,
                  color: isDark
                      ? AppColors.subtextDark
                      : AppColors.subtextLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.isDark,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.accentLight,
              ),
            ),
          ),
      ],
    );
  }
}
