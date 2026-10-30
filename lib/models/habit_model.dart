import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum HabitPeriod { morning, afternoon, evening, night }

/// Which days of the week the habit should repeat on (0 = Monday … 6 = Sunday).
typedef SelectedDays = List<int>;

/// How the user measures completion of a habit.
enum GoalType {
  simpleCheck, // Binary done / not-done
  counter, // Hit a numeric target
  duration, // Spend N minutes
}

/// Persistent habit model stored at `users/{uid}/habits/{habitId}` in Firestore.
class HabitModel {
  const HabitModel({
    required this.id,
    required this.name,
    required this.category,
    required this.frequency,
    required this.selectedDays,
    required this.reminderTime,
    required this.goalType,
    required this.streak,
    required this.period,
    required this.accentColorValue,
    required this.iconCodePoint,
    required this.isCompleted,
    this.createdAt,
    this.completedOnDate,
    this.multiDayDuration =
        1, // Number of days to complete (1 = single day, 2+ = multi-day)
    this.lastAlarmClosedDate, // Last date when alarm was closed
  });

  final String id;
  final String name;
  final String category;

  /// 'Daily' | 'Weekly' | 'Custom'
  final String frequency;

  /// Indices of selected weekday: 0 = Mon, 1 = Tue, … 6 = Sun
  final List<int> selectedDays;
  final String reminderTime;
  final GoalType goalType;
  final int streak;
  final HabitPeriod period;
  final int accentColorValue;
  final int iconCodePoint;
  final bool isCompleted;
  final DateTime? createdAt;
  final String? completedOnDate;

  /// Number of days this habit takes to complete (1 = daily, 2+ = multi-day).
  /// Example: if multiDayDuration = 3, habit takes 3 days to complete.
  final int multiDayDuration;

  /// Last date key when alarm was closed (triggers auto-complete).
  /// Format: 'YYYY-MM-DD'
  final String? lastAlarmClosedDate;

  // ---------------------------------------------------------------------------
  // Convenience getters for the UI
  // ---------------------------------------------------------------------------

  Color get accentColor => Color(accentColorValue);
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  bool isCompletedForDate(DateTime date) {
    if (completedOnDate == null) return false;
    return completedOnDate == _dateKey(date);
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory HabitModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? {};

    // selectedDays stored as List<int>; default Mon–Fri (0–4) for Daily.
    final rawDays = d['selectedDays'];
    final List<int> parsedDays = rawDays is List
        ? rawDays.map((e) => (e as num).toInt()).toList()
        : [0, 1, 2, 3, 4];

    final completedOnDate = d['completedOnDate'] as String?;
    final todayKey = _dateKey(DateTime.now());
    final legacyCompleted = (d['isCompleted'] as bool?) ?? false;

    return HabitModel(
      id: snap.id,
      name: (d['name'] as String?) ?? '',
      category: (d['category'] as String?) ?? 'Health',
      frequency: (d['frequency'] as String?) ?? 'Daily',
      selectedDays: parsedDays,
      reminderTime: (d['reminderTime'] as String?) ?? '08:00',
      goalType: _goalTypeFromString(
        (d['goalType'] as String?) ?? 'simpleCheck',
      ),
      streak: (d['streak'] as num?)?.toInt() ?? 0,
      period: _periodFromString((d['period'] as String?) ?? 'morning'),
      accentColorValue:
          (d['accentColorValue'] as num?)?.toInt() ??
          AppColors.primary.toARGB32(),
      iconCodePoint:
          (d['iconCodePoint'] as num?)?.toInt() ??
          Icons.fitness_center.codePoint,
      isCompleted: completedOnDate != null
          ? completedOnDate == todayKey
          : legacyCompleted,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      completedOnDate: completedOnDate,
      multiDayDuration: (d['multiDayDuration'] as num?)?.toInt() ?? 1,
      lastAlarmClosedDate: (d['lastAlarmClosedDate'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'frequency': frequency,
      'selectedDays': selectedDays,
      'reminderTime': reminderTime,
      'goalType': goalType.name,
      'streak': streak,
      'period': period.name,
      'accentColorValue': accentColorValue,
      'iconCodePoint': iconCodePoint,
      'isCompleted': isCompleted,
      'completedOnDate': completedOnDate,
      'multiDayDuration': multiDayDuration,
      'lastAlarmClosedDate': lastAlarmClosedDate,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  HabitModel copyWith({
    String? id,
    String? name,
    String? category,
    String? frequency,
    List<int>? selectedDays,
    String? reminderTime,
    GoalType? goalType,
    int? streak,
    HabitPeriod? period,
    int? accentColorValue,
    int? iconCodePoint,
    bool? isCompleted,
    DateTime? createdAt,
    String? completedOnDate,
    int? multiDayDuration,
    String? lastAlarmClosedDate,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      selectedDays: selectedDays ?? this.selectedDays,
      reminderTime: reminderTime ?? this.reminderTime,
      goalType: goalType ?? this.goalType,
      streak: streak ?? this.streak,
      period: period ?? this.period,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedOnDate: completedOnDate ?? this.completedOnDate,
      multiDayDuration: multiDayDuration ?? this.multiDayDuration,
      lastAlarmClosedDate: lastAlarmClosedDate ?? this.lastAlarmClosedDate,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static HabitPeriod _periodFromString(String value) {
    switch (value) {
      case 'night':
        return HabitPeriod.night;
      case 'evening':
        return HabitPeriod.evening;
      case 'afternoon':
        return HabitPeriod.afternoon;
      default:
        return HabitPeriod.morning;
    }
  }

  static GoalType _goalTypeFromString(String value) {
    switch (value) {
      case 'counter':
        return GoalType.counter;
      case 'duration':
        return GoalType.duration;
      default:
        return GoalType.simpleCheck;
    }
  }
}
