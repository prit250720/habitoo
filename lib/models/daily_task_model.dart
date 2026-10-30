import 'package:cloud_firestore/cloud_firestore.dart';

/// A personalized daily task stored at
/// users/{uid}/daily_tasks/{taskId} in Firestore.
class DailyTaskModel {
  const DailyTaskModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.title,
    required this.description,
    required this.habitId,
    required this.category,
    required this.date,
    required this.xp,
    required this.completed,
    this.xpEverAwarded = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String taskId;
  final String userId;
  final String title;
  final String description;
  final String? habitId;
  final String category;
  final String date;
  final int xp;
  final bool completed;

  /// True once XP has been credited to the user's profile for this task.
  /// Never reset to false — prevents double-awarding on re-completion.
  final bool xpEverAwarded;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DailyTaskModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? {};
    return DailyTaskModel(
      id: snap.id,
      taskId: (data['taskId'] as String?) ?? snap.id,
      userId: (data['userId'] as String?) ?? '',
      title: (data['title'] as String?) ?? 'Daily focus task',
      description: (data['description'] as String?) ?? '',
      habitId: data['habitId'] as String?,
      category: (data['category'] as String?) ?? 'Health',
      date: (data['date'] as String?) ?? '',
      xp: (data['xp'] as num?)?.toInt() ?? 1,
      completed: (data['completed'] as bool?) ?? false,
      xpEverAwarded: (data['xpEverAwarded'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'userId': userId,
      'title': title,
      'description': description,
      'habitId': habitId,
      'category': category,
      'date': date,
      'xp': xp,
      'completed': completed,
      'xpEverAwarded': xpEverAwarded,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  DailyTaskModel copyWith({
    String? id,
    String? taskId,
    String? userId,
    String? title,
    String? description,
    String? habitId,
    String? category,
    String? date,
    int? xp,
    bool? completed,
    bool? xpEverAwarded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyTaskModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      habitId: habitId ?? this.habitId,
      category: category ?? this.category,
      date: date ?? this.date,
      xp: xp ?? this.xp,
      completed: completed ?? this.completed,
      xpEverAwarded: xpEverAwarded ?? this.xpEverAwarded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
