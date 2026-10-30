import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit_model.dart';

/// Maps a habit's [reminderTime] ("HH:mm") + [selectedDays] into one or more
/// [AlarmSettings] and keeps them scheduled via the `alarm` package.
///
/// Alarm IDs are derived from the habit's Firestore document ID so they are
/// stable across app restarts.
class AlarmService {
  AlarmService._();

  static const String _kPrefsKey = 'alarm_habit_map'; // habitId → [alarmIds]
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _timezoneInitialized = false;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Schedule (or re-schedule) all alarms for [habit].
  ///
  /// Cancels any previously registered alarms for this habit first, then
  /// creates a new alarm for the next upcoming occurrence on each selected
  /// weekday.
  static Future<void> scheduleForHabit(HabitModel habit) async {
    // Cancel old alarms before re-scheduling.
    await cancelForHabit(habit.id);

    final parts = habit.reminderTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;

    final now = DateTime.now();
    final List<int> alarmIds = [];

    // For each selected weekday, schedule an alarm for the next occurrence.
    final days = habit.selectedDays.isEmpty
        ? List<int>.generate(7, (i) => i)
        : habit.selectedDays;

    for (final weekday in days) {
      // Dart weekday: Mon=1 … Sun=7.
      // Our index: Mon=0 … Sun=6  →  dartWeekday = index + 1.
      final dartWeekday = weekday + 1;
      final alarmId = _idForHabitDay(habit.id, weekday);

      DateTime alarmTime = _nextOccurrence(now, dartWeekday, hour, minute);

      final settings = AlarmSettings(
        id: alarmId,
        dateTime: alarmTime,
        assetAudioPath: 'assets/audio/alarm.mp3',
        loopAudio: true,
        vibrate: true,
        warningNotificationOnKill: false,
        androidFullScreenIntent: true,
        volumeSettings: VolumeSettings.fade(
          volume: 0.8,
          fadeDuration: const Duration(seconds: 3),
        ),
        notificationSettings: NotificationSettings(
          title: habit.name,
          body: _notificationBody(habit),
          // Payload carries habitId so the app can open the right AlarmScreen.
          icon: 'notification_icon',
        ),
      );

      await Alarm.set(alarmSettings: settings);
      await scheduleAlarmNotification(
        alarmId: alarmId,
        habit: habit,
        alarmTime: alarmTime,
      );
      alarmIds.add(alarmId);
    }

    await _persistAlarmIds(habit.id, alarmIds);
  }

