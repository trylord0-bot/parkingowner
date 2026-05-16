import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/app_state.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authNotifierProvider).valueOrNull;

    final name = user?.name ?? '최현우';
    final email = user?.email ?? 'choi@happy-apt.com';
    final roleName = _roleName(user?.role);
    final complexName = user?.complexName ?? '행복마을아파트';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          _Header(isDark: isDark),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProfileHero(
                  isDark: isDark,
                  name: name,
                  roleName: roleName,
                  complexName: complexName,
                ),
                const SizedBox(height: 12),
                _AccountCard(isDark: isDark, email: email),
                const SizedBox(height: 12),
                _SettingsCard(isDark: isDark, ref: ref),
                const SizedBox(height: 12),
                _SecurityCard(isDark: isDark),
                const SizedBox(height: 20),
                _LogoutButton(isDark: isDark, ref: ref, context: context),
                const SizedBox(height: 32),
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

// ── 헤더 ──────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 4, 8, 14),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            padding: EdgeInsets.zero,
          ),
          const Expanded(
            child: Text(
              '내 프로필',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.edit_outlined, size: 19, color: Colors.white.withValues(alpha: 0.7)),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── 공통 카드 ─────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Card({required this.isDark, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
        ),
      ),
    );
  }
}

// ── 프로필 히어로 ──────────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final bool isDark;
  final String name;
  final String roleName;
  final String complexName;

  const _ProfileHero({
    required this.isDark,
    required this.name,
    required this.roleName,
    required this.complexName,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return _Card(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          // 아바타
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 이름
          Text(
            name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 6),
          // 역할 배지 + 단지명
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Icon(Icons.apartment_rounded,
                      size: 12,
                      color: isDark ? AppColors.subtextDark : AppColors.subtextLight),
                  const SizedBox(width: 3),
                  Text(
                    complexName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 계정 정보 ──────────────────────────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  final bool isDark;
  final String email;

  const _AccountCard({required this.isDark, required this.email});

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: '계정 정보', isDark: isDark),
          _InfoRow(icon: Icons.email_rounded, label: '이메일', value: email, isDark: isDark),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.calendar_today_rounded, label: '가입일', value: '2024년 3월 15일', isDark: isDark),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 설정 ───────────────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final WidgetRef ref;

  const _SettingsCard({required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: '설정', isDark: isDark),
          _ToggleRow(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            label: '다크 모드',
            isDark: isDark,
            value: isDark,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state =
                v ? ThemeMode.dark : ThemeMode.light,
          ),
          _Divider(isDark: isDark),
          _TapRow(
            icon: Icons.notifications_rounded,
            label: '알림 설정',
            isDark: isDark,
            onTap: () {},
          ),
          _Divider(isDark: isDark),
          _TapRow(
            icon: Icons.language_rounded,
            label: '언어',
            isDark: isDark,
            trailing: Text(
              '한국어',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ── 보안 ───────────────────────────────────────────────────────────────────────
class _SecurityCard extends StatelessWidget {
  final bool isDark;

  const _SecurityCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: '보안', isDark: isDark),
          _TapRow(
            icon: Icons.lock_rounded,
            label: '비밀번호 변경',
            isDark: isDark,
            onTap: () {},
          ),
          _Divider(isDark: isDark),
          _TapRow(
            icon: Icons.devices_rounded,
            label: '로그인 기기 관리',
            isDark: isDark,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ── 공통 행 위젯들 ─────────────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: accent,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _TapRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;

  const _TapRow({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ),
            trailing ??
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? AppColors.subtextDark : const Color(0xFFC8D6E5),
              ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 16,
      thickness: 0.5,
      color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withValues(alpha: 0.1),
    );
  }
}

// ── 로그아웃 버튼 ─────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final bool isDark;
  final WidgetRef ref;
  final BuildContext context;

  const _LogoutButton({required this.isDark, required this.ref, required this.context});

  @override
  Widget build(BuildContext _) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await ref.read(authNotifierProvider.notifier).logout();
        },
        icon: const Icon(Icons.logout_rounded, size: 17),
        label: const Text('로그아웃'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.unregistered,
          side: BorderSide(color: AppColors.unregistered.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
