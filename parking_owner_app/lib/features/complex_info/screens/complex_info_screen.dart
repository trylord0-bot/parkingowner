import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';

class ComplexInfoScreen extends ConsumerWidget {
  const ComplexInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          _Header(isDark: isDark),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeroCard(isDark: isDark),
                const SizedBox(height: 12),
                _StatsRow(isDark: isDark),
                const SizedBox(height: 12),
                _ContactCard(isDark: isDark),
                const SizedBox(height: 12),
                _InviteCodeCard(isDark: isDark),
                const SizedBox(height: 12),
                _ZonesCard(isDark: isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
              '단지 정보',
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

// ── 재사용 카드 컨테이너 ──────────────────────────────────────────────────────
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

// ── 단지 기본 정보 ─────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final bool isDark;
  const _HeroCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return _Card(
      isDark: isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.apartment_rounded, size: 30, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '행복마을아파트',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '아파트',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 12, color: isDark ? AppColors.subtextDark : AppColors.subtextLight),
                    const SizedBox(width: 3),
                    Text(
                      '서울특별시 강남구 테헤란로 123',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '준공 2015년 · 총 240세대',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 현황 통계 ──────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final bool isDark;
  const _StatsRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '240', label: '총 세대', isDark: isDark),
          _Vdivider(isDark: isDark),
          _StatItem(value: '200', label: '주차면수', isDark: isDark),
          _Vdivider(isDark: isDark),
          _StatItem(value: '187', label: '등록차량', isDark: isDark, color: AppColors.accent),
          _Vdivider(isDark: isDark),
          _StatItem(value: '142', label: '현재 입차', isDark: isDark, color: AppColors.registered),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  final Color? color;

  const _StatItem({required this.value, required this.label, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color ?? (isDark ? AppColors.textDark : AppColors.textLight),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
          ),
        ),
      ],
    );
  }
}

class _Vdivider extends StatelessWidget {
  final bool isDark;
  const _Vdivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withValues(alpha: 0.12),
    );
  }
}

// ── 관리소 연락처 ──────────────────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final bool isDark;
  const _ContactCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: '관리소 연락처', isDark: isDark),
          _InfoRow(
            icon: Icons.manage_accounts_rounded,
            label: '단지 관리자',
            value: '김민준',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.phone_rounded,
            label: '전화',
            value: '02-1234-5678',
            isDark: isDark,
            actionIcon: Icons.call_rounded,
            onAction: () {},
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.email_rounded,
            label: '이메일',
            value: 'contact@happy-apt.com',
            isDark: isDark,
            actionIcon: Icons.send_rounded,
            onAction: () {},
          ),
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
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.actionIcon,
    this.onAction,
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
          child: Column(
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
        ),
        if (actionIcon != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(actionIcon, size: 16, color: accent),
            ),
          ),
      ],
    );
  }
}

// ── 단지 초대 코드 ─────────────────────────────────────────────────────────────
class _InviteCodeCard extends StatelessWidget {
  final bool isDark;
  const _InviteCodeCard({required this.isDark});

  static const _code = 'HAPPY-7823';

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: '단지 초대 코드', isDark: isDark),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                Icon(Icons.vpn_key_rounded, size: 18, color: accent),
                const SizedBox(width: 10),
                Text(
                  _code,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: accent,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: _code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('초대 코드가 복사되었습니다'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text(
                      '복사',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '세대원이 앱 가입 시 이 코드를 입력하면 단지에 자동 연결됩니다.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 주차 구역 현황 ─────────────────────────────────────────────────────────────
class _ZonesCard extends StatelessWidget {
  final bool isDark;
  const _ZonesCard({required this.isDark});

  static const _zones = [
    ('지상 주차장', 80, 65, AppColors.registered),
    ('지하 1층 (B1)', 60, 42, AppColors.visitor),
    ('지하 2층 (B2)', 60, 35, AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: '주차 구역 현황', isDark: isDark),
          ..._zones.asMap().entries.map((e) {
            final z = e.value;
            final isLast = e.key == _zones.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: _ZoneRow(name: z.$1, total: z.$2, used: z.$3, color: z.$4, isDark: isDark),
            );
          }),
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final String name;
  final int total;
  final int used;
  final Color color;
  final bool isDark;

  const _ZoneRow({
    required this.name,
    required this.total,
    required this.used,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = used / total;
    final pct = (ratio * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ),
            Text(
              '$used / $total  ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}
