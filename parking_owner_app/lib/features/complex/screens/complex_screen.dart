import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tab_header.dart';

enum ComplexTab { residents, zones }

final _complexTabProvider = StateProvider<ComplexTab>((ref) => ComplexTab.residents);

class ComplexScreen extends ConsumerWidget {
  const ComplexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tab = ref.watch(_complexTabProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          _ComplexHeader(isDark: isDark, tab: tab, onTabChanged: (t) => ref.read(_complexTabProvider.notifier).state = t),
          Expanded(
            child: tab == ComplexTab.residents ? _ResidentsList(isDark: isDark) : _ZonesList(isDark: isDark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: Icon(tab == ComplexTab.residents ? Icons.person_add_rounded : Icons.add_location_rounded),
        label: Text(tab == ComplexTab.residents ? '입주민 초대' : '구역 추가'),
        backgroundColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ComplexHeader extends StatelessWidget {
  final bool isDark;
  final ComplexTab tab;
  final ValueChanged<ComplexTab> onTabChanged;

  const _ComplexHeader({required this.isDark, required this.tab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return TabHeader(
      title: '단지관리',
      isDark: isDark,
      bottom: Row(
        children: [
          _TabBtn(label: '입주민', isSelected: tab == ComplexTab.residents, onTap: () => onTabChanged(ComplexTab.residents), badge: '2'),
          const SizedBox(width: 8),
          _TabBtn(label: '주차 구역', isSelected: tab == ComplexTab.zones, onTap: () => onTabChanged(ComplexTab.zones)),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  const _TabBtn({required this.label, required this.isSelected, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSelected ? Colors.white : Colors.transparent, width: 2)),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.unregistered, borderRadius: BorderRadius.circular(10)),
                child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResidentsList extends StatelessWidget {
  final bool isDark;
  const _ResidentsList({required this.isDark});

  static const _residents = [
    ('김민준', '101동 302호', '단지 관리자', true),
    ('이서연', '102동 504호', '입주민', false),
    ('박지훈', '104동 105호', '입주민', false),
    ('최예린', '103동 201호', '주차 관리원', false),
  ];

  static const _pending = [
    ('홍길동', '101동 401호'),
    ('강미래', '203동 302호'),
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subColor = isDark ? AppColors.subtextDark : AppColors.subtextLight;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _SectionTitle(title: '승인 대기 (${_pending.length})', isDark: isDark),
        const SizedBox(height: 8),
        ..._pending.map((r) => _PendingCard(name: r.$1, unit: r.$2, isDark: isDark)),
        const SizedBox(height: 16),
        _SectionTitle(title: '입주민 목록 (${_residents.length})', isDark: isDark),
        const SizedBox(height: 8),
        ..._residents.map((r) => _ResidentCard(name: r.$1, unit: r.$2, role: r.$3, isManager: r.$4, isDark: isDark)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight));
  }
}

class _PendingCard extends StatelessWidget {
  final String name;
  final String unit;
  final bool isDark;
  const _PendingCard({required this.name, required this.unit, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.visitor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.visitor.withOpacity(0.13), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person_rounded, color: AppColors.visitor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
                Text(unit, style: TextStyle(fontSize: 12, color: isDark ? AppColors.subtextDark : AppColors.subtextLight)),
              ],
            ),
          ),
          TextButton(onPressed: () {}, style: TextButton.styleFrom(foregroundColor: AppColors.registered, padding: const EdgeInsets.symmetric(horizontal: 12)), child: const Text('승인', style: TextStyle(fontWeight: FontWeight.w700))),
          TextButton(onPressed: () {}, style: TextButton.styleFrom(foregroundColor: AppColors.unregistered, padding: const EdgeInsets.symmetric(horizontal: 12)), child: const Text('거부', style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _ResidentCard extends StatelessWidget {
  final String name;
  final String unit;
  final String role;
  final bool isManager;
  final bool isDark;

  const _ResidentCard({required this.name, required this.unit, required this.role, required this.isManager, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark ? null : [BoxShadow(color: AppColors.primaryLight.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withOpacity(0.13),
            child: Text(name[0], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.primaryDark : AppColors.primaryLight)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isManager ? AppColors.accentLight : AppColors.registered).withOpacity(0.13),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(role, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isManager ? AppColors.accentLight : AppColors.registered)),
                    ),
                  ],
                ),
                Text(unit, style: TextStyle(fontSize: 12, color: isDark ? AppColors.subtextDark : AppColors.subtextLight)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.more_vert_rounded, size: 18), color: isDark ? AppColors.subtextDark : AppColors.subtextLight, onPressed: () {}),
        ],
      ),
    );
  }
}

class _ZonesList extends StatelessWidget {
  final bool isDark;
  const _ZonesList({required this.isDark});

  static const _zones = [
    ('지상 주차장', 80, 65, '지상 1층'),
    ('지하 1층', 60, 42, 'B1'),
    ('지하 2층', 60, 35, 'B2'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark ? null : [BoxShadow(color: AppColors.primaryLight.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ZoneStat(label: '총 구역', value: '${_zones.length}', isDark: isDark),
              _Divider(isDark: isDark),
              _ZoneStat(label: '총 면수', value: '${_zones.fold(0, (a, z) => a + z.$2)}', isDark: isDark),
              _Divider(isDark: isDark),
              _ZoneStat(label: '사용중', value: '${_zones.fold(0, (a, z) => a + z.$3)}', isDark: isDark, color: AppColors.accentLight),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ..._zones.map((z) => _ZoneCard(name: z.$1, total: z.$2, used: z.$3, floor: z.$4, isDark: isDark)),
      ],
    );
  }
}

class _ZoneStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? color;
  const _ZoneStat({required this.label, required this.value, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color ?? (isDark ? AppColors.textDark : AppColors.textLight))),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.subtextDark : AppColors.subtextLight)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(height: 32, width: 1, color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withOpacity(0.1));
  }
}

class _ZoneCard extends StatelessWidget {
  final String name;
  final int total;
  final int used;
  final String floor;
  final bool isDark;

  const _ZoneCard({required this.name, required this.total, required this.used, required this.floor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ratio = used / total;
    final color = ratio > 0.85 ? AppColors.unregistered : ratio > 0.7 ? AppColors.visitor : AppColors.registered;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: isDark ? null : [BoxShadow(color: AppColors.primaryLight.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(floor, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? AppColors.primaryDark : AppColors.primaryLight)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight))),
              Text('$used / $total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('사용률 ${(ratio * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              Text('여유 ${total - used}면', style: TextStyle(fontSize: 10, color: isDark ? AppColors.subtextDark : AppColors.subtextLight)),
            ],
          ),
        ],
      ),
    );
  }
}
