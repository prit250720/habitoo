# Multi-Day Habit Auto-Complete & History Architecture

## 📋 Overview

This design enables:

1. **Auto-complete** - When alarm closes, multi-day habits auto-complete
2. **Auto-reset** - Next day, incomplete status returns automatically
3. **History tracking** - All completion events recorded for reports

---

## 🏗️ Database Structure

### Firestore Collections

```
users/{uid}/
├── habits/{habitId}/
│   ├── name: "Meditation"
│   ├── multiDayDuration: 3          # Takes 3 days to complete
│   ├── isCompleted: true
│   ├── completedOnDate: "2026-07-24"
│   ├── lastAlarmClosedDate: "2026-07-24"
│   ├── streak: 5
│   └── completionHistory/{dateKey}/
│       ├── "2026-07-22": { wasCompleted: true, autoCompleted: true, alarmClosedAt: timestamp }
│       ├── "2026-07-23": { wasCompleted: false, autoCompleted: true, alarmClosedAt: null }
│       └── "2026-07-24": { wasCompleted: true, autoCompleted: true, alarmClosedAt: timestamp }
```

### Key Fields in HabitModel

| Field                 | Type   | Purpose                                                |
| --------------------- | ------ | ------------------------------------------------------ |
| `multiDayDuration`    | int    | Number of days to complete (1 = daily, 2+ = multi-day) |
| `lastAlarmClosedDate` | String | Last date alarm was closed (YYYY-MM-DD format)         |
| `isCompleted`         | bool   | Current completion status                              |
| `completedOnDate`     | String | Date when completed (YYYY-MM-DD format)                |

---

## 🔄 Flow Diagram

### When User Closes Alarm

```
User closes alarm
       ↓
handleAlarmClosed() called
       ↓
├── Set isCompleted = true
├── Set completedOnDate = today
├── Set lastAlarmClosedDate = today
├── Increment streak
└── Record in completionHistory
```

### Every Day (Background Task)

```
autoResetMultiDayHabits() runs
       ↓
For each multi-day habit where:
  - isCompleted = true AND
  - lastAlarmClosedDate = yesterday
       ↓
├── Set isCompleted = false
├── Set completedOnDate = null
└── Record auto-reset in history
```

---

## 💻 Usage Examples

### 1. When Alarm is Closed/Dismissed

```dart
// In your alarm/notification handling code
void onAlarmClosed(HabitModel habit) async {
  try {
    await habitRepository.handleAlarmClosed(
      uid: currentUser.uid,
      habit: habit,
    );
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${habit.name} marked as complete!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}
```

### 2. Auto-Reset (Run Daily via Background Task)

```dart
// Call this once per day (use WorkManager or similar)
void setupDailyAutoReset() {
  Workmanager().registerPeriodicTask(
    'habitAutoReset',
    'autoResetHabits',
    frequency: Duration(hours: 24),
    initialDelay: Duration(hours: 1), // Run 1 hour after midnight
  );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'autoResetHabits') {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await habitRepository.autoResetMultiDayHabits(uid: user.uid);
        }
      } catch (e) {
        print('Auto-reset failed: $e');
      }
    }
    return Future.value(true);
  });
}
```

### 3. Get Completion History for Reports

```dart
// Fetch completion data for the last 30 days
Future<void> loadCompletionReport(String habitId) async {
  try {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: 30));

    final history = await habitRepository.getCompletionHistory(
      uid: currentUser.uid,
      habitId: habitId,
      startDate: startDate,
      endDate: endDate,
    );

    // Calculate completion percentage
    final completedDays = history
        .where((h) => h['wasCompleted'] == true)
        .length;
    final completionPercent = (completedDays / 30 * 100).toStringAsFixed(1);

    print('Completion: $completionPercent%');
    print('Auto-completed: ${history.where((h) => h['autoCompleted'] == true).length}');
  } catch (e) {
    print('Error loading report: $e');
  }
}
```

### 4. Creating a Multi-Day Habit

```dart
final multiDayHabit = HabitModel(
  id: 'habit_1',
  name: 'Read Book',
  category: 'Learning',
  frequency: 'Daily',
  selectedDays: [0, 1, 2, 3, 4, 5, 6], // All days
  reminderTime: '20:00',
  goalType: GoalType.simpleCheck,
  streak: 0,
  period: HabitPeriod.evening,
  accentColorValue: Colors.blue.value,
  iconCodePoint: Icons.book.codePoint,
  isCompleted: false,
  multiDayDuration: 3, // Takes 3 days to complete!
);

await habitRepository.addHabit(
  uid: currentUser.uid,
  habit: multiDayHabit,
);
```

---

## 📊 Report Generation

Use completion history to create insights:

```dart
class HabitReport {
  final String habitId;
  final int totalDays;
  final int completedDays;
  final int autoCompletedDays;
  final double completionPercentage;
  final List<DateTime> completedDates;

  double get consistencyScore => completionPercentage;

  int get manualCompletions => completedDays - autoCompletedDays;

  HabitReport.fromHistory({
    required this.habitId,
    required List<Map<String, dynamic>> history,
  })  : totalDays = history.length,
        completedDays =
            history.where((h) => h['wasCompleted'] == true).length,
        autoCompletedDays =
            history.where((h) => h['autoCompleted'] == true).length,
        completionPercentage =
            (history.where((h) => h['wasCompleted'] == true).length /
                history.length *
                100),
        completedDates = history
            .where((h) => h['wasCompleted'] == true)
            .map((h) {
              final key = h['dateKey'] as String;
              final parts = key.split('-');
              return DateTime(int.parse(parts[0]), int.parse(parts[1]),
                  int.parse(parts[2]));
            })
            .toList();
}
```

---

## 🔑 Key Points

1. **Auto-complete triggers**: Only when alarm is closed/dismissed
2. **Auto-reset timing**: Happens daily via background task
3. **History immutable**: All completion records are permanent for reporting
4. **Streak logic**:
   - Increases when auto-completed
   - Can be manually adjusted by user toggle
5. **Multi-day value**:
   - `1` = normal daily habit
   - `2+` = multi-day habit with auto-reset

---

## ⚙️ Setup Checklist

- [ ] Add `multiDayDuration` field to Firestore habit documents
- [ ] Add `lastAlarmClosedDate` field to Firestore habit documents
- [ ] Implement `handleAlarmClosed()` in alarm handler
- [ ] Set up `autoResetMultiDayHabits()` background task
- [ ] Create completion history subcollection (auto-created on first record)
- [ ] Add completion report UI showing history from subcollection
- [ ] Test with multi-day habit (set `multiDayDuration: 2` or `3`)
- [ ] Verify history records appear in Firestore console
- [ ] Add WorkManager or similar for daily background task

---

## 🚀 Future Enhancements

- [ ] Consecutive multi-day tracking (e.g., "Day 2 of 3")
- [ ] Visual calendar showing auto-completed vs manual
- [ ] Streak protection for multi-day habits
- [ ] Analytics showing manual vs auto completion ratio
- [ ] Notifications for multi-day progress (e.g., "2 of 3 days done")
