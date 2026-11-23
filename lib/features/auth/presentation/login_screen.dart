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
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0783C4),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;
          final cardWidth = compact
              ? constraints.maxWidth - 32
              : math.min(580.0, constraints.maxWidth - 48);
          final cardHeight =
              compact ? math.min(520.0, constraints.maxHeight - 32) : 308.0;

          return Center(
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
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
      child: ClipRect(
        child: CustomPaint(
          painter: _WelcomePainter(),
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                right: 0,
                top: 155,
                child: Column(
                  children: [
                    Text(
                      'Welcome Page',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sign in To your Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD5F1FF),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                child: Text(
                  'WWW.YOURSITE.COM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
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
  final Future<void> Function() onSubmit;
  final VoidCallback onTogglePassword;

  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.authState,
    required this.onSubmit,
    required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      padding: const EdgeInsets.fromLTRB(30, 50, 30, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hello!',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 9,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Good Morning',
              style: TextStyle(
                color: Color(0xFF111111),
                fontSize: 9,
                height: 1,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Login Your Account',
              style: TextStyle(
                color: Color(0xFF077EB9),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _UnderlineField(
              controller: emailController,
              hintText: 'Email Address',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 6),
            _UnderlineField(
              controller: passwordController,
              hintText: 'Password',
              obscureText: obscurePassword,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter your password' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: Checkbox(
                    value: false,
                    onChanged: (_) {},
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    side:
                        const BorderSide(color: Color(0xFF9B9B9B), width: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Remember',
                  style: TextStyle(fontSize: 6.5, color: Color(0xFF777777)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forget Password?',
                    style: TextStyle(
                      fontSize: 6.5,
                      color: Color(0xFF777777),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 21,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => onSubmit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF05A0B5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'SUBMIT',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 9),
            TextButton(
              onPressed: () => context.push('/signup'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 6.5,
                  color: Color(0xFF777777),
                ),
              ),
            ),
          ],
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

  const _UnderlineField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 8, color: Color(0xFF444444)),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFB4B4B4),
          fontSize: 7.5,
          letterSpacing: 0.5,
        ),
        contentPadding: const EdgeInsets.only(bottom: 7),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF9A9A9A), width: 0.7),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF077EB9), width: 1),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 0.7),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        errorStyle: const TextStyle(fontSize: 7, height: 0.8),
      ),
      validator: validator,
    );
  }
}

class _WelcomePainter extends CustomPainter {
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
