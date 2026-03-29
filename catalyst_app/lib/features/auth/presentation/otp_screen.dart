import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:catalyst_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:catalyst_app/shared/widgets/loading_overlay.dart';
import 'package:catalyst_app/shared/widgets/animated_pressable.dart';
import 'package:catalyst_app/features/auth/presentation/login_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  String? _inlineError;

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) return;

    setState(() => _inlineError = null);
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      await ref.read(authRepositoryProvider).verifyOtp(
        email: widget.email,
        token: _otpController.text.trim(),
      );
      if (mounted) context.go('/onboarding');
    } catch (e) {
      if (mounted) {
        setState(() => _inlineError = 'Incorrect OTP, try again');
      }
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Verifying...',
      child: Scaffold(
        appBar: AppBar(title: const Text('Verify OTP')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Enter the 6-digit code sent to', style: Theme.of(context).textTheme.bodySmall),
              Text(widget.email, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: '6-digit code',
                  errorText: _inlineError,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AnimatedPressable(
                  onTap: _verifyOtp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Verify',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedPressable(
                onTap: () => context.pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
