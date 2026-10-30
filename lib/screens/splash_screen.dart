import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_text_styles.dart';
import '../utils/shared_prefs_helper.dart';

/// Splash screen shown on cold launch.
///
/// Checks [SharedPrefsHelper.isLoggedIn]:
/// - `true`  → navigate to `/dashboard`
/// - `false` → navigate to `/phone-login`
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    // ── Fade-in animation ────────────────────────────────────────────────────
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    // ── Auth check ───────────────────────────────────────────────────────────
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    // Small artificial delay so the splash is visible and the app has
    // time to finish its own async init.
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final loggedIn = await SharedPrefsHelper.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      context.go('/dashboard');
    } else {
      context.go('/phone-login');
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── App icon ───────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: cs.onPrimary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),

              // ── App name ───────────────────────────────────────────────
              Text(
                'Habitoo',
                style: AppTextStyles.headlineLgMobile.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Build better habits every day',
                style: AppTextStyles.bodyMd.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),

              // ── Loading indicator ──────────────────────────────────────
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
