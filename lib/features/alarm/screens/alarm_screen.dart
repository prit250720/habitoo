import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_ui_tokens.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../../models/habit_model.dart';
import '../../../services/alarm_service.dart';

/// Full-screen alarm page that rings until the user completes their goal.
///
/// The caller passes [alarmId] and [habit] via GoRouter `extra`
/// (wrapped in `_AlarmArgs` inside app_router.dart).
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key, required this.alarmId, required this.habit});

  final int alarmId;
  final HabitModel habit;

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with TickerProviderStateMixin {
  // ── Counter goal ──────────────────────────────────────────────────────────
  static const int _counterTarget = 10;
  int _counterValue = 0;

  // ── Duration goal ─────────────────────────────────────────────────────────
  static const int _durationSeconds = 60; // 1 minute
  late int _remainingSeconds;
  Timer? _timer;
  bool _timerRunning = false;

  // ── Shared ────────────────────────────────────────────────────────────────
  bool _goalComplete = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _durationSeconds;

    // Keep screen on and show over lock screen.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Pulsing icon animation while alarm is ringing.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Goal logic ────────────────────────────────────────────────────────────

  void _onSimpleCheckTap() {
    if (_goalComplete) return;
    setState(() => _goalComplete = true);
    _stopAlarmAndPop();
  }

  void _incrementCounter() {
    if (_goalComplete) return;
    setState(() {
      _counterValue++;
      if (_counterValue >= _counterTarget) {
        _goalComplete = true;
        _stopAlarmAndPop();
      }
    });
  }

  void _startTimer() {
    if (_timerRunning || _goalComplete) return;
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          t.cancel();
          _goalComplete = true;
          _stopAlarmAndPop();
        }
      });
    });
  }

  Future<void> _stopAlarmAndPop() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await HabitRepository().handleAlarmClosed(
          uid: uid,
          habit: widget.habit,
        );
      } catch (_) {
        // Ignore history write failures so the alarm still stops.
      }
    }

    _pulseController.stop();
    await AlarmService.stopAlarm(widget.alarmId);
    // Re-schedule for the next occurrence so the alarm rings again next time.
    await AlarmService.rescheduleNext(widget.alarmId, widget.habit);
    if (mounted) context.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final accentColor = habit.accentColor;
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      // Prevent back-swipe — user must complete the goal to dismiss.
      canPop: false,
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppUiTokens.screenPadding,
              vertical: 32,
            ),
            child: Column(
              children: [
                // ── Top bar ───────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TimeDisplay(accentColor: accentColor),
                    _AlarmLabel(accentColor: accentColor),
                  ],
                ),
                const Spacer(),

                // ── Habit icon (pulsing) ──────────────────────────────────
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                    child: Icon(habit.icon, color: accentColor, size: 56),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Habit name ────────────────────────────────────────────
                Text(
                  habit.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineLg.copyWith(
                    color: cs.onSurface,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _goalSubtitle(habit.goalType),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),

                // ── Goal-specific widget ──────────────────────────────────
                _buildGoalWidget(habit.goalType, accentColor, cs),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalWidget(
    GoalType goalType,
    Color accentColor,
    ColorScheme cs,
  ) {
    switch (goalType) {
      case GoalType.simpleCheck:
        return _SimpleCheckWidget(
          accentColor: accentColor,
          onTap: _onSimpleCheckTap,
        );
      case GoalType.counter:
        return _CounterWidget(
          current: _counterValue,
          target: _counterTarget,
          accentColor: accentColor,
          onIncrement: _incrementCounter,
        );
      case GoalType.duration:
        return _DurationWidget(
          remaining: _remainingSeconds,
          total: _durationSeconds,
          running: _timerRunning,
          accentColor: accentColor,
          onStart: _startTimer,
        );
    }
  }

  String _goalSubtitle(GoalType t) {
    switch (t) {
      case GoalType.simpleCheck:
        return 'Complete your habit to stop the alarm';
      case GoalType.counter:
        return 'Tap $_counterTarget times to stop the alarm';
      case GoalType.duration:
        return 'Run the timer to stop the alarm';
    }
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _TimeDisplay extends StatefulWidget {
  const _TimeDisplay({required this.accentColor});
  final Color accentColor;

  @override
  State<_TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<_TimeDisplay> {
  late Timer _t;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return Text(
      '$h:$m',
      style: AppTextStyles.headlineLg.copyWith(
        color: widget.accentColor,
        fontSize: 36,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AlarmLabel extends StatelessWidget {
  const _AlarmLabel({required this.accentColor});
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppUiTokens.buttonRadius),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm, size: 16, color: accentColor),
          const SizedBox(width: 6),
          Text(
            'Alarm',
            style: AppTextStyles.labelMd.copyWith(color: accentColor),
          ),
        ],
      ),
    );
  }
}

// ── Simple Check ──────────────────────────────────────────────────────────────

class _SimpleCheckWidget extends StatelessWidget {
  const _SimpleCheckWidget({required this.accentColor, required this.onTap});

  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Tap the button below once you've done it",
          textAlign: TextAlign.center,
          style: AppTextStyles.labelMd.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.45),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 72,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Counter ───────────────────────────────────────────────────────────────────

class _CounterWidget extends StatelessWidget {
  const _CounterWidget({
    required this.current,
    required this.target,
    required this.accentColor,
    required this.onIncrement,
  });

  final int current;
  final int target;
  final Color accentColor;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (current / target).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$current',
                    style: AppTextStyles.headlineLg.copyWith(
                      color: accentColor,
                      fontSize: 42,
                    ),
                  ),
                  Text(
                    'of $target',
                    style: AppTextStyles.labelMd.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.40),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap + to count each rep',
          style: AppTextStyles.labelSm.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Duration ──────────────────────────────────────────────────────────────────

class _DurationWidget extends StatelessWidget {
  const _DurationWidget({
    required this.remaining,
    required this.total,
    required this.running,
    required this.accentColor,
    required this.onStart,
  });

  final int remaining;
  final int total;
  final bool running;
  final Color accentColor;
  final VoidCallback onStart;

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = 1.0 - (remaining / total).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmt(remaining),
                    style: AppTextStyles.headlineLg.copyWith(
                      color: accentColor,
                      fontSize: 36,
                    ),
                  ),
                  Text(
                    'remaining',
                    style: AppTextStyles.labelMd.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (!running)
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(AppUiTokens.buttonRadius),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.40),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Start Timer',
                    style: AppTextStyles.labelMd.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Timer running…',
                style: AppTextStyles.labelMd.copyWith(color: accentColor),
              ),
            ],
          ),
      ],
    );
  }
}
