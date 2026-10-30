import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides a singleton [AuthRepository] instance to the widget tree.
///
/// Passes the database URL explicitly so [FirebaseDatabase] always connects
/// to the correct RTDB instance regardless of SDK default-app resolution.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    database: FirebaseDatabase.instanceFor(
      app: FirebaseAuth.instance.app,
      databaseURL: 'https://habitoo-fb165-default-rtdb.firebaseio.com',
    ),
  );
});

// ---------------------------------------------------------------------------
// Auth state stream
// ---------------------------------------------------------------------------

/// Exposes [AuthRepository.authStateChanges] as a [StreamProvider].
///
/// Consumers watch this to reactively respond to sign-in / sign-out events
/// without managing a [StreamSubscription] themselves.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// ---------------------------------------------------------------------------
// Auth controller
// ---------------------------------------------------------------------------

/// Manages sign-up, sign-in, and sign-out operations.
///
/// State is [AsyncValue<void>]:
/// - [AsyncData] — idle / last operation succeeded.
/// - [AsyncLoading] — an operation is in flight.
/// - [AsyncError] — the last operation failed; the error is a human-readable
///   [String] thrown by [AuthRepository].
class AuthController extends Notifier<AsyncValue<void>> {
  late AuthRepository _repository;

  @override
  AsyncValue<void> build() {
    // Synchronous build — no async work here so state is never AsyncLoading
    // from the build itself. Watching authStateChangesProvider here would
    // cause build() to re-run on every auth event, resetting state to
    // AsyncLoading. Instead we only initialise the repository.
    _repository = ref.watch(authRepositoryProvider);
    return const AsyncData(null);
  }

  /// Creates a new account, writes to Firestore, and writes to Realtime DB.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signUp(email: email, password: password, name: name),
    );
  }

  /// Signs in an existing user with email and password.
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signIn(email: email, password: password),
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.signOut);
  }
}

/// The provider for [AuthController].
///
/// Usage:
/// ```dart
/// // Trigger an action
/// ref.read(authControllerProvider.notifier).signIn(email: ..., password: ...);
///
/// // React to loading / error state
/// final authState = ref.watch(authControllerProvider);
/// authState.whenOrNull(loading: () => ..., error: (e, _) => ...);
/// ```
final authControllerProvider = NotifierProvider<AuthController, AsyncValue<void>>(
  AuthController.new,
);
