import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'auth_provider.dart';

/// Exposes a singleton [FirebaseFirestore] instance.
final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

/// Listens to the Firestore document `users/{currentUserId}` in realtime
/// and maps it to [UserModel].
///
/// Emits `null` when no user is signed in or the document does not exist.
final userDocProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);

      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('users')
          .doc(user.uid)
          .withConverter<UserModel>(
            fromFirestore: (snapshot, _) => UserModel.fromFirestore(snapshot),
            toFirestore: (snapshot, _) => {},
          )
          .snapshots()
          .map((snap) => snap.exists ? snap.data() : null);
    },
    loading: () => Stream.value(null),
    error: (error, stackTrace) {
      return Stream.value(null);
    },
  );
});
