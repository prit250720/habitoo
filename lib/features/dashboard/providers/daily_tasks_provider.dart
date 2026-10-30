import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/daily_task_repository.dart';
import '../../../services/daily_task_generation_service.dart';
import '../../../features/habits/providers/habits_provider.dart';

export '../../../models/daily_task_model.dart';

final dailyTaskRepositoryProvider = Provider<DailyTaskRepository>(
  (_) => DailyTaskRepository(),
);

final currentDailyTaskUidProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

final dailyTasksProvider = StreamProvider<List<DailyTaskModel>>((ref) {
  final uid = ref.watch(currentDailyTaskUidProvider);
  if (uid == null) return const Stream.empty();

  final repo = ref.watch(dailyTaskRepositoryProvider);
  return repo.watchTodayTasks(uid).handleError((_) => <DailyTaskModel>[]);
});

// ---------------------------------------------------------------------------
// XP award result — returned by toggleTaskCompletion so the UI can react.
// ---------------------------------------------------------------------------

class XpAwardResult {
  const XpAwardResult({required this.xpAwarded, required this.xpAmount});

  /// True when XP was credited for the first time on this task.
  final bool xpAwarded;

  /// The amount of XP awarded (0 if not awarded).
  final int xpAmount;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DailyTasksNotifier extends Notifier<AsyncValue<void>> {
  late DailyTaskRepository _repo;
  String? _generatedForDateKey;

  @override
  AsyncValue<void> build() {
    _repo = ref.watch(dailyTaskRepositoryProvider);
    return const AsyncData(null);
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> ensureTodayTasks() async {
    final uid = _uid;
    if (uid == null) return;

    final todayKey = _dateKey(DateTime.now());
    if (_generatedForDateKey == todayKey) return;

    state = const AsyncLoading();
    try {
      final existing = await _repo.getTodayTasks(uid, date: todayKey);
      if (existing.isNotEmpty) {
        _generatedForDateKey = todayKey;
        state = const AsyncData(null);
        return;
      }

      final habitsAsync = ref.read(habitsProvider.future);
      final habits = await habitsAsync;
      final generated = DailyTaskGenerationService.generateTasks(
        uid: uid,
        habits: habits,
        userData: const <String, dynamic>{},
      );
      final saved = await _repo.ensureTodayTasksExist(
        uid: uid,
        tasks: generated,
      );
      if (saved.isNotEmpty) {
        _generatedForDateKey = todayKey;
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Toggles a task's completion state.
  ///
  /// XP is awarded **only on the very first completion** — when
  /// [task.completed] is currently false AND [task.xpEverAwarded] is false.
  /// Unchecking a task never deducts XP, and re-checking it after it was
  /// already awarded also does nothing extra.
  ///
  /// Returns an [XpAwardResult] so callers can show feedback.
  Future<XpAwardResult> toggleTaskCompletion(DailyTaskModel task) async {
    final uid = _uid;
    if (uid == null) return const XpAwardResult(xpAwarded: false, xpAmount: 0);

    // First-time completion = currently incomplete AND XP was never awarded.
    final isFirstCompletion = !task.completed && !task.xpEverAwarded;

    try {
      // Mark task complete/incomplete; stamp xpEverAwarded on first completion.
      await _repo.markCompleted(
        uid: uid,
        taskId: task.taskId,
        completed: !task.completed,
        awardXp: isFirstCompletion,
      );

      // Credit XP to the user's profile only on first completion.
      if (isFirstCompletion) {
        await _repo.awardXpToUser(uid: uid, xpAmount: task.xp);
        return XpAwardResult(xpAwarded: true, xpAmount: task.xp);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }

    return const XpAwardResult(xpAwarded: false, xpAmount: 0);
  }
}

final dailyTasksActionsProvider =
    NotifierProvider<DailyTasksNotifier, AsyncValue<void>>(
      DailyTasksNotifier.new,
    );
