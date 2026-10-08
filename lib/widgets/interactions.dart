import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import 'motion.dart';

// ---------------------------------------------------------------------------
// Custom cursor (web desktop only)
// ---------------------------------------------------------------------------

/// App-wide cursor state. Only mouse hover events update it, so touch devices never show the ring.
class CursorState extends ChangeNotifier {
  Offset? position;
  String? label;

  void move(Offset p) {
    position = p;
    notifyListeners();
  }

  void hide() {
    position = null;
    label = null;
    notifyListeners();
  }

  void setLabel(String? l) {
    if (l == label) return;
    label = l;
    notifyListeners();
  }
}

final cursorState = CursorState();

/// Draws a small dot plus a trailing ring that follows the mouse. The ring grows and shows a word
/// over widgets wrapped in [CursorTarget]. The normal system cursor stays visible for accessibility.
class CursorFollower extends StatelessWidget {
  final Widget child;
  const CursorFollower({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    return MouseRegion(
      opaque: false,
      onHover: (e) => cursorState.move(e.position),
      onExit: (_) => cursorState.hide(),
      child: Stack(children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Material(
              type: MaterialType.transparency,
              child: ListenableBuilder(
                listenable: cursorState,
                builder: (context, _) {
                  final p = cursorState.position;
                  if (p == null) return const SizedBox.shrink();
                  final label = cursorState.label;
                  final ring = label == null ? 34.0 : 78.0;
                  final ink = Theme.of(context).colorScheme.onSurface;
                  return Stack(children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      left: p.dx - ring / 2,
                      top: p.dy - ring / 2,
                      width: ring,
                      height: ring,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: label == null ? Colors.transparent : PrismColors.fit.fade(0.9),
                          border: Border.all(color: label == null ? ink.fade(0.5) : PrismColors.fit, width: 1.2),
                        ),
                        child: label == null
                            ? null
                            : Text(label,
                                style: displayFont(Theme.of(context).textTheme.labelMedium ?? const TextStyle())
                                    .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (label == null)
                      Positioned(
                        left: p.dx - 3,
                        top: p.dy - 3,
                        width: 6,
                        height: 6,
                        child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: ink.fade(0.9))),
                      ),
                  ]);
                },
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Tells the cursor ring which word to show while the mouse is over [child] ("Open", "Start", "Drag"...).
class CursorTarget extends StatelessWidget {
  final String label;
  final Widget child;
  const CursorTarget({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => MouseRegion(
        opaque: false,
        onEnter: (_) => cursorState.setLabel(label),
        onExit: (_) => cursorState.setLabel(null),
        child: child,
      );
}

// ---------------------------------------------------------------------------
// Hover interactions
// ---------------------------------------------------------------------------

/// Pulls its child slightly toward the mouse and springs back when the mouse leaves.
class MagneticButton extends StatefulWidget {
  final Widget child;
  final double strength;
  const MagneticButton({super.key, required this.child, this.strength = 0.3});

  @override
  State<MagneticButton> createState() => _MagneticButtonState();
}

class _MagneticButtonState extends State<MagneticButton> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return MouseRegion(
      opaque: false,
      onHover: (e) {
        final size = context.size;
        if (size == null) return;
        final d = (e.localPosition - Offset(size.width / 2, size.height / 2)) * widget.strength;
        setState(() => _offset = Offset(d.dx.clamp(-10.0, 10.0), d.dy.clamp(-8.0, 8.0)));
      },
      onExit: (_) => setState(() => _offset = Offset.zero),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(end: _offset),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, o, child) => Transform.translate(offset: o, child: child),
        child: widget.child,
      ),
    );
  }
}

/// Text link whose underline draws in from the left on hover or keyboard focus, with an arrow that nudges right.
class HoverLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final TextStyle? style;
  final bool arrow;
  const HoverLink({super.key, required this.label, required this.onTap, this.style, this.arrow = true});

  @override
  State<HoverLink> createState() => _HoverLinkState();
}

class _HoverLinkState extends State<HoverLink> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    final style = widget.style ?? Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    final color = style.color ?? Theme.of(context).colorScheme.onSurface;
    final active = _hover || _focus;
    final d = still ? Duration.zero : const Duration(milliseconds: 260);
    return Semantics(
      link: true,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (h) => setState(() => _hover = h),
        onFocusChange: (f) => setState(() => _focus = f),
        borderRadius: BorderRadius.circular(6),
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm, horizontal: 2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            IntrinsicWidth(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(widget.label, style: style),
                const SizedBox(height: 3),
                SizedBox(
                  height: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: d,
                      curve: Curves.easeOutCubic,
                      widthFactor: active ? 1 : 0.0001,
                      child: Container(height: 2, color: color),
                    ),
                  ),
                ),
              ]),
            ),
            if (widget.arrow)
              AnimatedSlide(
                duration: d,
                curve: Curves.easeOutCubic,
                offset: active ? const Offset(0.25, 0) : Offset.zero,
                child: Padding(
                  padding: const EdgeInsets.only(left: Spacing.sm, bottom: 5),
                  child: Icon(Icons.arrow_forward, size: (style.fontSize ?? 16) * 1.05, color: color),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Text reveals
// ---------------------------------------------------------------------------

/// Splits a heading into the lines it actually wraps to, then slides each line up from behind a clip.
class MaskedTextReveal extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration delay;
  const MaskedTextReveal({super.key, required this.text, required this.style, this.delay = Duration.zero});

  @override
  State<MaskedTextReveal> createState() => _MaskedTextRevealState();
}

class _MaskedTextRevealState extends State<MaskedTextReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _c.value = 1;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// The lines the text actually wraps to at [maxWidth].
  /// Each line is found by sampling the MIDDLE of that line: a point at a line's left edge can resolve
  /// to the end of the previous line (text affinity), which would repeat a line and drop the last one.
  List<String> _lines(double maxWidth, TextScaler scaler) {
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: maxWidth);
    final out = <String>[];
    var lastEnd = -1;
    var y = 0.0;
    for (final lm in tp.computeLineMetrics()) {
      final pos = tp.getPositionForOffset(Offset(lm.left + lm.width / 2, y + lm.height / 2));
      final range = tp.getLineBoundary(pos);
      if (range.start >= 0 && range.end > lastEnd && range.end <= widget.text.length) {
        final line = widget.text.substring(range.start, range.end).trim();
        if (line.isNotEmpty) out.add(line);
        lastEnd = range.end;
      }
      y += lm.height;
    }
    tp.dispose();
    // Safety net: if the split does not add back up to the original words, show the text as one block.
    final joined = out.join(' ').split(RegExp(r'\s+')).join(' ');
    final original = widget.text.trim().split(RegExp(r'\s+')).join(' ');
    return joined == original ? out : [widget.text];
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.text,
      header: true,
      child: ExcludeSemantics(
        child: LayoutBuilder(builder: (context, box) {
          final lines = _lines(box.maxWidth, MediaQuery.textScalerOf(context));
          return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < lines.length; i++)
              ClipRect(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, child) {
                    final begin = math.min<double>(i * 0.12, 0.6);
                    final t = Interval(begin, math.min<double>(begin + 0.4, 1.0), curve: Curves.easeOutCubic).transform(_c.value);
                    return FractionalTranslation(translation: Offset(0, 1 - t), child: child);
                  },
                  child: Text(lines[i], style: widget.style, maxLines: lines.length == 1 ? null : 1, softWrap: lines.length == 1),
                ),
              ),
          ]);
        }),
      ),
    );
  }
}

