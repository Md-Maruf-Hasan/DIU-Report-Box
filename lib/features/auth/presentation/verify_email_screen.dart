import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  String? _message;

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final isVerified = await repo.reloadAndCheckVerified();

    if (!mounted) return;

    if (isVerified) {
      context.go('/lost-found');
    } else {
      setState(() {
        _isChecking = false;
        _message = 'Email is not yet verified. Please click the link in your university inbox.';
      });
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
      _message = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _message = 'A new verification email has been sent. Please check your inbox & spam folder.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _message = 'Failed to resend email: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify University Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: Color(0xFF006A4E),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email Address',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'We have sent a verification link to:\n${user?.email ?? "your email"}\n\nPlease verify your email to unlock all DIU Report Box features.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),

              if (_message != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _message!.contains('sent')
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _message!.contains('sent')
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _message!.contains('sent')
                          ? Colors.green.shade800
                          : Colors.orange.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // I have verified button
              ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkVerification,
                icon: _isChecking
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('I Have Verified'),
              ),
              const SizedBox(height: 12),

              // Resend verification email button
              OutlinedButton.icon(
                onPressed: _isResending ? null : _resendEmail,
                icon: _isResending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.email_outlined),
                label: const Text('Resend Verification Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
