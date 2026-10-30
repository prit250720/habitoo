import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/daily_task_model.dart';

/// Manages daily tasks stored at users/{uid}/daily_tasks/{taskId}.
class DailyTaskRepository {
  DailyTaskRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ── Collection helpers ──────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _tasksCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('daily_tasks');

  DocumentReference<Map<String, dynamic>> _taskDoc(String uid, String taskId) =>
      _tasksCol(uid).doc(taskId);

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  // ── Read ────────────────────────────────────────────────────────────────

  Stream<List<DailyTaskModel>> watchTodayTasks(String uid, {String? date}) {
    final todayKey = date ?? _dateKey(DateTime.now());
    return _tasksCol(uid)
        .where('date', isEqualTo: todayKey)
        .snapshots()
        .map(
          (qs) =>
              qs.docs.map((doc) => DailyTaskModel.fromFirestore(doc)).toList(),
        );
  }

  Future<List<DailyTaskModel>> getTodayTasks(String uid, {String? date}) async {
    final todayKey = date ?? _dateKey(DateTime.now());
    final snapshot =
        await _tasksCol(uid).where('date', isEqualTo: todayKey).get();
    return snapshot.docs
        .map((doc) => DailyTaskModel.fromFirestore(doc))
        .toList();
  }

  // ── Write ───────────────────────────────────────────────────────────────

  Future<void> saveTasks(String uid, List<DailyTaskModel> tasks) async {
    if (tasks.isEmpty) return;
    final batch = _firestore.batch();
    for (final task in tasks) {
      final ref = _taskDoc(uid, task.taskId);
      batch.set(ref, task.toFirestore());
    }
    await batch.commit();
  }

  Future<List<DailyTaskModel>> ensureTodayTasksExist({
    required String uid,
    required List<DailyTaskModel> tasks,
  }) async {
    final todayKey = _dateKey(DateTime.now());

    return _firestore.runTransaction<List<DailyTaskModel>>((transaction) async {
      final querySnapshot = await _tasksCol(uid)
          .where('date', isEqualTo: todayKey)
          .limit(5)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs
            .map((doc) => DailyTaskModel.fromFirestore(doc))
            .toList();
      }

      final batchTasks = tasks.take(5).toList();
      for (final task in batchTasks) {
        transaction.set(_taskDoc(uid, task.taskId), task.toFirestore());
      }
      return batchTasks;
    });
  }

  /// Marks a task complete/incomplete and — on first-time completion only —
  /// stamps [xpEverAwarded] = true on the task document.
  ///
  /// XP is NOT deducted here when unchecking; that is handled separately
  /// by [awardXpToUser] being called only when [xpEverAwarded] is still false.
  Future<void> markCompleted({
    required String uid,
    required String taskId,
    required bool completed,
    bool awardXp = false,
  }) async {
    final updates = <String, dynamic>{
      'completed': completed,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Stamp xpEverAwarded only on first-time completion, never remove it.
    if (awardXp) {
      updates['xpEverAwarded'] = true;
    }

    await _taskDoc(uid, taskId).update(updates);
  }

  /// Awards [xpAmount] XP to the user's Firestore document atomically.
  ///
  /// Uses [FieldValue.increment] so concurrent writes don't race.
  /// After crediting XP, checks if the new total crosses the level threshold
  /// (`level * 100`) and — if so — increments the level and resets XP to the
  /// remainder, keeping the progress bar meaningful.
  ///
  /// Returns the amount of XP actually awarded (same as [xpAmount]).
  Future<int> awardXpToUser({
    required String uid,
    required int xpAmount,
  }) async {
    if (xpAmount <= 0) return 0;

    final userRef = _userDoc(uid);

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(userRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      final currentXp = (data['xp'] as num?)?.toInt() ?? 0;
      final currentLevel = (data['level'] as num?)?.toInt() ?? 1;

      final newXp = currentXp + xpAmount;
      final xpGoal = currentLevel * 100;

      if (newXp >= xpGoal) {
        // Level up — carry over remainder XP.
        transaction.update(userRef, {
          'xp': newXp - xpGoal,
          'level': currentLevel + 1,
        });
      } else {
        transaction.update(userRef, {'xp': newXp});
      }
    });

    return xpAmount;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
