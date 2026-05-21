import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/models/app_state.dart';
import 'user_avatar.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final headerBg = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final name = user?.name ?? '최현우';
    final complexName = user?.displayComplexName ?? '단지 미설정';
    final roleName = _roleName(user?.role);
    // GoRouter 인스턴스를 미리 캡처한다.
    // Drawer pop 이후 context가 detach되어도 router는 유효하다.
    final router = GoRouter.of(context);

    return Drawer(
      backgroundColor: bg,
      child: Column(
        children: [
          // 프로필 헤더
          Container(
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 24),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF4A90C8).withValues(alpha: 0.1)
                      : AppColors.primaryLight.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 닫기 버튼
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '✕',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? AppColors.subtextDark
                                : AppColors.subtextLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 이름 + 테마 전환 버튼
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    UserAvatar(
                      name: name,
                      profileImageUrl: user?.profileImageUrl,
                      size: 46,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$name 님',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textDark
                                  : AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 단지 + 역할 배지
                          Row(
                            children: [
                              Icon(
                                Icons.apartment_rounded,
                                size: 13,
                                color: isDark
                                    ? AppColors.subtextDark
                                    : AppColors.subtextLight,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                complexName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.subtextDark
                                      : AppColors.subtextLight,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(
                                          0xFF4A90C8,
                                        ).withValues(alpha: 0.15)
                                      : AppColors.primaryLight.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  roleName,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.primaryDark
                                        : AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).state =
                          isDark ? ThemeMode.light : ThemeMode.dark,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF4A90C8).withValues(alpha: 0.15)
                              : AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 메뉴 리스트
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _DrawerSection(label: '정보', isDark: isDark),
                _DrawerItem(
                  emoji: '🏢',
                  label: '단지 정보',
                  isDark: isDark,
                  onTap: () => router.push('/complex-info'),
                ),
                _DrawerItem(
                  emoji: '➕',
                  label: '단지 변경 / 추가',
                  isDark: isDark,
                  onTap: () => router.push('/onboarding'),
                ),
                _DrawerItem(
                  emoji: '📊',
                  label: '리포트 (통계)',
                  isDark: isDark,
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _DrawerSection(label: '앱', isDark: isDark),
                _DrawerItem(
                  emoji: '👤',
                  label: '프로필',
                  isDark: isDark,
                  onTap: () => router.push('/profile'),
                ),
                _DrawerItem(
                  emoji: '⚙️',
                  label: '설정',
                  isDark: isDark,
                  onTap: () {},
                ),
                _DrawerItem(
                  emoji: '📖',
                  label: '이용 가이드',
                  isDark: isDark,
                  onTap: () {},
                ),
                _DrawerItem(
                  emoji: '💬',
                  label: '고객센터',
                  isDark: isDark,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // 푸터
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF4A90C8).withValues(alpha: 0.1)
                      : AppColors.primaryLight.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () async {
                    Navigator.of(context).pop();
                    await ref.read(authNotifierProvider.notifier).logout();
                  },
                  child: Row(
                    children: [
                      Text('🚪', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        '로그아웃',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.subtextDark
                              : AppColors.subtextLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.subtextDark.withValues(alpha: 0.7)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _roleName(UserRole? role) {
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
}

class _DrawerSection extends StatelessWidget {
  final String label;
  final bool isDark;
  const _DrawerSection({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isDark ? const Color(0xFF607080) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.emoji,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          // Drawer pop 애니메이션이 시작된 다음 프레임에 네비게이션한다.
          // 동기 호출 시 context가 detach된 상태로 push가 실행될 수 있다.
          WidgetsBinding.instance.addPostFrameCallback((_) => onTap());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
              ),
              Text(
                '›',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark
                      ? const Color(0xFF3A5068)
                      : const Color(0xFFC8D6E5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
