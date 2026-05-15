import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/app_state.dart';
import '../../../shared/widgets/tab_header.dart';

enum ScanState { idle, scanning, found, notFound }

final _scanStateProvider = StateProvider<ScanState>((ref) => ScanState.idle);
final _scannedPlateProvider = StateProvider<String?>((ref) => null);

class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scanState = ref.watch(_scanStateProvider);
    final plate = ref.watch(_scannedPlateProvider);
    final vehicles = ref.watch(mockVehiclesProvider);

    Vehicle? found;
    if (plate != null) {
      try {
        found = vehicles.firstWhere((v) => v.plateNumber == plate);
      } catch (_) {}
    }

    void doScan() async {
      ref.read(_scanStateProvider.notifier).state = ScanState.scanning;
      await Future.delayed(const Duration(seconds: 2));
      final demoPlates = ['123가4567', '654마9012', '789다1234', '000미0000'];
      final picked = demoPlates[DateTime.now().second % demoPlates.length];
      ref.read(_scannedPlateProvider.notifier).state = picked;
      final v = vehicles.where((v) => v.plateNumber == picked).toList();
      ref.read(_scanStateProvider.notifier).state =
          v.isNotEmpty ? ScanState.found : ScanState.notFound;
    }

    void doReset() {
      ref.read(_scanStateProvider.notifier).state = ScanState.idle;
      ref.read(_scannedPlateProvider.notifier).state = null;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          TabHeader(title: '스캔', isDark: isDark),
          _CameraSection(isDark: isDark, scanState: scanState),
          Expanded(
            child: _ScrollContent(
              isDark: isDark,
              scanState: scanState,
              plate: plate,
              vehicle: found,
              onScan: doScan,
              onReset: doReset,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 카메라 영역 (고정 높이) ─────────────────────────────────────────────────

class _CameraSection extends StatelessWidget {
  final bool isDark;
  final ScanState scanState;
  const _CameraSection({required this.isDark, required this.scanState});

  Color get _frameColor {
    switch (scanState) {
      case ScanState.idle:
      case ScanState.scanning:
        return const Color(0xFF9CA3AF);
      case ScanState.found:
        return AppColors.accentLight;
      case ScanState.notFound:
        return AppColors.unregistered;
    }
  }

  String get _hintText {
    switch (scanState) {
      case ScanState.idle:
        return '차량 번호판을 카메라에 인식시키세요';
      case ScanState.scanning:
        return 'OCR 분석 중...';
      case ScanState.found:
        return '정상 등록 차량';
      case ScanState.notFound:
        return '미등록 차량';
    }
  }

  @override
  Widget build(BuildContext context) {
    final frameColor = _frameColor;
    final screenW = MediaQuery.of(context).size.width;
    final frameW = screenW * 0.68;
    final frameH = frameW * 0.4;

    return Container(
      height: 220,
      color: const Color(0xFF0A1020),
      child: Stack(
        children: [
          // 배경 그라디언트
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [const Color(0xFF1a1a24), const Color(0xFF060606)],
                ),
              ),
            ),
          ),
          // 스캔 프레임 (중앙)
          Center(
            child: SizedBox(
              width: frameW,
              height: frameH,
              child: Stack(
                children: [
                  // 항상 표시되는 스캔 라인
                  Positioned.fill(
                    child: ClipRect(child: _ScanLine(color: frameColor)),
                  ),
                  // 코너 브래킷
                  _Corner(top: 0, left: 0, color: frameColor, tl: true),
                  _Corner(top: 0, right: 0, color: frameColor, tr: true),
                  _Corner(bottom: 0, left: 0, color: frameColor, bl: true),
                  _Corner(bottom: 0, right: 0, color: frameColor, br: true),
                ],
              ),
            ),
          ),
          // 힌트 텍스트
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: _HintBadge(
                text: _hintText,
                scanState: scanState,
              ),
            ),
          ),
          // 인식률 표시
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                scanState == ScanState.found
                    ? '인식률 98%'
                    : scanState == ScanState.notFound
                        ? '인식률 92%'
                        : scanState == ScanState.scanning
                            ? '인식 중...'
                            : '인식률 —',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xA0FFFFFF),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintBadge extends StatefulWidget {
  final String text;
  final ScanState scanState;
  const _HintBadge({required this.text, required this.scanState});

  @override
  State<_HintBadge> createState() => _HintBadgeState();
}

class _HintBadgeState extends State<_HintBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUnr = widget.scanState == ScanState.notFound;
    final bg = isUnr
        ? AppColors.unregistered.withOpacity(0.85)
        : Colors.black.withOpacity(0.55);

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (isUnr) {
      return ScaleTransition(scale: _scale, child: badge);
    }
    return badge;
  }
}

