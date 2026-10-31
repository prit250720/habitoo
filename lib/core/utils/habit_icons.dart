import 'package:flutter/material.dart';

/// A catalogue of every [IconData] used for habits in the app.
///
/// Annotated with [@staticIconProvider] so Flutter's release-build icon-font
/// tree-shaker knows the exact set of glyphs to keep — even though individual
/// habits store the code-point as an integer in Firestore and reconstruct the
/// [IconData] at runtime.
///
/// **Rules for this file:**
///   1. Every selectable habit [IconData] MUST be declared here as `static const`.
///   2. When adding a new icon to the add/edit-habit screen, add it here first;
///      otherwise the glyph will be stripped from the release APK.
@staticIconProvider
abstract final class HabitIcons {
  // ── Category icons (appear in add/edit-habit category chips) ─────────────
  static const IconData health = Icons.fitness_center; // 0xe28d
  static const IconData work = Icons.work; // 0xe6f2
  static const IconData personal = Icons.psychology; // 0xe4ef
  static const IconData growth = Icons.trending_up; // 0xe67f
  static const IconData creative = Icons.palette; // 0xe46b
  static const IconData social = Icons.groups; // 0xe2ee

  // ── Fallback / default ────────────────────────────────────────────────────
  static const IconData fallback = Icons.fitness_center;

  // ── Lookup map: code-point → IconData ─────────────────────────────────────
  /// Converts a Firestore-persisted code-point back to an [IconData].
  ///
  /// Returns [fallback] for any unknown code-point so the UI never breaks
  /// on old or unrecognised data.
  static IconData fromCodePoint(int codePoint) =>
      _byCodePoint[codePoint] ?? fallback;

  static const Map<int, IconData> _byCodePoint = {
    0xe28d: health, // fitness_center
    0xe6f2: work, // work
    0xe4ef: personal, // psychology
    0xe67f: growth, // trending_up
    0xe46b: creative, // palette
    0xe2ee: social, // groups
  };
}
