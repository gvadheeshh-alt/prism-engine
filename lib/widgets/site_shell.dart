import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';
import 'interactions.dart';
import 'motion.dart';

/// Large editorial heading size: 44px on phones up to 96px on wide screens.
TextStyle statementStyle(BuildContext context, {double max = 96, double min = 44, double factor = 0.075}) {
  final w = MediaQuery.sizeOf(context).width;
  final size = (w * factor).clamp(min, max);
  return displayFont(TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.03,
    letterSpacing: -size * 0.03,
    color: Theme.of(context).colorScheme.onSurface,
  ));
}

/// Body text for marketing pages: 16px on phones, 18px on desktop.
TextStyle leadStyle(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return (Theme.of(context).textTheme.bodyLarge ?? const TextStyle())
      .copyWith(fontSize: w > 900 ? 18 : 16, height: 1.6, color: Theme.of(context).colorScheme.onSurface.fade(0.78));
}

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width > 900;

/// A page section with generous, responsive whitespace and a capped content width.
class SiteSection extends StatelessWidget {
  final Widget child;
  final bool tight;
  final double maxWidth;
  const SiteSection({super.key, required this.child, this.tight = false, this.maxWidth = Layout.maxContent});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final v = tight ? (wide ? 64.0 : 40.0) : (wide ? 128.0 : 64.0);
    final h = wide ? 48.0 : 20.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: v),
      child: Center(
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page scaffold for marketing pages
// ---------------------------------------------------------------------------

/// Marketing page frame: header that hides on scroll down and returns on scroll up,
/// full-screen menu, scrolling content and the shared footer.
class SiteScaffold extends StatefulWidget {
  final List<Widget> sections;
  final bool footer;
  const SiteScaffold({super.key, required this.sections, this.footer = true});

  @override
  State<SiteScaffold> createState() => _SiteScaffoldState();
}

class _SiteScaffoldState extends State<SiteScaffold> {
  final _scroll = ScrollController();
  bool _hidden = false;
  bool _glass = false;
  bool _menu = false;
  double _last = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final off = _scroll.offset;
    final delta = off - _last;
    var hidden = _hidden;
    if (delta > 6 && off > 140) hidden = true;
    if (delta < -6 || off < 40) hidden = false;
    final glass = off > 40;
    _last = off;
    if (hidden != _hidden || glass != _glass) {
      setState(() {
        _hidden = hidden;
        _glass = glass;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scroll,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 80),
              ...widget.sections,
              if (widget.footer) const SiteFooter(),
            ]),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedSlide(
            duration: still ? Duration.zero : const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            offset: _hidden && !_menu ? const Offset(0, -1.2) : Offset.zero,
            child: _SiteHeader(glass: _glass, onMenu: () => setState(() => _menu = true)),
          ),
        ),
        if (_menu) Positioned.fill(child: FullScreenMenu(onClosed: () => setState(() => _menu = false))),
      ]),
    );
  }
}

class _Wordmark extends StatelessWidget {
  final double size;
  const _Wordmark({this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final c in PrismColors.spectrum)
        Container(width: size * 0.16, height: size * 0.8, margin: const EdgeInsets.only(right: 2), color: c),
      const SizedBox(width: Spacing.sm),
      Text('PRISM',
          style: displayFont(TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ))),
    ]);
  }
}

