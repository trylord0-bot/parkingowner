import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/complex_onboarding_models.dart';
import '../providers/complex_onboarding_provider.dart';
import '../widgets/kakao_postcode_search_sheet.dart';

class ComplexOnboardingScreen extends ConsumerStatefulWidget {
  final bool isRequired;

  const ComplexOnboardingScreen({super.key, required this.isRequired});

  @override
  ConsumerState<ComplexOnboardingScreen> createState() =>
      _ComplexOnboardingScreenState();
}

class _ComplexOnboardingScreenState
    extends ConsumerState<ComplexOnboardingScreen> {
  bool _isChecking = false;

  Future<void> _openAddressSearch() async {
    final address = await showModalBottomSheet<AddressSearchResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const KakaoPostcodeSearchSheet(),
    );

    if (address == null || !mounted) return;
    await _checkAddress(address);
  }

  Future<void> _checkAddress(AddressSearchResult address) async {
    setState(() => _isChecking = true);
    try {
      final token = await _accessToken();
      final result = await ref
          .read(complexServiceProvider)
          .checkAddress(accessToken: token, roadAddress: address.roadAddress);
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _ComplexResultSheet(
          address: address,
          checkResult: result,
          onCompleted: () {
            context.go('/home');
          },
        ),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<String> _accessToken() async {
    final tokens = await ref.read(storageServiceProvider).loadTokens();
    final token = tokens.accessToken;
    if (token == null) throw const ApiException(401, '로그인이 필요합니다.');
    return token;
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final text = isDark ? AppColors.textDark : AppColors.textLight;
    final subtext = isDark ? AppColors.subtextDark : AppColors.subtextLight;
    final canGoBack = !widget.isRequired && Navigator.of(context).canPop();

    return PopScope(
      canPop: !widget.isRequired,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: canGoBack
              ? IconButton(
                  tooltip: '뒤로',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                )
              : null,
          title: Text(
            '단지 찾기',
            style: TextStyle(
              color: text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isRequired
                      ? '환영합니다!\n우리 단지 주소를 검색해주세요.'
                      : '단지 변경 및 추가',
                  style: TextStyle(
                    color: text,
                    fontSize: 22,
                    height: 1.32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '정확한 단지 구분을 위해 도로명 또는 지번 주소를 기준으로 검색합니다.',
                  style: TextStyle(
                    color: subtext,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kakao,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(
                      _isChecking ? '주소 확인 중' : '카카오 주소검색으로 찾기',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: _isChecking ? null : _openAddressSearch,
                  ),
                ),
                const Spacer(),
                Center(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 16,
                      color: subtext,
                    ),
                    label: Text(
                      '단지관리자 이용 가이드',
                      style: TextStyle(
                        color: subtext,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComplexResultSheet extends ConsumerStatefulWidget {
  final AddressSearchResult address;
  final ComplexCheckResult checkResult;
  final VoidCallback onCompleted;

  const _ComplexResultSheet({
    required this.address,
    required this.checkResult,
    required this.onCompleted,
  });

  @override
  ConsumerState<_ComplexResultSheet> createState() =>
      _ComplexResultSheetState();
}

class _ComplexResultSheetState extends ConsumerState<_ComplexResultSheet> {
  final _aliasController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final suggestedAlias = widget.address.buildingName?.trim();
    if (widget.checkResult.exists == false &&
        suggestedAlias?.isNotEmpty == true) {
      _aliasController.text = suggestedAlias!;
    }
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _createComplex() async {
    final alias = _aliasController.text.trim();
    if (alias.isEmpty) {
      _showMessage('단지 별칭을 입력해주세요.');
      return;
    }
    await _submit(() async {
      final token = await _accessToken();
      await ref
          .read(complexServiceProvider)
          .createComplex(
            accessToken: token,
            address: widget.address,
            alias: alias,
          );
    });
  }

  Future<void> _requestJoin() async {
    final complexId = widget.checkResult.complex?.id;
    if (complexId == null) return;
    await _submit(() async {
      final token = await _accessToken();
      await ref
          .read(complexServiceProvider)
          .requestJoin(accessToken: token, complexId: complexId);
    });
  }

  Future<void> _useInviteCode() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) {
      _showMessage('초대코드를 입력해주세요.');
      return;
    }
    await _submit(() async {
      final token = await _accessToken();
      await ref
          .read(complexServiceProvider)
          .useInviteCode(accessToken: token, code: code);
    });
  }

  Future<void> _submit(Future<void> Function() action) async {
    setState(() => _isSubmitting = true);
    try {
      await action();
      await ref.read(authNotifierProvider.notifier).reloadCurrentUser();
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCompleted();
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<String> _accessToken() async {
    final tokens = await ref.read(storageServiceProvider).loadTokens();
    final token = tokens.accessToken;
    if (token == null) throw const ApiException(401, '로그인이 필요합니다.');
    return token;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isRegistered = widget.checkResult.exists;
    final complex = widget.checkResult.complex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.textDark : AppColors.textLight;
    final subtext = isDark ? AppColors.subtextDark : AppColors.subtextLight;
    final sheetInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + sheetInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isRegistered ? '단지 가입' : '새 단지 등록',
                      style: TextStyle(
                        color: text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                isRegistered
                    ? '이미 파킹오너 시스템을 사용 중인 주소입니다.'
                    : '아직 파킹오너에 등록되지 않은 주소입니다.',
                style: TextStyle(color: subtext, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              _AddressBox(
                badge: isRegistered ? '파킹오너 등록됨' : '미등록 주소',
                badgeColor: isRegistered
                    ? AppColors.registered
                    : const Color(0xFF9CA3AF),
                roadAddress: widget.address.roadAddress,
                buildingName:
                    complex?.buildingName ?? widget.address.buildingName,
                alias: complex?.alias,
              ),
              const SizedBox(height: 16),
              if (isRegistered)
                _RegisteredActions(
                  inviteCodeController: _inviteCodeController,
                  isSubmitting: _isSubmitting,
                  onRequestJoin: _requestJoin,
                  onUseInviteCode: _useInviteCode,
                )
              else
                _CreateComplexForm(
                  aliasController: _aliasController,
                  isSubmitting: _isSubmitting,
                  onSubmit: _createComplex,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressBox extends StatelessWidget {
  final String badge;
  final Color badgeColor;
  final String roadAddress;
  final String? buildingName;
  final String? alias;

  const _AddressBox({
    required this.badge,
    required this.badgeColor,
    required this.roadAddress,
    this.buildingName,
    this.alias,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.textDark : AppColors.textLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border.all(
          color: isDark
              ? AppColors.primaryDark.withValues(alpha: 0.15)
              : const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBadge(label: badge, color: badgeColor),
          const SizedBox(height: 6),
          Text(
            roadAddress,
            style: TextStyle(
              color: text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (buildingName?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const _StatusBadge(label: '건물명', color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    buildingName!,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (alias?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const _StatusBadge(label: '별칭', color: AppColors.primaryDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alias!,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateComplexForm extends StatelessWidget {
  final TextEditingController aliasController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _CreateComplexForm({
    required this.aliasController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtext = isDark ? AppColors.subtextDark : AppColors.subtextLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '단지 별칭',
          style: TextStyle(
            color: subtext,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: aliasController,
          enabled: !isSubmitting,
          decoration: InputDecoration(
            hintText: '예) 행복아파트, 테헤란 오피스텔',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.visitor.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_rounded, color: AppColors.visitor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '입력한 별칭은 입주민이 단지를 식별하는 데 사용됩니다. 첫 등록자는 단지관리자 권한을 받습니다.',
                  style: TextStyle(
                    color: AppColors.visitor,
                    fontSize: 11,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.apartment_rounded),
            label: const Text('이 주소로 새 단지 등록하기'),
          ),
        ),
      ],
    );
  }
}

class _RegisteredActions extends StatelessWidget {
  final TextEditingController inviteCodeController;
  final bool isSubmitting;
  final VoidCallback onRequestJoin;
  final VoidCallback onUseInviteCode;

  const _RegisteredActions({
    required this.inviteCodeController,
    required this.isSubmitting,
    required this.onRequestJoin,
    required this.onUseInviteCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: isSubmitting ? null : onRequestJoin,
            icon: const Icon(Icons.groups_rounded),
            label: const Text('입주민으로 가입 요청하기'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: inviteCodeController,
          enabled: !isSubmitting,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.key_rounded),
            suffixIcon: IconButton(
              tooltip: '초대코드 적용',
              onPressed: isSubmitting ? null : onUseInviteCode,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            hintText: '관리자가 발급한 초대코드 입력',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: isSubmitting ? null : () {},
          child: const Text('제가 이 단지의 관리자입니다. 권한 이의신청'),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
