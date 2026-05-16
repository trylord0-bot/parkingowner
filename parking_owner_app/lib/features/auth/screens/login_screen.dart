import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@parkingowner.com');
  final _pwCtrl = TextEditingController(text: 'Admin1234!');
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _pwCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('이메일과 비밀번호를 입력해주세요.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).login(email, password);
      // 성공 시 라우터 redirect가 /home으로 자동 이동
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('[예상치 못한 오류] $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.unregistered,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              onPressed: () => _showDevPanel(context, isDark),
              backgroundColor: Colors.red.shade700,
              tooltip: 'Dev Tools',
              child: const Icon(Icons.bug_report_rounded, size: 18),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B3D6F), Color(0xFF2D6098), Color(0xFF4A90C8)],
                  stops: [0.0, 0.55, 1.0],
                ),
          color: isDark ? AppColors.backgroundDark : null,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 48),
                _Logo(isDark: isDark),
                const SizedBox(height: 32),
                _LoginForm(
                  isDark: isDark,
                  emailCtrl: _emailCtrl,
                  pwCtrl: _pwCtrl,
                  obscure: _obscure,
                  loading: _loading,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  onLogin: _login,
                  onForgotPw: () => _showForgotPassword(context, isDark),
                  onSignup: () => context.push('/signup'),
                ),
                const SizedBox(height: 20),
                _SocialLogin(isDark: isDark, onLogin: _login),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPassword(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ForgotPasswordSheet(isDark: isDark),
    );
  }

  void _showDevPanel(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DevPanel(isDark: isDark),
    );
  }
}