class _SiteHeader extends StatelessWidget {
  final bool glass;
  final VoidCallback onMenu;
  const _SiteHeader({required this.glass, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final wide = isWide(context);
    final bar = Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 16),
      decoration: BoxDecoration(
        color: glass ? (dark ? PrismColors.bgDark : PrismColors.bgLight).fade(0.78) : Colors.transparent,
        border: Border(bottom: BorderSide(color: glass ? cs.onSurface.fade(0.08) : Colors.transparent)),
      ),
      child: Row(children: [
        Semantics(
          label: 'PRISM home',
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.nested),
            onTap: () => context.go('/'),
            child: const Padding(padding: EdgeInsets.all(Spacing.sm), child: _Wordmark()),
          ),
        ),
        const Spacer(),
        MagneticButton(
          child: CursorTarget(
            label: 'Start',
            child: FilledButton(
              onPressed: () => context.push('/student'),
              child: Text(wide ? 'Start free' : 'Start'),
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        CursorTarget(
          label: 'Open',
          child: TextButton.icon(
            onPressed: onMenu,
            icon: const Icon(Icons.menu),
            label: const Text('Menu'),
            style: TextButton.styleFrom(foregroundColor: cs.onSurface, minimumSize: const Size(48, 48)),
          ),
        ),
      ]),
    );
    if (!glass) return bar;
    return ClipRect(
      child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: bar),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen menu
// ---------------------------------------------------------------------------

class _MenuLink {
  final String label, path;
  const _MenuLink(this.label, this.path);
}

const _menuLinks = [
  _MenuLink('Home', '/'),
  _MenuLink('How it works', '/how-it-works'),
  _MenuLink('Careers', '/careers'),
  _MenuLink('For parents', '/parents'),
  _MenuLink('For schools', '/schools'),
  _MenuLink('About', '/about'),
];

/// Opens with a top-down reveal; links rise in one after another. Esc closes it and
/// keyboard focus stays inside while it is open.
class FullScreenMenu extends StatefulWidget {
  final VoidCallback onClosed;
  const FullScreenMenu({super.key, required this.onClosed});

  @override
  State<FullScreenMenu> createState() => _FullScreenMenuState();
}

class _FullScreenMenuState extends State<FullScreenMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  int? _hovered;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _close([String? goTo]) async {
    if (reduceMotion(context)) {
      _c.value = 0;
    } else {
      await _c.reverse();
    }
    if (!mounted) return;
    final router = GoRouter.of(context);
    widget.onClosed();
    if (goTo != null) router.go(goTo);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final h = MediaQuery.sizeOf(context).height;
    final wide = isWide(context);
    final current = GoRouterState.of(context).uri.path;
    final linkStyle = statementStyle(context, max: 64, min: 34, factor: 0.05);

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => _close()},
      child: FocusScope(
        autofocus: true,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: Curves.easeInOutCubic.transform(_c.value),
              child: child,
            ),
          ),
          child: SizedBox(
            height: h,
            child: Material(
              color: dark ? PrismColors.bgDark : PrismColors.bgLight,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 20, vertical: Spacing.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      const _Wordmark(),
                      const Spacer(),
                      TextButton.icon(
                        autofocus: true,
                        onPressed: () => _close(),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: TextButton.styleFrom(foregroundColor: cs.onSurface, minimumSize: const Size(48, 48)),
                      ),
                    ]),
                    const Spacer(),
                    for (var i = 0; i < _menuLinks.length; i++)
                      ClipRect(
                        child: AnimatedBuilder(
                          animation: _c,
                          builder: (context, child) {
                            final start = 0.3 + i * 0.07;
                            final t = Interval(start.clamp(0.0, 0.9), (start + 0.35).clamp(0.0, 1.0), curve: Curves.easeOutCubic)
                                .transform(_c.value);
                            return FractionalTranslation(translation: Offset(0, 1 - t), child: child);
                          },
                          child: _MenuItem(
                            label: _menuLinks[i].label,
                            style: linkStyle,
                            current: current == _menuLinks[i].path,
                            dimmed: _hovered != null && _hovered != i,
                            onHover: (h) => setState(() => _hovered = h ? i : (_hovered == i ? null : _hovered)),
                            onTap: () => _close(_menuLinks[i].path),
                          ),
                        ),
                      ),
                    const Spacer(),
                    Wrap(
                      spacing: Spacing.md,
                      runSpacing: Spacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton(onPressed: () => _close('/student'), child: const Text('Start the assessment')),
                        OutlinedButton(onPressed: () => _close('/parent'), child: const Text('I have a family code')),
                        ...appBarActions(context),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  final String label;
  final TextStyle style;
  final bool current, dimmed;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;
  const _MenuItem({
    required this.label,
    required this.style,
    required this.current,
    required this.dimmed,
    required this.onHover,
    required this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _active = false;

  void _set(bool v) {
    setState(() => _active = v);
    widget.onHover(v);
  }

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    final d = still ? Duration.zero : const Duration(milliseconds: 260);
    final color = widget.style.color ?? Theme.of(context).colorScheme.onSurface;
    return CursorTarget(
      label: 'Go',
      child: InkWell(
        onTap: widget.onTap,
        onHover: _set,
        onFocusChange: _set,
        hoverColor: Colors.transparent,
        child: AnimatedOpacity(
          duration: d,
          opacity: widget.dimmed ? 0.35 : 1,
          child: AnimatedSlide(
            duration: d,
            curve: Curves.easeOutCubic,
            offset: _active ? const Offset(0.03, 0) : Offset.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                AnimatedSize(
                  duration: d,
                  child: _active
                      ? Padding(
                          padding: const EdgeInsets.only(right: Spacing.md),
                          child: Icon(Icons.arrow_forward, size: (widget.style.fontSize ?? 40) * 0.7, color: PrismColors.fit),
                        )
                      : const SizedBox.shrink(),
                ),
                Flexible(child: Text(widget.label, style: widget.style.copyWith(color: color))),
                if (widget.current)
                  Container(
                    margin: const EdgeInsets.only(left: Spacing.md),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: PrismColors.fit, shape: BoxShape.circle),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    final wide = isWide(context);

    Widget column(String title, List<(String, String)> links) => SizedBox(
          width: wide ? 220 : double.infinity,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: tt.labelLarge?.copyWith(color: cs.onSurface.fade(0.6))),
            const SizedBox(height: Spacing.sm),
            for (final l in links)
              HoverLink(label: l.$1, arrow: false, style: tt.bodyLarge, onTap: () => context.go(l.$2)),
          ]),
        );

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.onSurface.fade(0.08)))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SiteSection(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Reveal(child: Text('Find the career that fits your whole family.', style: statementStyle(context, max: 72))),
            const SizedBox(height: Spacing.xl),
            MagneticButton(
              child: CursorTarget(
                label: 'Start',
                child: FilledButton(onPressed: () => context.push('/student'), child: const Text('Start the assessment')),
              ),
            ),
            const SizedBox(height: Spacing.xxxl),
            Wrap(spacing: Spacing.xxl, runSpacing: Spacing.xl, children: [
              column('Explore', [('How it works', '/how-it-works'), ('Careers', '/careers'), ('About and data', '/about')]),
              column('For families', [('For parents', '/parents'), ('Parent form', '/parent'), ('Take the quiz', '/student')]),
              column('For schools', [('For schools', '/schools'), ('School dashboard', '/admin')]),
            ]),
            const SizedBox(height: Spacing.xxl),
            Text(
              'Salaries, fees, job growth and demand figures in this prototype are illustrative demo data. '
              'Always check exam dates, fees and scholarships on official websites.',
              style: tt.bodySmall,
            ),
          ]),
        ),
        // Oversized wordmark that rises into view.
        ClipRect(
          child: Reveal(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 12),
              child: Text(
                'PRISM',
                maxLines: 1,
                style: displayFont(TextStyle(
                  fontSize: (w * 0.24).clamp(80.0, 340.0),
                  fontWeight: FontWeight.w700,
                  height: 0.9,
                  letterSpacing: -4,
                  color: cs.onSurface.fade(0.07),
                )),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.md, Spacing.xl, Spacing.xl),
          child: Text('PRISM Engine, built for DataQuest 3.0 (DQNM).', style: tt.bodySmall),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Preloader (first load only)
// ---------------------------------------------------------------------------

/// Counts 0% to 100% while seed data loads, then lifts away like a curtain.
/// Never shows when reduced motion is on.
class PreloaderGate extends StatefulWidget {
  final Widget child;
  const PreloaderGate({super.key, required this.child});

  @override
  State<PreloaderGate> createState() => _PreloaderGateState();
}

class _PreloaderGateState extends State<PreloaderGate> with TickerProviderStateMixin {
  late final AnimationController _count = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  bool _done = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _done = true;
      return;
    }
    _count.forward();
    _count.addStatusListener((_) => _maybeExit());
    _exit.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() => _done = true);
    });
  }

  void _maybeExit() {
    if (!mounted || _done || _exit.isAnimating || _exit.isCompleted) return;
    final loading = context.read<AppState>().loading;
    if (_count.isCompleted && !loading) _exit.forward();
  }

  @override
  void dispose() {
    _count.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    final loading = context.watch<AppState>().loading;
    if (!loading) WidgetsBinding.instance.addPostFrameCallback((_) => _maybeExit());
    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: AnimatedBuilder(
          animation: Listenable.merge([_count, _exit]),
          builder: (context, _) {
            final shown = loading ? _count.value.clamp(0.0, 0.99) : _count.value;
            final bg = Theme.of(context).scaffoldBackgroundColor; // follows light or dark mode
            final ink = Theme.of(context).colorScheme.onSurface;
            return FractionalTranslation(
              translation: Offset(0, -Curves.easeInOutCubic.transform(_exit.value)),
              child: Semantics(
                label: 'Loading PRISM',
                child: Material(
                  color: bg,
                  child: Stack(children: [
                    Positioned(
                      left: 32,
                      top: 32,
                      child: const _Wordmark(),
                    ),
                    Positioned(
                      right: 32,
                      bottom: 24,
                      child: Text(
                        '${(shown * 100).round()}%',
                        style: displayFont(TextStyle(
                          fontSize: (MediaQuery.sizeOf(context).width * 0.16).clamp(64.0, 180.0),
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: ink,
                          fontFeatures: tabularFigures,
                        )),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      bottom: 0,
                      height: 3,
                      width: MediaQuery.sizeOf(context).width * shown,
                      child: const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: PrismColors.spectrum))),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// App bar for the app pages (quiz, parent form, results...)
// ---------------------------------------------------------------------------

/// Shared app bar for the app pages so they match the marketing site: wordmark (to home), page title, actions.
PreferredSizeWidget prismAppBar(BuildContext context, {required String title, List<Widget> actions = const []}) {
  final cs = Theme.of(context).colorScheme;
  final wide = MediaQuery.sizeOf(context).width > 600;
  return AppBar(
    automaticallyImplyLeading: false,
    titleSpacing: wide ? 32 : 12,
    toolbarHeight: 64,
    shape: Border(bottom: BorderSide(color: cs.onSurface.fade(0.08))),
    title: Row(children: [
      Semantics(
        label: 'PRISM home',
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.nested),
          onTap: () => context.go('/'),
          child: Padding(padding: const EdgeInsets.all(Spacing.xs), child: _Wordmark(size: wide ? 20 : 16)),
        ),
      ),
      if (wide) ...[
        const SizedBox(width: Spacing.lg),
        Container(width: 1, height: 20, color: cs.onSurface.fade(0.18)),
        const SizedBox(width: Spacing.lg),
      ] else
        const SizedBox(width: Spacing.md),
      Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium)),
    ]),
    actions: [...actions, ...appBarActions(context), const SizedBox(width: Spacing.sm)],
  );
}
