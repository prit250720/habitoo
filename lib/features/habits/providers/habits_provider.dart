import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/habit_repository.dart';
import '../../../models/habit_model.dart';
import '../../../services/alarm_service.dart';

export '../../../models/habit_model.dart' show HabitModel, HabitPeriod;
export '../../../models/daily_task_model.dart' show DailyTaskModel;

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final habitRepositoryProvider = Provider<HabitRepository>(
  (_) => HabitRepository(),
);

// ---------------------------------------------------------------------------
// Current UID helper
// ---------------------------------------------------------------------------

/// Returns the Firebase UID of the signed-in user, or null.
final currentUidProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

// ---------------------------------------------------------------------------
// Habits stream provider
// ---------------------------------------------------------------------------

/// Streams the full list of habits for the current user from Firestore.
/// Emits [AsyncLoading] while connecting, [AsyncData] once data arrives,
/// and [AsyncError] on Firestore errors.
///
/// Returns an empty list when no user is signed in.
final habitsProvider = StreamProvider<List<HabitModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();

  final repo = ref.watch(habitRepositoryProvider);
  return repo.watchHabits(uid);
});

// ---------------------------------------------------------------------------
// Habits actions notifier
// ---------------------------------------------------------------------------

/// Exposes write operations (add, toggle, delete, update) against Firestore.
/// Also keeps alarms in sync: schedules on add/update, cancels on delete.
///
/// State is [AsyncValue<void>] — consumers watch it to react to
/// loading / error / success.
class HabitsActionsNotifier extends Notifier<AsyncValue<void>> {
  late HabitRepository _repo;

  @override
  AsyncValue<void> build() {
    _repo = ref.watch(habitRepositoryProvider);
    return const AsyncData(null);
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Add ──────────────────────────────────────────────────────────────────

  Future<bool> addHabit(HabitModel habit) async {
    final uid = _uid;
    if (uid == null) {
      state = AsyncError('Not signed in', StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    try {
      // Firestore gives back the model with its real document ID.
      final saved = await _repo.addHabit(uid: uid, habit: habit);
      // Schedule alarms using the permanent ID.
      await AlarmService.scheduleForHabit(saved);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  // ── Toggle done ──────────────────────────────────────────────────────────

  Future<void> toggleHabitDone(HabitModel habit) async {
    final uid = _uid;
    if (uid == null) return;
    // Optimistic: don't block UI — fire and forget, errors surfaced via state.
    try {
      await _repo.toggleHabitDone(uid: uid, habit: habit);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteHabit(String habitId) async {
    final uid = _uid;
    if (uid == null) return;
    state = const AsyncLoading();
    try {
      // Cancel alarms before removing from Firestore so we still have the ID.
      await AlarmService.cancelForHabit(habitId);
      await _repo.deleteHabit(uid: uid, habitId: habitId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Update ───────────────────────────────────────────────────────────────

  /// Updates the habit in Firestore and re-schedules its alarms to reflect
  /// any changes to reminderTime or selectedDays.
  Future<bool> updateHabit(HabitModel habit) async {
    final uid = _uid;
    if (uid == null) {
      state = AsyncError('Not signed in', StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    try {
      await _repo.updateHabit(uid: uid, habit: habit);
      // Cancel old alarms and schedule fresh ones with updated settings.
      await AlarmService.scheduleForHabit(habit);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final habitsActionsProvider =
    NotifierProvider<HabitsActionsNotifier, AsyncValue<void>>(
      HabitsActionsNotifier.new,
    );
