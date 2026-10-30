import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/phone_auth_controller.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_ui_tokens.dart';

/// Phone-number OTP login screen.
///
/// Flow:
///   1. User enters phone number → taps "Send OTP"
///   2. OTP input appears → user enters 6-digit code → taps "Verify & Login"
///   3. On [PhoneAuthSuccess] → router redirects to home automatically.
class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    final phone = _phoneController.text.trim();
    await ref.read(phoneAuthControllerProvider.notifier).sendOtp(phone);
    // After OTP sent, focus the OTP field
    if (mounted) {
      final state = ref.read(phoneAuthControllerProvider);
      if (state is PhoneAuthOtpSent) {
        _otpController.clear();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _otpFocus.requestFocus();
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    final state = ref.read(phoneAuthControllerProvider);
    final phone = state is PhoneAuthOtpSent
        ? state.phoneNumber
        : _phoneController.text.trim();
    await ref
        .read(phoneAuthControllerProvider.notifier)
        .verifyOtp(otp: _otpController.text, phoneNumber: phone);
  }

  void _changeNumber() {
    ref.read(phoneAuthControllerProvider.notifier).reset();
    _otpController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _phoneFocus.requestFocus();
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Listen for success → navigate to dashboard
    ref.listen<PhoneAuthState>(phoneAuthControllerProvider, (_, next) {
      if (next is PhoneAuthSuccess && mounted) {
        context.go('/dashboard');
      }
    });

    final state = ref.watch(phoneAuthControllerProvider);
    final isLoading = state is PhoneAuthLoading;
    final isOtpSent = state is PhoneAuthOtpSent;
    final errorMessage = state is PhoneAuthError ? state.message : null;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppUiTokens.screenPadding,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo ──────────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: cs.onPrimary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Heading ───────────────────────────────────────────────
                Text(
                  isOtpSent ? 'Verify OTP' : 'Welcome to Habitoo',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineLgMobile.copyWith(
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOtpSent
                      // ignore: unnecessary_cast
                      ? 'Enter the 6-digit code sent to\n${(state as PhoneAuthOtpSent).phoneNumber}'
                      : 'Sign in with your phone number',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Card ──────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(
                      AppUiTokens.cardRadiusLarge,
                    ),
                    border: Border.all(color: cs.surfaceContainerHigh),
                    boxShadow: [
                      BoxShadow(
                        color: cs.onSurface.withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: isOtpSent
                        ? _OtpStep(
                            key: const ValueKey('otp'),
                            controller: _otpController,
                            focusNode: _otpFocus,
                            isLoading: isLoading,
                            onVerify: _verifyOtp,
                            onChangeNumber: _changeNumber,
                          )
                        : _PhoneStep(
                            key: const ValueKey('phone'),
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            isLoading: isLoading,
                            onSend: _sendOtp,
                          ),
                  ),
                ),

                // ── Error banner ──────────────────────────────────────────
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: errorMessage),
                ],

                const SizedBox(height: 28),

                // ── Switch to email/password login ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Prefer email login? ',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/login'),
                      child: Text(
                        'Sign in with email',
                        style: AppTextStyles.labelMd.copyWith(
                          color: cs.primary,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                          decorationColor: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phone number step
// ---------------------------------------------------------------------------

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label: 'Phone Number'),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[+\d]')),
          ],
          onFieldSubmitted: (_) => isLoading ? null : onSend(),
          style: AppTextStyles.bodyMd.copyWith(color: cs.onSurface),
          decoration: _inputDecoration(
            context: context,
            hint: '+919876543210',
            prefixIcon: Icons.phone_outlined,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Include country code, e.g. +91 for India',
          style: AppTextStyles.labelMd.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Send OTP',
          isLoading: isLoading,
          onPressed: onSend,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// OTP step
// ---------------------------------------------------------------------------

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onVerify,
    required this.onChangeNumber,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onVerify;
  final VoidCallback onChangeNumber;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label: 'One-Time Password'),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onFieldSubmitted: (_) => isLoading ? null : onVerify(),
          style: AppTextStyles.bodyMd.copyWith(
            color: cs.onSurface,
            letterSpacing: 6,
            fontSize: 20,
          ),
          decoration: _inputDecoration(
            context: context,
            hint: '------',
            prefixIcon: Icons.lock_outline_rounded,
          ).copyWith(counterText: ''),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Verify & Login',
          isLoading: isLoading,
          onPressed: onVerify,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: isLoading ? null : onChangeNumber,
          child: Text(
            'Change number',
            style: AppTextStyles.labelMd.copyWith(color: cs.primary),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      style: AppTextStyles.labelMd.copyWith(color: cs.onSurface),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUiTokens.buttonRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: cs.onPrimary,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.labelMd.copyWith(
                  color: cs.onPrimary,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: cs.onErrorContainer,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.labelMd.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required BuildContext context,
  required String hint,
  required IconData prefixIcon,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.bodyMd.copyWith(color: cs.outline),
    prefixIcon: Icon(prefixIcon, color: cs.outline, size: 20),
    filled: true,
    fillColor: cs.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
      borderSide: BorderSide(color: cs.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
      borderSide: BorderSide(color: cs.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
      borderSide: BorderSide(color: cs.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
      borderSide: BorderSide(color: cs.error, width: 2),
    ),
  );
}
