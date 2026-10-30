import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/habit_model.dart';

/// Manages `users/{uid}/habits/{habitId}` in Firestore.
///
/// All public methods throw [String] error messages on failure so callers
/// can display them directly in the UI without parsing exception types.
class HabitRepository {
  HabitRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _habitsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('habits');

  DocumentReference<Map<String, dynamic>> _habitDoc(
    String uid,
    String habitId,
  ) => _habitsCol(uid).doc(habitId);

  // ---------------------------------------------------------------------------
  // Stream — realtime list
  // ---------------------------------------------------------------------------

  /// Returns a live stream of all habits for [uid], ordered by createdAt asc.
  Stream<List<HabitModel>> watchHabits(String uid) {
    return _habitsCol(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (qs) => qs.docs.map((doc) => HabitModel.fromFirestore(doc)).toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------

  /// Adds a new habit document. The Firestore auto-generated ID is used.
  /// Returns the created [HabitModel] with its assigned [id].
  Future<HabitModel> addHabit({
    required String uid,
    required HabitModel habit,
  }) async {
    try {
      final ref = _habitsCol(uid).doc(); // auto-id
      final withId = habit.copyWith(id: ref.id);
      await ref.set(withId.toFirestore());
      return withId;
    } catch (e) {
      throw 'Failed to save habit. Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // Toggle completion
  // ---------------------------------------------------------------------------

  /// Toggles completion for the current day only.
  Future<void> toggleHabitDone({
    required String uid,
    required HabitModel habit,
  }) async {
    try {
      final today = DateTime.now();
      final todayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final todayIndex = today.weekday - 1;
      final isScheduledToday =
          habit.frequency == 'Daily' || habit.selectedDays.contains(todayIndex);

      if (!isScheduledToday) {
        await _habitDoc(
          uid,
          habit.id,
        ).update({'isCompleted': false, 'completedOnDate': null});
        return;
      }

      final alreadyCompletedToday = habit.completedOnDate == todayKey;
      final nowCompleted = !alreadyCompletedToday;
      final newStreak = nowCompleted
          ? habit.streak + 1
          : (habit.streak > 0 ? habit.streak - 1 : 0);

      await _habitDoc(uid, habit.id).update({
        'isCompleted': nowCompleted,
        'completedOnDate': nowCompleted ? todayKey : null,
        'streak': newStreak,
      });

      await _recordCompletion(
        uid: uid,
        habitId: habit.id,
        dateKey: todayKey,
        wasCompleted: nowCompleted,
        autoCompleted: false,
        alarmClosedAt: null,
      );
    } catch (e) {
      throw 'Failed to update habit. Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // Reset stale completion state
  // ---------------------------------------------------------------------------

  /// Clears `completedOnDate` for any habit whose last completed date is older
  /// than today, so habits become available again the next day.
  Future<void> resetOutdatedHabitCompletions({required String uid}) async {
    try {
      final snapshot = await _habitsCol(uid).get();
      final todayKey = _dateKey(DateTime.now());

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final completedOnDate = data['completedOnDate'] as String?;

        if (completedOnDate != null && completedOnDate != todayKey) {
          await _habitDoc(
            uid,
            doc.id,
          ).update({'isCompleted': false, 'completedOnDate': null});
        }
      }
    } catch (e) {
      throw 'Failed to reset outdated habit completions.';
    }
  }

  // ---------------------------------------------------------------------------
  // Multi-day habit: Auto-complete on alarm close
  // ---------------------------------------------------------------------------

  /// Called when user closes/dismisses the alarm for a multi-day habit.
  /// This auto-marks the habit as complete for today and records in history.
  Future<void> handleAlarmClosed({
    required String uid,
    required HabitModel habit,
  }) async {
    try {
      final today = DateTime.now();
      final todayKey = _dateKey(today);

      // Auto-mark as complete
      await _habitDoc(uid, habit.id).update({
        'isCompleted': true,
        'completedOnDate': todayKey,
        'lastAlarmClosedDate': todayKey,
        'streak': habit.streak + 1,
      });

      // Record in completion history
      await _recordCompletion(
        uid: uid,
        habitId: habit.id,
        dateKey: todayKey,
        wasCompleted: true,
        autoCompleted: true,
        alarmClosedAt: today,
      );
    } catch (e) {
      throw 'Failed to record habit completion. Please try again.';
    }
  }

  /// Auto-resets incomplete status for multi-day habits the next day.
  /// Call this daily (e.g., via background task) to uncomplete habits.
  Future<void> autoResetMultiDayHabits({required String uid}) async {
    try {
      final snapshot = await _habitsCol(
        uid,
      ).where('multiDayDuration', isGreaterThan: 1).get();

      final today = DateTime.now();
      final todayKey = _dateKey(today);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final completedOnDate = data['completedOnDate'] as String?;
        final lastAlarmClosedDate = data['lastAlarmClosedDate'] as String?;

        // If the habit was completed on a previous day, reset it now.
        if (completedOnDate == todayKey || lastAlarmClosedDate == todayKey) {
          continue;
        }

        final staleDateKey = completedOnDate ?? lastAlarmClosedDate;
        if (staleDateKey == null || !_hasPassedToNewDay(staleDateKey)) {
          continue;
        }

        await _habitDoc(
          uid,
          doc.id,
        ).update({'isCompleted': false, 'completedOnDate': null});

        // Record a daily history row for the new date so the table stays correct.
        await _recordCompletion(
          uid: uid,
          habitId: doc.id,
          dateKey: todayKey,
          wasCompleted: false,
          autoCompleted: true,
          alarmClosedAt: null,
        );
      }
    } catch (e) {
      throw 'Failed to auto-reset habits. Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // Completion History
  // ---------------------------------------------------------------------------

  /// Records a completion event in Firestore.
  ///
  /// Writes both:
  /// - `users/{uid}/habits/{habitId}/completionHistory/{dateKey}`
  /// - `users/{uid}/habitCompletionHistory/{habitId}_{dateKey}`
  ///
  /// This gives both a nested relation and a flat table-like collection,
  /// with one unique document per habit per date.
  Future<void> _recordCompletion({
    required String uid,
    required String habitId,
    required String dateKey,
    required bool wasCompleted,
    required bool autoCompleted,
    DateTime? alarmClosedAt,
  }) async {
    try {
      final nestedHistoryRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('habits')
          .doc(habitId)
          .collection('completionHistory')
          .doc(dateKey);

      final tableHistoryRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('habitCompletionHistory')
          .doc('${habitId}_$dateKey');

      final data = {
        'habitId': habitId,
        'dateKey': dateKey,
        'wasCompleted': wasCompleted,
        'completedAt': Timestamp.now(),
        'autoCompleted': autoCompleted,
        'alarmClosedAt': alarmClosedAt != null
            ? Timestamp.fromDate(alarmClosedAt)
            : null,
      };

      await Future.wait([
        nestedHistoryRef.set(data),
        tableHistoryRef.set(data),
      ]);
    } catch (e) {
      throw 'Failed to record completion history.';
    }
  }

  /// Fetches completion history for a habit within a date range.
  /// Useful for generating reports and analytics.
  Future<List<Map<String, dynamic>>> getCompletionHistory({
    required String uid,
    required String habitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startKey = _dateKey(startDate);
      final endKey = _dateKey(endDate);

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('habits')
          .doc(habitId)
          .collection('completionHistory')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw 'Failed to fetch completion history.';
    }
  }

  // ---------------------------------------------------------------------------
  // Helper methods
  // ---------------------------------------------------------------------------

  static String _dateKey(DateTime? date) {
    final d = date ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Checks if a new day has passed since the given date key.
  static bool _hasPassedToNewDay(String? dateKey) {
    if (dateKey == null) return false;
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return false;

      final lastDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      final today = DateTime.now();
      return today.isAfter(lastDate);
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  Future<void> deleteHabit({
    required String uid,
    required String habitId,
  }) async {
    try {
      await _habitDoc(uid, habitId).delete();
    } catch (e) {
      throw 'Failed to delete habit. Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  Future<void> updateHabit({
    required String uid,
    required HabitModel habit,
  }) async {
    try {
      await _habitDoc(uid, habit.id).update(habit.toFirestore());
    } catch (e) {
      throw 'Failed to update habit. Please try again.';
    }
  }
}