/// Reports where a widget sits on screen as the page scrolls. Shared by the scroll-driven widgets below.
mixin _ScrollWatcher<T extends StatefulWidget> on State<T> {
  ScrollPosition? _position;

  void onScrollChanged();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.removeListener(onScrollChanged);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(onScrollChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) onScrollChanged();
    });
  }

  @override
  void dispose() {
    _position?.removeListener(onScrollChanged);
    super.dispose();
  }

  /// Top of this widget relative to the top of the screen, or null before layout.
  double? get screenTop {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero).dy;
  }
}

/// Words fill from a muted colour to full colour as the paragraph scrolls through the screen.
class ScrollFillText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const ScrollFillText({super.key, required this.text, required this.style});

  @override
  State<ScrollFillText> createState() => _ScrollFillTextState();
}

class _ScrollFillTextState extends State<ScrollFillText> with _ScrollWatcher<ScrollFillText> {
  double _progress = 0;

  @override
  void onScrollChanged() {
    final top = screenTop;
    final box = context.findRenderObject() as RenderBox?;
    if (top == null || box == null) return;
    final h = MediaQuery.sizeOf(context).height;
    final p = ((h * 0.85 - top) / (h * 0.55 + box.size.height)).clamp(0.0, 1.0);
    if ((p - _progress).abs() > 0.004) setState(() => _progress = p);
  }