// ─── 스캔 라인 (항상 애니메이션) ──────────────────────────────────────────────

class _ScanLine extends StatefulWidget {
  final Color color;
  const _ScanLine({required this.color});

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pos;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _pos = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Align(
        alignment: Alignment(0, _pos.value * 2 - 1),
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 코너 브래킷 ──────────────────────────────────────────────────────────────

class _Corner extends StatelessWidget {
  final double? top, bottom, left, right;
  final Color color;
  final bool tl, tr, bl, br;
  const _Corner({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.color,
    this.tl = false,
    this.tr = false,
    this.bl = false,
    this.br = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: CustomPaint(
        size: const Size(22, 22),
        painter: _CornerPainter(color: color, tl: tl, tr: tr, bl: bl, br: br),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool tl, tr, bl, br;
  const _CornerPainter({
    required this.color,
    this.tl = false,
    this.tr = false,
    this.bl = false,
    this.br = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (tl) {
      canvas.drawLine(Offset(0, size.height), Offset.zero, p);
      canvas.drawLine(Offset.zero, Offset(size.width, 0), p);
    }
    if (tr) {
      canvas.drawLine(Offset(0, 0), Offset(size.width, 0), p);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), p);
    }
    if (bl) {
      canvas.drawLine(Offset.zero, Offset(0, size.height), p);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), p);
    }
    if (br) {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), p);
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => old.color != color;
}

// ─── 스크롤 콘텐츠 영역 ───────────────────────────────────────────────────────

class _ScrollContent extends StatelessWidget {
  final bool isDark;
  final ScanState scanState;
  final String? plate;
  final Vehicle? vehicle;
  final VoidCallback onScan;
  final VoidCallback onReset;

  const _ScrollContent({
    required this.isDark,
    required this.scanState,
    required this.plate,
    required this.vehicle,
    required this.onScan,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    return Container(
      color: bg,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OcrDisplay(isDark: isDark, scanState: scanState, plate: plate),
            const SizedBox(height: 14),
            _ActionButtons(
              isDark: isDark,
              scanState: scanState,
              onScan: onScan,
              onReset: onReset,
            ),
            const SizedBox(height: 14),
            _InfoCard(
              isDark: isDark,
              scanState: scanState,
              vehicle: vehicle,
            ),
            if (scanState == ScanState.found || scanState == ScanState.notFound) ...[
              const SizedBox(height: 16),
              _HistorySection(isDark: isDark, scanState: scanState),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── OCR 번호판 표시 ──────────────────────────────────────────────────────────

class _OcrDisplay extends StatelessWidget {
  final bool isDark;
  final ScanState scanState;
  final String? plate;

  const _OcrDisplay({
    required this.isDark,
    required this.scanState,
    required this.plate,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (plate != null && plate!.isNotEmpty)
            Text(
              plate!,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: scanState == ScanState.notFound
                    ? AppColors.unregistered
                    : textColor,
              ),
            )
          else if (scanState == ScanState.scanning)
            Text(
              'OCR 분석 중...',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
              ),
            )
          else
            Text(
              '인식 대기 중...',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
              ),
            ),
          // 편집 버튼 (번호판 인식 후)
          if (plate != null && plate!.isNotEmpty)
            Positioned(
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.accentLight.withOpacity(0.1)
                      : AppColors.primaryLight.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── 액션 버튼 ────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool isDark;
  final ScanState scanState;
  final VoidCallback onScan;
  final VoidCallback onReset;

  const _ActionButtons({
    required this.isDark,
    required this.scanState,
    required this.onScan,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    switch (scanState) {
      case ScanState.idle:
        return _outlineBtn(
          context,
          label: '스캔 대기 중',
          isDark: isDark,
          onPressed: onScan, // 데모용 탭 가능
        );

      case ScanState.scanning:
        return _outlineBtn(
          context,
          label: 'OCR 분석 중...',
          isDark: isDark,
          onPressed: null,
        );

      case ScanState.found:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('입주민 차량'),
            onPressed: null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        );

      case ScanState.notFound:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.textDark : AppColors.textLight,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.subtextDark.withOpacity(0.5)
                        : AppColors.subtextLight.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle:
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                child: const Text('방문 등록'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showUnauthorizedSheet(context, isDark),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.unregistered,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle:
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                child: const Text('무단주차 처리'),
              ),
            ),
          ],
        );
    }
  }

  Widget _outlineBtn(
    BuildContext context, {
    required String label,
    required bool isDark,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.subtextDark : AppColors.subtextLight,
          side: BorderSide(
            color: isDark
                ? AppColors.subtextDark.withOpacity(0.4)
                : AppColors.subtextLight.withOpacity(0.4),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }

  void _showUnauthorizedSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnauthorizedSheet(isDark: isDark),
    );
  }
}

// ─── 정보 카드 ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final ScanState scanState;
  final Vehicle? vehicle;

  const _InfoCard({
    required this.isDark,
    required this.scanState,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final subColor = isDark ? AppColors.subtextDark : AppColors.subtextLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primaryLight.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: switch (scanState) {
        ScanState.idle => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Badge(label: '대기 중', color: const Color(0xFF9CA3AF)),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '차량을 스캔하면 정보가 표시됩니다.',
                  style: TextStyle(fontSize: 12, color: subColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ScanState.scanning => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Badge(label: '인식 중', color: AppColors.accentLight),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '번호판 데이터를 분석하고 있습니다...',
                  style: TextStyle(fontSize: 12, color: subColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ScanState.found => _RegisteredCardContent(
            isDark: isDark,
            vehicle: vehicle,
          ),
        ScanState.notFound => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Badge(label: '미등록 차량', color: AppColors.unregistered),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '단지에 등록된 정보가 없는 차량입니다.',
                  style: TextStyle(fontSize: 12, color: subColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
      },
    );
  }
}

class _RegisteredCardContent extends StatelessWidget {
  final bool isDark;
  final Vehicle? vehicle;
  const _RegisteredCardContent({required this.isDark, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subColor = isDark ? AppColors.subtextDark : AppColors.subtextLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Badge(label: '등록 차량', color: AppColors.registered),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF22C55E).withOpacity(0.3)),
              ),
              child: const Icon(Icons.phone_rounded,
                  size: 14, color: Color(0xFF22C55E)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 2열 그리드
        Row(
          children: [
            Expanded(
              child: _InfoItem(
                label: '동·호수',
                value: vehicle?.unit ?? '—',
                textColor: textColor,
                subColor: subColor,
              ),
            ),
            Expanded(
              child: _InfoItem(
                label: '등록일',
                value: '2025.01.15',
                textColor: textColor,
                subColor: subColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _InfoItem(
                label: '차종',
                value: '—',
                textColor: textColor,
                subColor: subColor,
              ),
            ),
            Expanded(
              child: _InfoItem(
                label: '차주',
                value: vehicle?.ownerName ?? '—',
                textColor: textColor,
                subColor: subColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color subColor;
  const _InfoItem({
    required this.label,
    required this.value,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: subColor)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color.withOpacity(0.9)),
      ),
    );
  }
}

// ─── 과거 이력 섹션 ───────────────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  final bool isDark;
  final ScanState scanState;
  const _HistorySection({required this.isDark, required this.scanState});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subColor = isDark ? AppColors.subtextDark : AppColors.subtextLight;
    final lineColor = isDark
        ? AppColors.accentLight.withOpacity(0.15)
        : AppColors.primaryLight.withOpacity(0.12);

    final List<_HistItem> items = scanState == ScanState.found
        ? [
            _HistItem(
                dot: AppColors.accentLight, title: '입차', time: '2026.05.13 · 오전 8:24'),
            _HistItem(
                dot: AppColors.subtextLight, title: '출차', time: '2026.05.12 · 오후 7:51'),
            _HistItem(
                dot: AppColors.accentLight, title: '입차', time: '2026.05.12 · 오전 9:03'),
          ]
        : [
            _HistItem(
                dot: AppColors.unregistered,
                title: '무단주차 경고장 부착',
                time: '2026.04.20 · B2 구역',
                titleColor: AppColors.unregistered),
            _HistItem(
                dot: AppColors.unregistered,
                title: '미등록 감지',
                time: '2026.04.15 · 오후 2:10',
                titleColor: AppColors.unregistered),
            _HistItem(
                dot: AppColors.visitor,
                title: '방문 차량 입차 (만료)',
                time: '2026.03.30 · 101동 302호',
                titleColor: AppColors.visitor),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('과거 이력',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: textColor)),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('더보기',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < items.length; i++)
          _HistoryItem(
            item: items[i],
            isLast: i == items.length - 1,
            textColor: textColor,
            subColor: subColor,
            lineColor: lineColor,
          ),
      ],
    );
  }
}

class _HistItem {
  final Color dot;
  final String title;
  final String time;
  final Color? titleColor;
  const _HistItem({
    required this.dot,
    required this.title,
    required this.time,
    this.titleColor,
  });
}

class _HistoryItem extends StatelessWidget {
  final _HistItem item;
  final bool isLast;
  final Color textColor;
  final Color subColor;
  final Color lineColor;

  const _HistoryItem({
    required this.item,
    required this.isLast,
    required this.textColor,
    required this.subColor,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: item.dot,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 30,
                    color: lineColor,
                    margin: const EdgeInsets.only(top: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: item.titleColor ?? textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(item.time,
                  style: TextStyle(fontSize: 10, color: subColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 무단주차 처리 바텀 시트 ──────────────────────────────────────────────────

class _UnauthorizedSheet extends StatefulWidget {
  final bool isDark;
  const _UnauthorizedSheet({required this.isDark});

  @override
  State<_UnauthorizedSheet> createState() => _UnauthorizedSheetState();
}

class _UnauthorizedSheetState extends State<_UnauthorizedSheet> {
  final Set<int> _selected = {0, 1};

  final List<String> _options = [
    '조치 기록 (필수)',
    '경고 스티커 발부',
    '전화로 이동주차 통보',
    '방송으로 이동주차 통보',
    '반복 위반 강력 경고',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subColor = isDark ? AppColors.subtextDark : AppColors.subtextLight;
    final borderColor = isDark
        ? AppColors.accentLight.withOpacity(0.15)
        : AppColors.primaryLight.withOpacity(0.1);
    final optBg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark
            ? Border(
                top: BorderSide(
                    color: AppColors.accentLight.withOpacity(0.15)))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 스크롤 바디
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '무단주차 조치 기록',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '처리하신 방법을 선택해 주세요. (다중 선택 가능)',
                    style: TextStyle(fontSize: 12, color: subColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  // 옵션 목록
                  ...List.generate(_options.length, (i) {
                    final isLocked = i == 0;
                    final isSel = _selected.contains(i);
                    return GestureDetector(
                      onTap: isLocked
                          ? null
                          : () => setState(() => isSel
                              ? _selected.remove(i)
                              : _selected.add(i)),
                      child: Opacity(
                        opacity: isLocked ? 0.6 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 11),
                          decoration: BoxDecoration(
                            color: isSel
                                ? (isDark
                                    ? AppColors.accentLight.withOpacity(0.1)
                                    : AppColors.primaryLight.withOpacity(0.05))
                                : optBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel
                                  ? (isDark
                                      ? AppColors.accentLight
                                      : AppColors.primaryLight)
                                  : borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? (isDark
                                          ? AppColors.accentLight
                                          : AppColors.primaryLight)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isSel
                                        ? (isDark
                                            ? AppColors.accentLight
                                            : AppColors.primaryLight)
                                        : const Color(0xFF9CA3AF),
                                    width: 2,
                                  ),
                                ),
                                child: isSel
                                    ? const Icon(Icons.check,
                                        size: 12, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _options[i],
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  // 추가사항 입력
                  Text(
                    '추가사항 (선택)',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: subColor),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    maxLines: 3,
                    style: TextStyle(fontSize: 12, color: textColor),
                    decoration: InputDecoration(
                      hintText: '현장 상황이나 특이사항을 입력하세요...',
                      hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF3A5068)
                              : const Color(0xFFC0CCD8),
                          fontSize: 12),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.accentLight.withOpacity(0.2)
                              : AppColors.primaryLight.withOpacity(0.15),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.accentLight.withOpacity(0.2)
                              : AppColors.primaryLight.withOpacity(0.15),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 자동 촬영 사진
                  Text(
                    '자동 촬영 사진',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: subColor),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.accentLight.withOpacity(0.2)),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1c2a3a), Color(0xFF0e1a28)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 차량 실루엣
                        Center(
                          child: Icon(
                            Icons.directions_car_rounded,
                            size: 64,
                            color: const Color(0xFF7890A8).withOpacity(0.35),
                          ),
                        ),
                        // 번호판
                        Positioned(
                          bottom: 14,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '55다 1234',
                                style: TextStyle(
                                  color: Color(0xFF162035),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // AUTO 뱃지
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.unregistered.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AUTO',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3),
                            ),
                          ),
                        ),
                        // 촬영 시각
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '2026.05.15 · 09:12',
                              style: TextStyle(
                                  color: Color(0xFFD8E8F5),
                                  fontSize: 9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // 하단 버튼
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.of(context).padding.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.accentLight.withOpacity(0.1)
                          : AppColors.primaryLight.withOpacity(0.08),
                      foregroundColor: subColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.accentLight
                          : AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('처리완료'),
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
