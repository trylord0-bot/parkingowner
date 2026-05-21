import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../models/app_state.dart';
import 'main_scaffold.dart';

class TabHeader extends ConsumerWidget {
  final String title;
  final bool isDark;
  final Widget? bottom;

  const TabHeader({
    super.key,
    required this.title,
    required this.isDark,
    this.bottom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final complexName = user?.displayComplexName ?? '단지 미설정';
    final roleName = _roleName(user?.role);

    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        bottom != null ? 0 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
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
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
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
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HamLine(),
                      SizedBox(height: 4),
                      _HamLine(),
                      SizedBox(height: 4),
                      _HamLine(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: 8),
            bottom!,
            const SizedBox(height: 2),
          ],
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
  const _HamLine();

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
