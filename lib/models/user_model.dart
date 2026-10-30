import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the live user document stored at `users/{uid}` in Firestore.
class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.level,
    required this.xp,
    required this.badges,
  });

  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final int level;
  final int xp;
  final List<String> badges;

  /// XP required to reach the next level.
  ///
  /// Linear formula: level 1 needs 100 XP, level 2 needs 200 XP, etc.
  int get xpGoal => level * 100;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? {};
    return UserModel(
      uid: snap.id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      avatarUrl: (data['avatarUrl'] as String?) ?? '',
      level: (data['level'] as num?)?.toInt() ?? 1,
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      badges: List<String>.from((data['badges'] as List?) ?? []),
    );
  }
}
