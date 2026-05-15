import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  int _step = 0;
  bool _loading = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
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

  Future<void> _onNext() async {
    if (_step == 0) {
      await _doRegister();
    } else if (_step == 1) {
      setState(() => _step = 2);
    } else {
      context.go('/login');
    }
  }

  Future<void> _doRegister() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _pwCtrl.text;
    final confirm = _pwConfirmCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError('모든 필드를 입력해주세요.');
      return;
    }
    if (password != confirm) {
      _showError('비밀번호가 일치하지 않습니다.');
      return;
    }
    if (password.length < 8) {
      _showError('비밀번호는 8자 이상이어야 합니다.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).register(name, email, password);
      if (mounted) setState(() { _step = 1; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) { _showError(e.message); setState(() => _loading = false); }
    } catch (_) {
      if (mounted) { _showError('회원가입에 실패했습니다. 다시 시도해주세요.'); setState(() => _loading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => _step > 0 ? setState(() => _step--) : context.pop(),
        ),
        title: Text(
          '회원가입 (${_step + 1}/3)',
          style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _StepIndicator(step: _step),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: [
                _Step1(
                  nameCtrl: _nameCtrl,
                  emailCtrl: _emailCtrl,
                  pwCtrl: _pwCtrl,
                  pwConfirmCtrl: _pwConfirmCtrl,
                  isDark: isDark,
                ),
                _Step2(email: _emailCtrl.text, isDark: isDark),
                _Step3Complete(isDark: isDark),
              ][_step],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _onNext,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _step == 2 ? '로그인 화면으로' : '다음',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: i <= step
                    ? AppColors.accentLight
                    : AppColors.accentLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController pwCtrl;
  final TextEditingController pwConfirmCtrl;
  final bool isDark;

  const _Step1({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.pwCtrl,
    required this.pwConfirmCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기본 정보 입력',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDark : AppColors.textLight),
        ),
        const SizedBox(height: 6),
        Text(
          '서비스 이용을 위한 정보를 입력해주세요.',
          style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.subtextDark : AppColors.subtextLight),
        ),
        const SizedBox(height: 28),
        _FieldLabel('이름', isDark: isDark),
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: '홍길동'),
        ),
        const SizedBox(height: 16),
        _FieldLabel('이메일', isDark: isDark),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'example@email.com'),
        ),
        const SizedBox(height: 16),
        _FieldLabel('비밀번호', isDark: isDark),
        TextField(
          controller: pwCtrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: '8자 이상 입력'),
        ),
        const SizedBox(height: 16),
        _FieldLabel('비밀번호 확인', isDark: isDark),
        TextField(
          controller: pwConfirmCtrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: '비밀번호를 다시 입력'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Step2 extends StatelessWidget {
  final String email;
  final bool isDark;

  const _Step2({required this.email, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final subColor = isDark ? AppColors.subtextDark : AppColors.subtextLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이메일 인증',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 6),
        Text(
          '아래 이메일로 인증 링크를 발송했습니다.',
          style: TextStyle(fontSize: 13, color: subColor),
        ),
        const SizedBox(height: 4),
        Text(
          email.isEmpty ? 'example@email.com' : email,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.accentLight),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accentLight.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.accentLight.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mail_outline_rounded,
                  color: AppColors.accentLight, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '이메일의 인증 링크를 클릭하여 인증을 완료해 주세요.\n인증 후 관리자 승인을 거쳐 서비스를 이용할 수 있습니다.',
                  style: TextStyle(fontSize: 13, color: subColor, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Step3Complete extends StatelessWidget {
  final bool isDark;
  const _Step3Complete({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.registered.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.registered, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            '가입 완료!',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDark : AppColors.textLight),
          ),
          const SizedBox(height: 8),
          Text(
            '회원가입이 완료되었습니다.\n단지 관리자의 승인 후 서비스를 이용할 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.subtextDark : AppColors.subtextLight,
                height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.subtextDark : AppColors.subtextLight),
      ),
    );
  }
}
