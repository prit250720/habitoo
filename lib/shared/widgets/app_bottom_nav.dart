import 'package:flutter/material.dart';

// ── Tab definitions ──────────────────────────────────────────────────────────

const _kTabs = [
  _TabData(
    icon: Icons.today_outlined,
    selectedIcon: Icons.today_rounded,
    label: 'Today',
  ),
  _TabData(
    icon: Icons.checklist_rounded,
    selectedIcon: Icons.checklist_rounded,
    label: 'Habits',
  ),
  _TabData(
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
    label: 'Stats',
  ),
  _TabData(
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    label: 'Profile',
  ),
];

class _TabData {
  const _TabData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

// ── Widget ───────────────────────────────────────────────────────────────────

class AppBottomNav extends StatefulWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleX;
  late Animation<double> _arcY;

  // 4 equal slots → centers at 1/8, 3/8, 5/8, 7/8 of pill width (0..1)
  static const _slots = [0.125, 0.375, 0.625, 0.875];

  double _fromX = 0.125; // tracks last animated-to position

  @override
  void initState() {
    super.initState();
    _fromX = _slots[widget.currentIndex];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _buildAnimations(from: _fromX, to: _fromX);
  }

  void _buildAnimations({required double from, required double to}) {
    _circleX = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    // Slight arc dip in the middle of travel for a "rolling" feel
    _arcY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fromX = to;
  }

  @override
  void didUpdateWidget(AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final double from = _fromX;
      final double to = _slots[widget.currentIndex];
      _buildAnimations(from: from, to: to);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 8 + bottomInset),
      child: SizedBox(
        height: 68,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pillWidth = constraints.maxWidth;
            const circleD = 46.0; // diameter of sliding indicator circle
            const circleR = circleD / 2;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Pill background ────────────────────────────────────
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: cs.onSurface.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Tab items ─────────────────────────────────────────
                Positioned.fill(
                  child: Row(
                    children: List.generate(_kTabs.length, (i) {
                      return Expanded(
                        child: _NavItem(
                          data: _kTabs[i],
                          selected: widget.currentIndex == i,
                          onTap: () => widget.onDestinationSelected(i),
                        ),
                      );
                    }),
                  ),
                ),

                // ── Sliding green circle ───────────────────────────────
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final cx = _circleX.value * pillWidth;
                    final cy = (68 / 2) - circleR - 6 + _arcY.value;

                    return Positioned(
                      left: cx - circleR,
                      top: cy,
                      child: Material(
                        color: cs.primary,
                        shape: const CircleBorder(),
                        elevation: 4,
                        shadowColor: cs.primary.withValues(alpha: 0.4),
                        child: SizedBox(
                          width: circleD,
                          height: circleD,
                          child: Icon(
                            _kTabs[widget.currentIndex].selectedIcon,
                            color: cs.onPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Nav item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _TabData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon + label both hidden when selected (circle covers the slot)
              AnimatedOpacity(
                opacity: selected ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(data.icon, color: cs.onSurfaceVariant, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
