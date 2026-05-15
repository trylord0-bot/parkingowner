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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          TabHeader(title: '스캔', isDark: isDark),
          Expanded(
            child: Stack(
              children: [
                _CameraPreview(isDark: isDark, scanState: scanState),
                _ScanOverlay(scanState: scanState),
              ],
            ),
          ),
          _ScanBottomPanel(
            scanState: scanState,
            vehicle: found,
            plate: plate,
            isDark: isDark,
            onScan: () async {
              ref.read(_scanStateProvider.notifier).state = ScanState.scanning;
              await Future.delayed(const Duration(seconds: 2));
              final demoPlates = ['123가4567', '654마9012', '789다1234', '000미0000'];
              final picked = demoPlates[DateTime.now().second % demoPlates.length];
              ref.read(_scannedPlateProvider.notifier).state = picked;
              final v = vehicles.where((v) => v.plateNumber == picked).toList();
              ref.read(_scanStateProvider.notifier).state = v.isNotEmpty ? ScanState.found : ScanState.notFound;
            },
            onReset: () {
              ref.read(_scanStateProvider.notifier).state = ScanState.idle;
              ref.read(_scannedPlateProvider.notifier).state = null;
            },
          ),
        ],
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  final bool isDark;
  final ScanState scanState;
  const _CameraPreview({required this.isDark, required this.scanState});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1020),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_rounded, size: 48, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 12),
            Text(
              scanState == ScanState.scanning ? 'OCR 분석 중...' : '카메라 미리보기',
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  final ScanState scanState;
  const _ScanOverlay({required this.scanState});

  Color get _frameColor {
    switch (scanState) {
      case ScanState.idle: return Colors.white;
      case ScanState.scanning: return AppColors.accentLight;
      case ScanState.found: return AppColors.registered;
      case ScanState.notFound: return AppColors.unregistered;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameW = size.width * 0.82;
    final frameH = frameW * 0.28;
    final top = size.height * 0.32;
    final color = _frameColor;

    return Positioned(
      top: top,
      left: (size.width - frameW) / 2,
      child: Stack(
        children: [
          Container(
            width: frameW, height: frameH,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (scanState == ScanState.scanning)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _ScanLine(color: color),
              ),
            ),
          _Corner(top: 0, left: 0, color: color, tl: true),
          _Corner(top: 0, right: 0, color: color, tr: true),
          _Corner(bottom: 0, left: 0, color: color, bl: true),
          _Corner(bottom: 0, right: 0, color: color, br: true),
        ],
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  final Color color;
  const _ScanLine({required this.color});
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Align(
        alignment: Alignment(0, _anim.value * 2 - 1),
        child: Container(height: 2, color: widget.color.withOpacity(0.7)),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final double? top, bottom, left, right;
  final Color color;
  final bool tl, tr, bl, br;
  const _Corner({this.top, this.bottom, this.left, this.right, required this.color, this.tl = false, this.tr = false, this.bl = false, this.br = false});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: CustomPaint(
        size: const Size(20, 20),
        painter: _CornerPainter(color: color, tl: tl, tr: tr, bl: bl, br: br),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool tl, tr, bl, br;
  const _CornerPainter({required this.color, this.tl = false, this.tr = false, this.bl = false, this.br = false});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    if (tl) { canvas.drawLine(Offset(0, size.height), const Offset(0, 0), p); canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), p); }
    if (tr) { canvas.drawLine(Offset(0, 0), Offset(size.width, 0), p); canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), p); }
    if (bl) { canvas.drawLine(const Offset(0, 0), Offset(0, size.height), p); canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), p); }
    if (br) { canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), p); canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), p); }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ScanBottomPanel extends StatelessWidget {
  final ScanState scanState;
  final Vehicle? vehicle;
  final String? plate;
  final bool isDark;
  final VoidCallback onScan;
  final VoidCallback onReset;

  const _ScanBottomPanel({
    required this.scanState,
    required this.vehicle,
    required this.plate,
    required this.isDark,
    required this.onScan,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -8))],
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.subtextDark.withOpacity(0.3) : AppColors.subtextLight.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          if (scanState == ScanState.idle) _IdlePanel(onScan: onScan, isDark: isDark),
          if (scanState == ScanState.scanning) _ScanningPanel(isDark: isDark),
          if (scanState == ScanState.found && vehicle != null) _VehicleInfoPanel(vehicle: vehicle!, isDark: isDark, onReset: onReset),
          if (scanState == ScanState.notFound) _NotFoundPanel(plate: plate ?? '', isDark: isDark, onReset: onReset),
        ],
      ),
    );
  }
}

