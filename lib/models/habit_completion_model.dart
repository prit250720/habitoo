import 'package:cloud_firestore/cloud_firestore.dart';

/// Records historical completion data for reporting purposes.
/// Stored at: `users/{uid}/habits/{habitId}/completionHistory/{dateKey}`
class HabitCompletionModel {
  const HabitCompletionModel({
    this.habitId,
    required this.dateKey, // 'YYYY-MM-DD' format
    required this.wasCompleted,
    required this.completedAt, // When the user marked/auto-marked as complete
    required this.autoCompleted, // Whether it was auto-completed by system
    this.alarmClosedAt, // When alarm was closed (triggers auto-complete)
  });

  final String? habitId;
  final String dateKey;
  final bool wasCompleted;
  final DateTime completedAt;
  final bool autoCompleted;
  final DateTime? alarmClosedAt;

  factory HabitCompletionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? {};

    return HabitCompletionModel(
      habitId: d['habitId'] as String?,
      dateKey: (d['dateKey'] as String?) ?? snap.id,
      wasCompleted: (d['wasCompleted'] as bool?) ?? false,
      completedAt: (d['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      autoCompleted: (d['autoCompleted'] as bool?) ?? false,
      alarmClosedAt: (d['alarmClosedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'wasCompleted': wasCompleted,
      'completedAt': Timestamp.fromDate(completedAt),
      'autoCompleted': autoCompleted,
      'alarmClosedAt': alarmClosedAt != null
          ? Timestamp.fromDate(alarmClosedAt!)
          : null,
    };
  }
}
