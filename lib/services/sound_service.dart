import 'package:audioplayers/audioplayers.dart';

/// Lightweight service for playing short UI sounds.
///
/// Uses a single [AudioPlayer] instance. Calling [playTaskComplete] while a
/// sound is already playing will restart it from the beginning, so rapid
/// taps never stack up multiple simultaneous playbacks.
class SoundService {
  SoundService._();

  static final AudioPlayer _player = AudioPlayer();

  /// Play the satisfying "task complete" chime.
  ///
  /// Safe to call fire-and-forget — errors are swallowed so a missing asset
  /// or audio focus issue never crashes the UI.
  static Future<void> playTaskComplete() async {
    try {
      // Stop any currently playing sound first so rapid taps don't stack.
      await _player.stop();
      await _player.play(
        AssetSource('audio/task_complete.mp3'),
        volume: 1.0,
      );
    } catch (_) {
      // Audio failure should never affect the rest of the app.
    }
  }

  /// Release the underlying audio player — call this when the app is
  /// permanently shutting down (optional, but good practice).
  static Future<void> dispose() async {
    await _player.dispose();
  }
}