  @override
  Widget build(BuildContext context) {
    final full = widget.style.color ?? Theme.of(context).colorScheme.onSurface;
    final muted = full.fade(0.22);
    final p = reduceMotion(context) ? 1.0 : _progress;
    final words = widget.text.split(' ');
    return Text.rich(TextSpan(children: [
      for (var i = 0; i < words.length; i++)
        TextSpan(
          text: i < words.length - 1 ? '${words[i]} ' : words[i],
          style: widget.style.copyWith(color: Color.lerp(muted, full, (p * words.length - i).clamp(0.0, 1.0))),
        ),
    ]));
  }
}

/// Keeps its content fixed on screen while the page scrolls through [scrollLength] screen-heights,
/// and gives the builder a 0..1 progress value for scroll-driven storytelling.
class PinnedScrollSection extends StatefulWidget {
  final double scrollLength;
  final Widget Function(BuildContext context, double progress) builder;
  const PinnedScrollSection({super.key, this.scrollLength = 2.5, required this.builder});

  @override
  State<PinnedScrollSection> createState() => _PinnedScrollSectionState();
}

class _PinnedScrollSectionState extends State<PinnedScrollSection> with _ScrollWatcher<PinnedScrollSection> {
  double _offset = 0;
  double _progress = 0;

  @override
  void onScrollChanged() {
    final top = screenTop;
    if (top == null) return;
    final vh = MediaQuery.sizeOf(context).height;
    final travel = vh * widget.scrollLength - vh;
    final offset = (-top).clamp(0.0, math.max<double>(0.0, travel));
    final progress = travel <= 0 ? 1.0 : offset / travel;
    if ((offset - _offset).abs() > 0.5 || (progress - _progress).abs() > 0.002) {
      setState(() {
        _offset = offset;
        _progress = progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vh = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: vh * widget.scrollLength,
      child: Stack(children: [
        Positioned(left: 0, right: 0, top: _offset, height: vh, child: widget.builder(context, _progress)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Marquee
// ---------------------------------------------------------------------------

/// Seamless, endlessly scrolling row that slows down while the mouse is over it.
/// With reduced motion it stops and becomes a normal horizontally scrollable row.
class Marquee extends StatefulWidget {
  final List<Widget> children;
  final double speed; // pixels per second
  final double spacing;
  const Marquee({super.key, required this.children, this.speed = 45, this.spacing = Spacing.xxl});

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  double _speed = 0;
  bool _hover = false;
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = reduceMotion(context);
    if (_still) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    final target = _hover ? widget.speed * 0.2 : widget.speed;
    _speed += (target - _speed) * math.min<double>(1.0, dt * 4);
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final half = (pos.maxScrollExtent + pos.viewportDimension) / 2;
    if (half <= 0) return;
    var next = _controller.offset + _speed * dt;
    if (next >= half) next -= half;
    _controller.jumpTo(next.clamp(0.0, pos.maxScrollExtent));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final c in widget.children) Padding(padding: EdgeInsets.only(right: widget.spacing), child: c),
    ];
    return MouseRegion(
      opaque: false,
      onEnter: (_) => _hover = true,
      onExit: (_) => _hover = false,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: _still ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
        child: Row(children: [...items, ...items]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page transition
// ---------------------------------------------------------------------------

/// A spectrum-coloured curtain sweeps up the screen; the new page appears behind it halfway through.
Page<void> curtainPage(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 480),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final t = animation.value;
            final h = MediaQuery.sizeOf(context).height;
            final bg = Theme.of(context).scaffoldBackgroundColor; // curtain matches light or dark mode
            final y = (1 - 2 * Curves.easeInOutCubic.transform(t)) * h;
            return Stack(children: [
              Opacity(opacity: t < 0.5 ? 0 : 1, child: child),
              if (t > 0 && t < 1)
                Positioned(
                  left: 0,
                  right: 0,
                  top: y,
                  height: h,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [PrismColors.fit, PrismColors.roi, bg, bg],
                          stops: const [0, 0.08, 0.2, 1],
                        ),
                      ),
                    ),
                  ),
                ),
            ]);
          },
        );
      },
    );