class _IdlePanel extends StatelessWidget {
  final VoidCallback onScan;
  final bool isDark;
  const _IdlePanel({required this.onScan, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subColor = isDark ? AppColors.subtextDark : AppColors.subtextLight;
    return Column(
      children: [
        Text('번호판을 프레임 안에 위치시키세요', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 4),
        Text('자동으로 인식되거나 버튼을 눌러 수동 스캔', style: TextStyle(fontSize: 12, color: subColor)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('번호판 스캔'),
                onPressed: onScan,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.keyboard_rounded, size: 18),
              label: const Text('직접 입력'),
              onPressed: () => _showManualInput(context, isDark),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                side: BorderSide(color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showManualInput(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('번호판 직접 입력', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.textLight)),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: '예: 123가4567',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: const TextStyle(fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () { Navigator.pop(context); onScan(); }, child: const Text('검색')),
          ],
        ),
      ),
    );
  }
}

class _ScanningPanel extends StatelessWidget {
  final bool isDark;
  const _ScanningPanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text('번호판 인식 중...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.textDark : AppColors.textLight)),
        const SizedBox(height: 4),
        Text('OCR 분석을 수행하고 있습니다', style: TextStyle(fontSize: 12, color: isDark ? AppColors.subtextDark : AppColors.subtextLight)),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _VehicleInfoPanel extends StatelessWidget {
  final Vehicle vehicle;
  final bool isDark;
  final VoidCallback onReset;

  const _VehicleInfoPanel({required this.vehicle, required this.isDark, required this.onReset});

  Color get _typeColor {
    switch (vehicle.type) {
      case VehicleType.registered: return AppColors.registered;
      case VehicleType.visitor: return AppColors.visitor;
      case VehicleType.unregistered: return AppColors.unregistered;
    }
  }

  String get _typeLabel {
    switch (vehicle.type) {
      case VehicleType.registered: return '등록 차량';
      case VehicleType.visitor: return '방문 차량';
      case VehicleType.unregistered: return '미등록 차량';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.plateNumber,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textColor, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(8)),
                    child: Text(_typeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                  ),
                ],
              ),
            ),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.directions_car_rounded, color: color, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoRow(label: '차주', value: vehicle.ownerName, isDark: isDark),
        _InfoRow(label: '세대', value: vehicle.unit, isDark: isDark),
        if (vehicle.expiresAt != null)
          _InfoRow(
            label: '만료',
            value: vehicle.expiresAt!.isBefore(DateTime.now()) ? '만료됨' : '${vehicle.expiresAt!.difference(DateTime.now()).inHours}시간 남음',
            isDark: isDark,
            valueColor: vehicle.expiresAt!.isBefore(DateTime.now()) ? AppColors.unregistered : null,
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login_rounded, size: 16),
                label: const Text('입차 처리'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.registered,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('출차 처리'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentLight,
                  side: BorderSide(color: AppColors.accentLight.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onReset, child: const Text('다시 스캔')),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, required this.isDark, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.subtextDark : AppColors.subtextLight))),
          const SizedBox(width: 12),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? (isDark ? AppColors.textDark : AppColors.textLight))),
        ],
      ),
    );
  }
}

class _NotFoundPanel extends StatelessWidget {
  final String plate;
  final bool isDark;
  final VoidCallback onReset;

  const _NotFoundPanel({required this.plate, required this.isDark, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: AppColors.unregistered.withOpacity(0.13), shape: BoxShape.circle),
          child: const Icon(Icons.warning_amber_rounded, color: AppColors.unregistered, size: 28),
        ),
        const SizedBox(height: 12),
        Text(plate, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor, letterSpacing: 2)),
        const SizedBox(height: 4),
        const Text('미등록 차량', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.unregistered)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('방문 등록'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.visitor,
                  foregroundColor: const Color(0xFF191919),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.warning_amber_rounded, size: 16),
                label: const Text('불법 주차 기록'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.unregistered,
                  side: BorderSide(color: AppColors.unregistered.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onReset, child: const Text('다시 스캔')),
      ],
    );
  }
}
