import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'models/habit_model.dart';
import 'providers/device_identity_provider.dart';
import 'providers/theme_provider.dart';
import 'routing/app_router.dart';
import 'services/alarm_service.dart';
import 'data/repositories/habit_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialise the alarm plugin — must happen before runApp.
  await Alarm.init();
  await AlarmService.initializeNotifications(
    onNotificationTapped: _handleNotificationResponse,
  );

  // If the app was opened by tapping a notification, open the matching alarm.
  final launchDetails = await FlutterLocalNotificationsPlugin()
      .getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp ?? false) {
    final response = launchDetails!.notificationResponse;
    if (response != null) {
      unawaited(_handleNotificationResponse(response));
    }
  }

  // Load saved theme BEFORE runApp so the very first frame uses the correct
  // value — prevents the toggle from appearing off after a restart.
  final savedTheme = await loadSavedThemeMode();

  runApp(
    ProviderScope(
      overrides: [initialThemeModeProvider.overrideWithValue(savedTheme)],
      child: const HabitooApp(),
    ),
  );
}

Future<void> _handleNotificationResponse(NotificationResponse response) async {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  final parts = payload.split('|');
  if (parts.length < 2) return;

  final alarmId = int.tryParse(parts[0]);
  final habitId = parts[1];
  if (alarmId == null || habitId.isEmpty) return;

  final habit = await _fetchHabit(habitId);
  if (habit == null) return;

  void openAlarm() {
    if (rootNavigatorKey.currentContext != null) {
      navigateToAlarm(alarmId: alarmId, habit: habit);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rootNavigatorKey.currentContext != null) {
        navigateToAlarm(alarmId: alarmId, habit: habit);
      }
    });
  }

  if (rootNavigatorKey.currentContext != null) {
    openAlarm();
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) => openAlarm());
  }
}

Future<HabitModel?> _fetchHabit(String habitId) async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(habitId)
        .get();

    if (!doc.exists) return null;
    return HabitModel.fromFirestore(doc);
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Root app widget
// ---------------------------------------------------------------------------

class HabitooApp extends ConsumerStatefulWidget {
  const HabitooApp({super.key});

  @override
  ConsumerState<HabitooApp> createState() => _HabitooAppState();
}

class _HabitooAppState extends ConsumerState<HabitooApp> {
  StreamSubscription<User?>? _authSub;
  String? _lastResetUid;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _resetOutdatedCompletions(currentUser.uid);
    }

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        unawaited(AlarmService.cancelAll());
      } else {
        _resetOutdatedCompletions(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _resetOutdatedCompletions(String uid) {
    if (_lastResetUid == uid) return;
    _lastResetUid = uid;
    unawaited(HabitRepository().resetOutdatedHabitCompletions(uid: uid));
    unawaited(HabitRepository().autoResetMultiDayHabits(uid: uid));
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final deviceIdentityAsync = ref.watch(deviceIdentityProvider);
    final themeMode = ref.watch(themeProvider);

    return deviceIdentityAsync.when(
      data: (_) => MaterialApp.router(
        title: 'Habitoo',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(),
        ),
        routerConfig: router,
        // Wrap the entire app in the alarm watcher so it is always active.
        builder: (context, child) =>
            AlarmWatcher(child: child ?? const SizedBox.shrink()),
      ),
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stackTrace) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Unable to initialise the app: $error')),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AlarmWatcher — listens to Alarm.ringStream and opens AlarmScreen
// ---------------------------------------------------------------------------

/// Sits at the root of the widget tree (via MaterialApp.builder) and reacts
/// to [Alarm.ringing] events.
///
/// When an alarm fires while the app is in the **foreground**, the stream
/// emits an [AlarmSettings] event which we use to look up the habit and push
/// the AlarmScreen.
///
/// When the app is **killed or backgrounded**, the `alarm` package uses
/// Android's `USE_FULL_SCREEN_INTENT` to display the full-screen notification
/// and bring the app back to the foreground — which then also triggers the
/// ringing stream, so this same listener handles that case too.
class AlarmWatcher extends StatefulWidget {
  const AlarmWatcher({super.key, required this.child});
  final Widget child;

  @override
  State<AlarmWatcher> createState() => _AlarmWatcherState();
}

class _AlarmWatcherState extends State<AlarmWatcher> {
  StreamSubscription<AlarmSettings>? _ringSub;

  // Guard against navigating twice if the stream emits quickly.
  int? _lastHandledAlarmId;

  @override
  void initState() {
    super.initState();
    // ignore: deprecated_member_use
    _ringSub = Alarm.ringStream.stream.listen(_onAlarmRing);
  }

  @override
  void dispose() {
    _ringSub?.cancel();
    super.dispose();
  }

  Future<void> _onAlarmRing(AlarmSettings settings) async {
    if (_lastHandledAlarmId == settings.id) return;
    _lastHandledAlarmId = settings.id;
    final appIsInForeground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (appIsInForeground) {
      await AlarmService.cancelAlarmNotification(settings.id);
    }

    // Look up which habit owns this alarm.
    final habitId = await AlarmService.habitIdForAlarm(settings.id);
    if (habitId == null) {
      // Unknown alarm — stop it so it doesn't ring forever.
      await AlarmService.stopAlarm(settings.id);
      return;
    }

    // Fetch the habit from Firestore so we have all fields for AlarmScreen.
    final habit = await _fetchHabit(habitId);
    if (habit == null) {
      await AlarmService.stopAlarm(settings.id);
      return;
    }

    // The alarm screen replaces the notification while the app is open.
    final appIsStillInForeground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (appIsStillInForeground) {
      if (!appIsInForeground) {
        await AlarmService.cancelAlarmNotification(settings.id);
      }
    } else if (mounted) {
      unawaited(
        AlarmService.showAlarmNotification(alarmId: settings.id, habit: habit),
      );
    }

    // Avoid forcing navigation immediately; let the alarm plugin own the ring.
    if (mounted && ModalRoute.of(context)?.settings.name != '/alarm') {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          navigateToAlarm(alarmId: settings.id, habit: habit);
        }
      });
    }

    // Reset guard after a short delay so the same alarm can re-trigger
    // if the user dismisses without completing (edge case).
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _lastHandledAlarmId = null;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
