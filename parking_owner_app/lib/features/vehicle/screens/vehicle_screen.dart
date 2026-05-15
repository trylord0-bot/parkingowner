import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/app_state.dart';
import '../../../shared/widgets/tab_header.dart';

enum VehicleFilter { all, registered, visitor, unregistered }

final _filterProvider = StateProvider<VehicleFilter>((ref) => VehicleFilter.all);
final _searchProvider = StateProvider<String>((ref) => '');

class VehicleScreen extends ConsumerWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = ref.watch(_filterProvider);
    final search = ref.watch(_searchProvider);
    final all = ref.watch(mockVehiclesProvider);

    final filtered = all.where((v) {
      final matchFilter = filter == VehicleFilter.all ||
          (filter == VehicleFilter.registered && v.type == VehicleType.registered) ||
          (filter == VehicleFilter.visitor && v.type == VehicleType.visitor) ||
          (filter == VehicleFilter.unregistered && v.type == VehicleType.unregistered);
      final matchSearch = search.isEmpty || v.plateNumber.contains(search) || v.ownerName.contains(search);
      return matchFilter && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          _VehicleHeader(isDark: isDark, ref: ref),
          _FilterChips(filter: filter, isDark: isDark, onChanged: (f) => ref.read(_filterProvider.notifier).state = f),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('차량이 없습니다', style: TextStyle(color: isDark ? AppColors.subtextDark : AppColors.subtextLight)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _VehicleCard(vehicle: filtered[i], isDark: isDark),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicle(context, isDark),
        icon: const Icon(Icons.add_rounded),
        label: const Text('차량 등록'),
        backgroundColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddVehicle(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddVehicleSheet(isDark: isDark),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  final bool isDark;
  final WidgetRef ref;
  const _VehicleHeader({required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    return TabHeader(
      title: '차량관리',
      isDark: isDark,
      bottom: Column(
        children: [
          TextField(
            onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: '번호판 또는 차주 검색',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final VehicleFilter filter;
  final bool isDark;
  final ValueChanged<VehicleFilter> onChanged;

  const _FilterChips({required this.filter, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      (VehicleFilter.all, '전체', null),
      (VehicleFilter.registered, '등록', AppColors.registered),
      (VehicleFilter.visitor, '방문', AppColors.visitor),
      (VehicleFilter.unregistered, '미등록', AppColors.unregistered),
    ];

    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        children: items.map((item) {
          final isSelected = filter == item.$1;
          final color = item.$3 ?? (isDark ? AppColors.primaryDark : Colors.white);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(item.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.9) : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? color : Colors.white.withOpacity(0.25)),
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? (item.$3 == null ? AppColors.primaryLight : Colors.white) : Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool isDark;

  const _VehicleCard({required this.vehicle, required this.isDark});

  Color get _typeColor {
    switch (vehicle.type) {
      case VehicleType.registered: return AppColors.registered;
      case VehicleType.visitor: return AppColors.visitor;
      case VehicleType.unregistered: return AppColors.unregistered;
    }
  }

  String get _typeLabel {
    switch (vehicle.type) {
      case VehicleType.registered: return '등록';
      case VehicleType.visitor: return '방문';
      case VehicleType.unregistered: return '미등록';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subColor = isDark ? AppColors.subtextDark : AppColors.subtextLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: isDark ? null : [BoxShadow(color: AppColors.primaryLight.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.directions_car_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(vehicle.plateNumber, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor, letterSpacing: 1)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(6)),
                      child: Text(_typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${vehicle.ownerName} · ${vehicle.unit}', style: TextStyle(fontSize: 12, color: subColor)),
                if (vehicle.expiresAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    vehicle.expiresAt!.isBefore(DateTime.now()) ? '만료됨' : '${vehicle.expiresAt!.difference(DateTime.now()).inHours}시간 후 만료',
                    style: TextStyle(fontSize: 10, color: vehicle.expiresAt!.isBefore(DateTime.now()) ? AppColors.unregistered : AppColors.visitor, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.call_rounded, size: 18),
                color: isDark ? AppColors.primaryDark : AppColors.secondaryLight,
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 18),
                color: subColor,
                onPressed: () => _showOptions(context, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit_rounded), title: const Text('차량 정보 수정'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.history_rounded), title: const Text('입출차 이력'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.sms_rounded), title: const Text('SMS 발송'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.delete_rounded, color: AppColors.unregistered), title: const Text('차량 삭제', style: TextStyle(color: AppColors.unregistered)), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class _AddVehicleSheet extends StatelessWidget {
  final bool isDark;
  const _AddVehicleSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('차량 등록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(hintText: '번호판 (예: 123가4567)', labelText: '번호판')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(hintText: '차주 이름', labelText: '차주')),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(hintText: '동/호수 (예: 101동 302호)', labelText: '세대')),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('등록')),
        ],
      ),
    );
  }
}
