import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// True when the user has asked the OS to reduce motion.
bool reduceMotion(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Counts up (or down) to [value] whenever it changes. Uses tabular figures so width never jitters.
class AnimatedNumber extends StatelessWidget {
  final double value;
  final int decimals;
  final TextStyle? style;
  final String suffix;
  final Duration duration;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.decimals = 0,
    this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final s = displayFont(base).copyWith(fontFeatures: tabularFigures);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: reduceMotion(context) ? Duration.zero : duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.toStringAsFixed(decimals)}$suffix', style: s),
    );
  }
}

/// A card that tilts toward the mouse on web/desktop (max [maxTiltDegrees]) with a soft moving highlight.
/// Touch devices never send hover events, so they get a flat, still card.
class TiltCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double maxTiltDegrees;
  final double radius;
  final bool selected;
  final Color? selectedColor;
  final String? semanticLabel;

  const TiltCard({
    super.key,
    required this.child,
    this.onTap,
    this.maxTiltDegrees = 6,
    this.radius = Radii.primary,
    this.selected = false,
    this.selectedColor,
    this.semanticLabel,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  Offset _pointer = Offset.zero; // -1..1 in both axes
  bool _hovering = false;
  bool _focused = false;

  void _onHover(PointerHoverEvent e, Size size) {
    if (size.width == 0 || size.height == 0) return;
    setState(() {
      _hovering = true;
      _pointer = Offset(
        (e.localPosition.dx / size.width) * 2 - 1,
        (e.localPosition.dy / size.height) * 2 - 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rad = widget.maxTiltDegrees * 3.1415926535 / 180;
    final active = _hovering && !still;
    final matrix = Matrix4.identity()..setEntry(3, 2, 0.0012);
    if (active) {
      matrix
        ..rotateX(-_pointer.dy * rad)
        ..rotateY(_pointer.dx * rad);
    }
    final accent = widget.selectedColor ?? PrismColors.fit;
    final borderColor = _focused
        ? accent
        : widget.selected
            ? accent.fade(0.7)
            : cs.onSurface.fade(_hovering ? 0.16 : 0.08);

    return MouseRegion(
        cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        onHover: (e) {
          final size = context.size;
          if (size != null) _onHover(e, size);
        },
        onExit: (_) => setState(() {
          _hovering = false;
          _pointer = Offset.zero;
        }),
        child: AnimatedContainer(
          duration: still ? Duration.zero : const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: matrix,
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: borderColor, width: _focused ? 2 : 1),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark
                  ? [PrismColors.surfaceDarkHigh, PrismColors.surfaceDark]
                  : [Colors.white, const Color(0xFFF8F9FD)],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: Stack(children: [
              if (widget.selected)
                Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 3, color: accent)),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: widget.onTap,
                  onFocusChange: (f) => setState(() => _focused = f),
                  child: Semantics(label: widget.semanticLabel, button: widget.onTap != null, child: widget.child),
                ),
              ),
              if (active)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(_pointer.dx, _pointer.dy),
                          radius: 0.9,
                          colors: [Colors.white.fade(dark ? 0.07 : 0.35), Colors.white.fade(0)],
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      );
  }
}

/// Grey placeholder block shown while data loads.
class Skeleton extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;
  const Skeleton({super.key, this.height = 16, this.width, this.radius = Radii.nested});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: ink.fade(0.06 + 0.06 * _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// A page-shaped skeleton used while seed data loads.
class PageSkeleton extends StatelessWidget {
  const PageSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Layout.maxReading),
        child: const Padding(
          padding: EdgeInsets.all(Spacing.xl),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Skeleton(height: 180, radius: Radii.primary),
            SizedBox(height: Spacing.xl),
            Skeleton(height: 28, width: 320),
            SizedBox(height: Spacing.md),
            Skeleton(height: 14),
            SizedBox(height: Spacing.sm),
            Skeleton(height: 14, width: 420),
          ]),
        ),
      ),
    );
  }
}

/// Fades and rises into view the first time it scrolls onto the screen.
/// Shown immediately when the OS asks for reduced motion.
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const Reveal({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  bool _shown = false;
  bool _triggered = false;
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _shown = true;
      _triggered = true;
      return;
    }
    _position?.removeListener(_check);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_triggered || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top < MediaQuery.sizeOf(context).height * 0.92) {
      _triggered = true;
      _position?.removeListener(_check);
      Future<void>.delayed(widget.delay, () {
        if (mounted) setState(() => _shown = true);
      });
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const d = Duration(milliseconds: 450);
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: d,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : const Offset(0, 0.08),
        duration: d,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
