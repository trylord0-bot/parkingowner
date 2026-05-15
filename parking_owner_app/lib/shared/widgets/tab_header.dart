import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'main_scaffold.dart';

class TabHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget? bottom;

  const TabHeader({super.key, required this.title, required this.isDark, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, bottom != null ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.apartment_rounded, color: Colors.white60, size: 12),
                        const SizedBox(width: 4),
                        const Text('행복마을아파트', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const Text('단지 관리자', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
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

class _HamLine extends StatelessWidget {
  const _HamLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      width: 16,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1)),
    );
  }
}