class _Logo extends StatelessWidget {
  final bool isDark;
  const _Logo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('🅿', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        Text(
          'ParkingOwner',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDark : Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '스마트 주차 관리 솔루션',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.subtextDark : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  final bool isDark;
  final TextEditingController emailCtrl;
  final TextEditingController pwCtrl;
  final bool obscure;
  final bool loading;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onForgotPw;
  final VoidCallback onSignup;

  const _LoginForm({
    required this.isDark,
    required this.emailCtrl,
    required this.pwCtrl,
    required this.obscure,
    required this.loading,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onForgotPw,
    required this.onSignup,
  });

  @override
  Widget build(BuildContext context) {
    final formBg = isDark ? AppColors.surfaceDark : Colors.white.withValues(alpha: 0.13);
    final formBorder =
        isDark ? AppColors.accentLight.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.22);
    final inputBg = isDark ? AppColors.backgroundDark : Colors.white.withValues(alpha: 0.17);
    final inputBorder =
        isDark ? AppColors.accentLight.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.28);
    final textColor = isDark ? AppColors.textDark : Colors.white;
    final hintColor = isDark ? AppColors.subtextDark : Colors.white.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: formBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: formBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthTextField(
            controller: emailCtrl,
            hint: '이메일',
            icon: Icons.email_outlined,
            isDark: isDark,
            inputBg: inputBg,
            inputBorder: inputBorder,
            textColor: textColor,
            hintColor: hintColor,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          _AuthTextField(
            controller: pwCtrl,
            hint: '비밀번호',
            icon: Icons.lock_outline_rounded,
            isDark: isDark,
            inputBg: inputBg,
            inputBorder: inputBorder,
            textColor: textColor,
            hintColor: hintColor,
            obscure: obscure,
            onSubmitted: (_) => onLogin(),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: hintColor,
                size: 18,
              ),
              onPressed: onToggleObscure,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: loading ? null : onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
                foregroundColor: isDark ? Colors.white : AppColors.primaryLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('로그인',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onForgotPw,
                child: Text('비밀번호 찾기',
                    style: TextStyle(fontSize: 11, color: hintColor)),
              ),
              TextButton(
                onPressed: onSignup,
                child: Text('회원가입',
                    style: TextStyle(fontSize: 11, color: hintColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final Color inputBg;
  final Color inputBorder;
  final Color textColor;
  final Color hintColor;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.inputBg,
    required this.inputBorder,
    required this.textColor,
    required this.hintColor,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: TextStyle(color: textColor, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontSize: 13),
        prefixIcon: Icon(icon, color: hintColor, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryDark : Colors.white,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _SocialLogin extends StatelessWidget {
  final bool isDark;
  final VoidCallback onLogin;
  const _SocialLogin({required this.isDark, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final lineColor =
        isDark ? AppColors.primaryDark.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2);
    final divColor = isDark ? AppColors.subtextDark : Colors.white.withValues(alpha: 0.45);

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: lineColor, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('또는 소셜 계정으로 로그인',
                  style: TextStyle(fontSize: 11, color: divColor)),
            ),
            Expanded(child: Divider(color: lineColor, height: 1)),
          ],
        ),
        const SizedBox(height: 16),
        _SocialButton(
          color: AppColors.kakao,
          textColor: const Color(0xFF191919),
          icon: '💬',
          label: '카카오로 로그인',
          onTap: onLogin,
        ),
        const SizedBox(height: 8),
        _SocialButton(
          color: AppColors.naver,
          textColor: Colors.white,
          icon: 'N',
          label: '네이버로 로그인',
          isText: true,
          onTap: onLogin,
        ),
        const SizedBox(height: 8),
        _SocialButton(
          color: Colors.white,
          textColor: const Color(0xFF191919),
          icon: 'G',
          label: 'Google로 로그인',
          isText: true,
          hasBorder: true,
          onTap: onLogin,
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String icon;
  final String label;
  final bool isText;
  final bool hasBorder;
  final VoidCallback onTap;

  const _SocialButton({
    required this.color,
    required this.textColor,
    required this.icon,
    required this.label,
    this.isText = false,
    this.hasBorder = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: hasBorder
                ? BorderSide(color: Colors.grey.withValues(alpha: 0.3))
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isText
                ? Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(icon,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  )
                : Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  final bool isDark;
  const _ForgotPasswordSheet({required this.isDark});

  @override
  ConsumerState<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).forgotPassword(email);
      if (mounted) setState(() { _sent = true; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? AppColors.textDark : AppColors.textLight;
    final subColor = widget.isDark ? AppColors.subtextDark : AppColors.subtextLight;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('비밀번호 찾기',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close_rounded, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _sent
                ? '재설정 링크를 발송했습니다. 이메일을 확인해주세요.'
                : '가입한 이메일을 입력하면 재설정 링크를 보내드립니다.',
            style: TextStyle(fontSize: 13, color: subColor),
          ),
          if (!_sent) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: '이메일 주소',
                prefixIcon: const Icon(Icons.email_outlined, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _send,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('재설정 링크 발송'),
            ),
          ] else ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DevPanel extends ConsumerStatefulWidget {
  final bool isDark;
  const _DevPanel({required this.isDark});

  @override
  ConsumerState<_DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends ConsumerState<_DevPanel> {
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _reset() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(authServiceProvider).devReset();
      if (mounted) setState(() { _result = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: AppColors.unregistered,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? AppColors.textDark : AppColors.textLight;
    final subColor = widget.isDark ? AppColors.subtextDark : AppColors.subtextLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('DEBUG',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Text('개발자 도구',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close_rounded, color: subColor),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_result == null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade700.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text('다음 작업이 실행됩니다',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red.shade700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...['모든 사용자, 차량, 입출차 기록 삭제', '모든 단지, 채널, 알림 삭제', '앱 관리자 계정 재생성', '기본 단지 및 주차 구역 재생성']
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.remove_rounded, size: 14, color: subColor),
                                const SizedBox(width: 6),
                                Text(s, style: TextStyle(fontSize: 12, color: subColor)),
                              ],
                            ),
                          )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _reset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('DB 초기화 + 기본 데이터 세팅',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.registered.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.registered.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.registered, size: 18),
                      const SizedBox(width: 8),
                      Text('초기화 완료',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ResultRow('이메일', _result!['admin']?['email'] ?? '', subColor, textColor),
                  const SizedBox(height: 6),
                  _ResultRow('비밀번호', _result!['admin']?['password'] ?? '', subColor, textColor),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('닫기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  const _ResultRow(this.label, this.value, this.labelColor, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
        ),
      ],
    );
  }
}