  /// Initialise the local notification plugin used as a fallback when the
  /// alarm fires while the app is backgrounded or reopened.
  static Future<void> initializeNotifications({
    Future<void> Function(NotificationResponse response)? onNotificationTapped,
  }) async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _ensureTimezoneInitialized();
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onNotificationTapped == null
          ? null
          : (response) => unawaited(onNotificationTapped(response)),
    );

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'habit_alarm_channel',
          'Habit alarms',
          description: 'Notifications for active habit alarms',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();
    }

  }

  static Future<void> _ensureTimezoneInitialized() async {
    if (_timezoneInitialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _timezoneInitialized = true;
  }

  /// Schedule a local notification for the alarm so it appears even if the app
  /// is backgrounded or closed when the time arrives.
  static Future<void> scheduleAlarmNotification({
    required int alarmId,
    required HabitModel habit,
    required DateTime alarmTime,
  }) async {
    await _ensureTimezoneInitialized();

    const androidDetails = AndroidNotificationDetails(
      'habit_alarm_channel',
      'Habit alarms',
      channelDescription: 'Notifications for active habit alarms',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );
    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.zonedSchedule(
      alarmId,
      habit.name,
      _notificationBody(habit),
      tz.TZDateTime.from(alarmTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$alarmId|${habit.id}',
    );
  }

  /// Show a local notification for an alarm that just fired.
  static Future<void> showAlarmNotification({
    required int alarmId,
    required HabitModel habit,
  }) async {
    final content = notificationContent(habit);
    const androidDetails = AndroidNotificationDetails(
      'habit_alarm_channel',
      'Habit alarms',
      channelDescription: 'Notifications for active habit alarms',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );
    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      alarmId,
      content['title'],
      content['body'],
      details,
      payload: '$alarmId|${habit.id}',
    );
  }

  /// Build the text used for the app notification for [habit].
  static Map<String, String> notificationContent(HabitModel habit) {
    return {'title': habit.name, 'body': _notificationBody(habit)};
  }

  /// Cancel every alarm associated with [habitId].
  static Future<void> cancelForHabit(String habitId) async {
    final ids = await _loadAlarmIds(habitId);
    for (final id in ids) {
      await _safeStopAlarm(id);
    }
    await _removeAlarmIds(habitId);
  }

  /// Cancel every known alarm and clear the persisted mapping.
  /// Used when the user signs out so no old reminders continue ringing.
  static Future<void> cancelAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);

    for (final entry in map.values) {
      final ids = (entry as List).map((e) => (e as num).toInt()).toList();
      for (final id in ids) {
        await _safeStopAlarm(id);
      }
    }

    await prefs.remove(_kPrefsKey);
  }

  /// Stop a ringing alarm by its numeric [alarmId].
  static Future<void> stopAlarm(int alarmId) async {
    await _safeStopAlarm(alarmId);
  }

  static Future<void> _safeStopAlarm(int alarmId) async {
    try {
      await _localNotifications.cancel(alarmId);
      await Alarm.stop(alarmId).timeout(const Duration(seconds: 2));
    } on TimeoutException catch (_) {
      // Ignore plugin/runtime stalls so logout and alarm cleanup remain
      // resilient even if the alarm plugin is unavailable or slow.
    } catch (_) {
      // Ignore plugin/runtime failures so logout and alarm cleanup remain
      // resilient even if the alarm plugin is unavailable.
    }
  }

  /// Re-schedule the alarm for [alarmId] to fire again tomorrow (or the next
  /// matching weekday) — used after the user dismisses today's alarm so it
  /// rings again next time.
  static Future<void> rescheduleNext(int alarmId, HabitModel habit) async {
    // Infer the weekday index from the alarmId.
    final weekdayIndex = alarmId % 10; // last digit encodes weekday 0-6
    final dartWeekday = weekdayIndex + 1;

    final parts = habit.reminderTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;

    final now = DateTime.now();
    // Add 1 second so _nextOccurrence skips "right now" and targets next week.
    final nextTime = _nextOccurrence(
      now.add(const Duration(seconds: 1)),
      dartWeekday,
      hour,
      minute,
    );

    final settings = AlarmSettings(
      id: alarmId,
      dateTime: nextTime,
      assetAudioPath: 'assets/audio/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: false,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: const Duration(seconds: 3),
      ),
      notificationSettings: NotificationSettings(
        title: habit.name,
        body: _notificationBody(habit),
        icon: 'notification_icon',
      ),
    );

    await Alarm.set(alarmSettings: settings);
    await scheduleAlarmNotification(
      alarmId: alarmId,
      habit: habit,
      alarmTime: nextTime,
    );
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Generates a stable int ID from a habitId + weekday index.
  /// We take the last 8 decimal digits of the hash, then encode the weekday
  /// (0-6) as the last digit so we can recover it later.
  static int _idForHabitDay(String habitId, int weekdayIndex) {
    final base = habitId.hashCode.abs() % 10000000; // 7 digits max
    return base * 10 + weekdayIndex; // last digit = weekday
  }

  /// Next [DateTime] on [dartWeekday] (1=Mon…7=Sun) at [hour]:[minute] that
  /// is strictly after [from].
  static DateTime _nextOccurrence(
    DateTime from,
    int dartWeekday,
    int hour,
    int minute,
  ) {
    // Start at today's candidate time.
    DateTime candidate = DateTime(
      from.year,
      from.month,
      from.day,
      hour,
      minute,
    );

    // Advance day by day until we land on the right weekday AND in the future.
    while (candidate.weekday != dartWeekday || !candidate.isAfter(from)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static String _notificationBody(HabitModel habit) {
    switch (habit.goalType) {
      case GoalType.counter:
        return 'Time to count your reps! Tap to open.';
      case GoalType.duration:
        return 'Start your timer! Tap to open.';
      case GoalType.simpleCheck:
        return 'Ready to check this off? Tap to open.';
    }
  }

  // -------------------------------------------------------------------------
  // SharedPreferences persistence (habitId → list of alarmIds)
  // -------------------------------------------------------------------------

  static Future<void> _persistAlarmIds(String habitId, List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    map[habitId] = ids;
    await prefs.setString(_kPrefsKey, jsonEncode(map));
  }

  static Future<List<int>> _loadAlarmIds(String habitId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final list = map[habitId];
    if (list == null) return [];
    return (list as List).map((e) => (e as num).toInt()).toList();
  }

  static Future<void> _removeAlarmIds(String habitId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    map.remove(habitId);
    await prefs.setString(_kPrefsKey, jsonEncode(map));
  }

  // -------------------------------------------------------------------------
  // Reverse lookup: alarmId → habitId
  // -------------------------------------------------------------------------

  /// Returns the habitId that owns [alarmId], or null if not found.
  /// Used by the foreground ring-stream listener to navigate to the right
  /// AlarmScreen without a Firestore round-trip on the ID lookup.
  static Future<String?> habitIdForAlarm(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    for (final entry in map.entries) {
      final ids = (entry.value as List).map((e) => (e as num).toInt()).toList();
      if (ids.contains(alarmId)) return entry.key;
    }
    return null;
  }
}
