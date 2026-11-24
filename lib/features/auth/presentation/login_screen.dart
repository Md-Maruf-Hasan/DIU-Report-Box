import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators.dart';
import '../../../app/demo_mode.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (ref.read(demoModeProvider)) {
      if (mounted) context.go('/lost-found');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).signIn(
          _emailController.text,
          _passwordController.text,
        );

    if (success && mounted) {
      context.go('/lost-found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(demoModeProvider);
    final authState = isDemoMode
        ? const AsyncValue<void>.data(null)
        : ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0783C4),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final cardWidth = compact
              ? constraints.maxWidth - 32
              : math.min(820.0, constraints.maxWidth - 48);
          final cardHeight = math.min(
            compact ? 620.0 : 560.0,
            math.max(0.0, constraints.maxHeight - 32),
          );

          return Center(
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  if (!compact) const Expanded(child: _WelcomePanel()),
                  Expanded(
                    child: _LoginForm(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      isLoading: isLoading,
                      authState: authState,
                      compact: compact,
                      onSubmit: _submit,
                      onTogglePassword: () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF087DB8), Color(0xFF0A98D2)],
        ),
      ),
      child: const ClipRect(
        child: CustomPaint(
          painter: _WelcomePainter(),
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome to DIU CAMPUS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Sign in to your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFD5F1FF),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final AsyncValue<void> authState;
  final bool compact;
  final Future<void> Function() onSubmit;
  final VoidCallback onTogglePassword;

  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.authState,
    required this.compact,
    required this.onSubmit,
    required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 40,
        vertical: compact ? 28 : 36,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Hello!',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Good morning',
                style: TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Login to your account',
                style: TextStyle(
                  color: Color(0xFF077EB9),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              if (authState.hasError) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    authState.error.toString().replaceAll('Exception: ', ''),
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _UnderlineField(
                controller: emailController,
                hintText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              _UnderlineField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: obscurePassword,
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your password'
                    : null,
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: false,
                        onChanged: (_) {},
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: Color(0xFF9B9B9B)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const Text(
                        'Remember me',
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF777777)),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => onSubmit(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF05A0B5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/signup'),
                child: const Text(
                  'Create account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF777777),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _UnderlineField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 16, color: Color(0xFF222222)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFB4B4B4),
          fontSize: 15,
        ),
        prefixIcon: Icon(
          keyboardType == TextInputType.emailAddress
              ? Icons.email_outlined
              : Icons.lock_outline,
          color: const Color(0xFF7A8A96),
        ),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD3DCE3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF077EB9), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 12),
      ),
      validator: validator,
    );
  }
}

class _WelcomePainter extends CustomPainter {
  const _WelcomePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rainPaint = Paint()
      ..color = const Color(0xFF78D0F1).withOpacity(0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final glowPaint = Paint()
      ..color = const Color(0xFF73C7EA).withOpacity(0.55);

    final rain = <Offset>[
      Offset(size.width * .18, 15),
      Offset(size.width * .24, 28),
      Offset(size.width * .34, 8),
      Offset(size.width * .43, 28),
      Offset(size.width * .52, 18),
      Offset(size.width * .62, 34),
      Offset(size.width * .71, 13),
      Offset(size.width * .82, 38),
      Offset(size.width * .11, 62),
      Offset(size.width * .27, 48),
      Offset(size.width * .48, 69),
      Offset(size.width * .73, 73),
      Offset(size.width * .88, 57),
      Offset(size.width * .21, 100),
      Offset(size.width * .38, 112),
      Offset(size.width * .67, 105),
    ];

    for (final point in rain) {
      canvas.drawCircle(point, 1.2, glowPaint);
    }
    for (var i = 0; i < 8; i++) {
      final x = (i * 41 + 54) % size.width;
      final y = 76 + (i * 37) % 155;
      canvas.drawLine(
        Offset(x, y.toDouble()),
        Offset(x - 5.0, y.toDouble() + 9.0),
        rainPaint,
      );
    }

    final wavePaint = Paint()
      ..color = const Color(0xFF1C9BCF).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * .63)
      ..quadraticBezierTo(size.width * .18, size.height * .56, size.width * .36,
          size.height * .66)
      ..quadraticBezierTo(size.width * .58, size.height * .76, size.width * .78,
          size.height * .62)
      ..quadraticBezierTo(
          size.width * .90, size.height * .54, size.width, size.height * .58)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, wavePaint);

    final wavePaint2 = Paint()
      ..color = const Color(0xFF075D98).withOpacity(0.28)
      ..style = PaintingStyle.fill;
    final path2 = Path()
      ..moveTo(0, size.height * .82)
      ..quadraticBezierTo(size.width * .24, size.height * .70, size.width * .48,
          size.height * .84)
      ..quadraticBezierTo(
          size.width * .72, size.height * .98, size.width, size.height * .78)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, wavePaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
