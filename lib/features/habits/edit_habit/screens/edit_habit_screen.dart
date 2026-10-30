import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_ui_tokens.dart';
import '../../../../models/habit_model.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../providers/habits_provider.dart';
import '../../add_habit/widgets/category_chip.dart';

class EditHabitScreen extends ConsumerStatefulWidget {
  const EditHabitScreen({super.key, required this.habit});

  /// The existing habit to pre-fill and update.
  final HabitModel habit;

  @override
  ConsumerState<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends ConsumerState<EditHabitScreen> {
  late final TextEditingController _nameController;
  final _nameFocusNode = FocusNode();
  final _scrollController = ScrollController();

  late String _selectedCategory;
  late String _selectedFrequency;
  late List<int> _selectedDays;
  late String _selectedTime;
  late HabitPeriod _selectedPeriod;
  late GoalType _selectedGoalType;
  late Color _selectedColor;
  late IconData _selectedIcon;
  bool _isSaving = false;

  static const List<_CategoryOption> _categories = [
    _CategoryOption('Health', Icons.fitness_center, AppColors.primary),
    _CategoryOption('Work', Icons.work, AppColors.secondary),
    _CategoryOption('Personal', Icons.psychology, AppColors.tertiary),
    _CategoryOption('Growth', Icons.trending_up, AppColors.primary),
    _CategoryOption('Creative', Icons.palette, AppColors.secondary),
    _CategoryOption('Social', Icons.groups, AppColors.tertiary),
  ];

  static const List<String> _frequencies = ['Daily', 'Weekly', 'Custom'];

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const List<String> _dayFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<_GoalOption> _goalOptions = [
    _GoalOption(
      type: GoalType.simpleCheck,
      icon: Icons.done_all,
      label: 'Simple Check',
      subtitle: 'Binary done / not done',
    ),
    _GoalOption(
      type: GoalType.counter,
      icon: Icons.add_circle_outline,
      label: 'Counter',
      subtitle: 'Hit a numeric target',
    ),
    _GoalOption(
      type: GoalType.duration,
      icon: Icons.timer_outlined,
      label: 'Duration',
      subtitle: 'Spend a set amount of time',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill all fields from the existing habit.
    final h = widget.habit;
    _nameController = TextEditingController(text: h.name);
    _selectedCategory = h.category;
    _selectedFrequency = h.frequency;
    _selectedDays = List<int>.from(h.selectedDays);
    _selectedTime = h.reminderTime;
    _selectedPeriod = h.period;
    _selectedGoalType = h.goalType;
    _selectedColor = h.accentColor;
    _selectedIcon = h.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Logic
  // ---------------------------------------------------------------------------

  void _onFrequencyChanged(String frequency) {
    setState(() {
      _selectedFrequency = frequency;
      if (frequency == 'Daily') {
        _selectedDays = [0, 1, 2, 3, 4, 5, 6];
      } else if (frequency == 'Weekly') {
        if (_selectedDays.isEmpty) _selectedDays = [0];
      } else {
        if (_selectedDays.isEmpty) _selectedDays = [0, 1, 2, 3, 4];
      }
    });
  }

  void _toggleDay(int index) {
    if (_selectedFrequency == 'Daily') return;
    setState(() {
      if (_selectedDays.contains(index)) {
        if (_selectedDays.length > 1) _selectedDays.remove(index);
      } else {
        _selectedDays.add(index);
        _selectedDays.sort();
      }
    });
  }

  void _clearFocusedFieldAndRestoreScroll([double? scrollOffset]) {
    final effectiveOffset =
        scrollOffset ??
        (_scrollController.hasClients ? _scrollController.offset : 0.0);

    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          effectiveOffset.clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
        );
      }
    });
  }

  Future<void> _pickTime() async {
    final scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    _clearFocusedFieldAndRestoreScroll(scrollOffset);

    final parts = _selectedTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(data: Theme.of(context), child: child!),
    );

    if (!mounted) return;

    _clearFocusedFieldAndRestoreScroll(scrollOffset);

    if (picked != null) {
      setState(() {
        _selectedTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveHabit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Build updated habit preserving id, streak, createdAt, and isCompleted.
    final updated = widget.habit.copyWith(
      name: name,
      category: _selectedCategory,
      frequency: _selectedFrequency,
      selectedDays: List<int>.from(_selectedDays),
      reminderTime: _selectedTime,
      goalType: _selectedGoalType,
      period: _selectedPeriod,
      accentColorValue: _selectedColor.toARGB32(),
      iconCodePoint: _selectedIcon.codePoint,
    );

    final success = await ref
        .read(habitsActionsProvider.notifier)
        .updateHabit(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) context.pop();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    ref.listen<AsyncValue<void>>(habitsActionsProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString()), backgroundColor: cs.error),
            );
          }
        },
      );
    });

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppHeader(
        title: 'Edit Habit',
        onBackTap: () => context.pop(),
        backEnabled: !_isSaving,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppUiTokens.screenPadding,
            8,
            AppUiTokens.screenPadding,
            120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Habit Name ────────────────────────────────────────────────
              _sectionLabel(cs, 'Habit Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                enabled: !_isSaving,
                style: AppTextStyles.bodyLg.copyWith(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'e.g., Morning Meditation',
                  hintStyle: AppTextStyles.bodyLg.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                  suffixIcon: Icon(Icons.edit_note, color: cs.primary),
                ),
              ),
              const SizedBox(height: 24),

              // ── Category ──────────────────────────────────────────────────
              _sectionLabel(cs, 'Category'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat.label;
                  return CategoryChip(
                    label: cat.label,
                    icon: cat.icon,
                    accentColor: cat.color,
                    selected: selected,
                    onTap: _isSaving
                        ? null
                        : () => setState(() {
                            _selectedCategory = cat.label;
                            _selectedColor = cat.color;
                            _selectedIcon = cat.icon;
                          }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Time of Day ─────────────────────────────────────────────
              _sectionLabel(cs, 'Time of Day'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _periodChip(cs, 'Morning', HabitPeriod.morning),
                  _periodChip(cs, 'Evening', HabitPeriod.evening),
                  _periodChip(cs, 'Night', HabitPeriod.night),
                ],
              ),
              const SizedBox(height: 24),

              // ── Frequency ─────────────────────────────────────────────────
              _sectionLabel(cs, 'Frequency'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _frequencies.map((freq) {
                  final selected = _selectedFrequency == freq;
                  return GestureDetector(
                    onTap: _isSaving ? null : () => _onFrequencyChanged(freq),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primaryContainer
                            : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected ? cs.primary : cs.outlineVariant,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        freq,
                        style: AppTextStyles.labelMd.copyWith(
                          color: selected
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // ── Day-of-week picker ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(
                    AppUiTokens.cardRadiusMedium,
                  ),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(7, (i) {
                        final isSelected = _selectedDays.contains(i);
                        final isLocked = _selectedFrequency == 'Daily';
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: GestureDetector(
                              onTap: isLocked || _isSaving
                                  ? null
                                  : () => _toggleDay(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cs.primaryContainer
                                      : cs.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(999),
                                  border: isSelected
                                      ? Border.all(
                                          color: cs.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                        )
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _dayLabels[i],
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: isSelected
                                        ? cs.onPrimaryContainer
                                        : cs.onSurfaceVariant,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    if (_selectedFrequency != 'Daily') ...[
                      const SizedBox(height: 10),
                      Text(
                        _buildDaySummary(),
                        style: AppTextStyles.labelSm.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Reminder Time ─────────────────────────────────────────────
              _sectionLabel(cs, 'Reminder Time'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isSaving ? null : _pickTime,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.schedule,
                          color: cs.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDisplayTime(_selectedTime),
                              style: AppTextStyles.headlineMd.copyWith(
                                color: cs.onSurface,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to change',
                              style: AppTextStyles.labelSm.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: cs.onSurfaceVariant,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Goal Type ─────────────────────────────────────────────────
              _sectionLabel(cs, 'Goal Type'),
              const SizedBox(height: 10),
              Column(
                children: _goalOptions.map((opt) {
                  final selected = _selectedGoalType == opt.type;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: _isSaving
                          ? null
                          : () => setState(() => _selectedGoalType = opt.type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primaryContainer.withValues(alpha: 0.18)
                              : cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? cs.primary : cs.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: selected
                                    ? cs.primary.withValues(alpha: 0.15)
                                    : cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                opt.icon,
                                color: selected
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt.label,
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: selected
                                          ? cs.onSurface
                                          : cs.onSurfaceVariant,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    opt.subtitle,
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle,
                                color: cs.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppUiTokens.screenPadding,
          0,
          AppUiTokens.screenPadding,
          24,
        ),
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveHabit,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            disabledBackgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusMedium),
            ),
          ),
          icon: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onPrimaryContainer,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(
            _isSaving ? 'Saving…' : 'Save Changes',
            style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _sectionLabel(ColorScheme cs, String label) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.labelMd.copyWith(color: cs.onSurfaceVariant),
    );
  }

  String _formatDisplayTime(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    final tod = TimeOfDay(hour: hour, minute: minute);
    final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final m = minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Widget _periodChip(ColorScheme cs, String label, HabitPeriod period) {
    final selected = _selectedPeriod == period;
    return GestureDetector(
      onTap: _isSaving ? null : () => setState(() => _selectedPeriod = period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _buildDaySummary() {
    if (_selectedDays.isEmpty) return 'No days selected';
    if (_selectedDays.length == 7) return 'Every day';
    return _selectedDays.map((i) => _dayFull[i]).join(', ');
  }
}

// ---------------------------------------------------------------------------
// Private data classes
// ---------------------------------------------------------------------------

class _CategoryOption {
  const _CategoryOption(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class _GoalOption {
  const _GoalOption({
    required this.type,
    required this.icon,
    required this.label,
    required this.subtitle,
  });
  final GoalType type;
  final IconData icon;
  final String label;
  final String subtitle;
}
