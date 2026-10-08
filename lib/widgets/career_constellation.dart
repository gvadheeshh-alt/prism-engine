import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/models.dart';
import '../theme.dart';
import 'motion.dart';
import 'three_d.dart';

/// Every career as a sphere in 3D space:
///   across = fit, up = job demand (market), depth = affordability (feasibility).
/// Sphere size grows with the PRISM score; colour is the career's strongest score.
/// Drag to orbit, scroll or pinch to zoom, double-tap to reset, tap a sphere to open that career.
class CareerConstellation extends StatefulWidget {
  final List<CareerScore> rankings;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const CareerConstellation({super.key, required this.rankings, required this.selectedId, required this.onSelect});

  @override
  State<CareerConstellation> createState() => _CareerConstellationState();
}

class _Node {
  final CareerScore score;
  final int rank;
  final Vec3 world;
  final double baseRadius;
  final Color color;
  const _Node(this.score, this.rank, this.world, this.baseRadius, this.color);
}

class _Drawn {
  final _Node node;
  final Offset at;
  final double radius;
  final double depth; // rotated z
  const _Drawn(this.node, this.at, this.radius, this.depth);
}

class _CareerConstellationState extends State<CareerConstellation> with TickerProviderStateMixin {
  static const _defaultYaw = 0.75, _defaultPitch = -0.38;

  double _yaw = _defaultYaw, _pitch = _defaultPitch, _zoom = 1.0;
  double _zoomAtStart = 1.0;
  double _time = 0;
  bool _dragging = false;
  DateTime _lastTouch = DateTime.fromMillisecondsSinceEpoch(0);
  bool _still = false;

  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  // Smooth re-positioning when weights change.
  late final AnimationController _morph = AnimationController(vsync: this, duration: const Duration(milliseconds: 500), value: 1);
  Map<String, Vec3> _from = {};
  Map<String, Vec3> _to = {};
  Map<String, double> _rFrom = {};
  Map<String, double> _rTo = {};

  String? _hoverId;
  Offset _hoverAt = Offset.zero;
  List<_Drawn> _drawn = const [];

  @override
  void initState() {
    super.initState();
    _setTargets(widget.rankings, animate: false);
  }

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

  @override
  void didUpdateWidget(CareerConstellation old) {
    super.didUpdateWidget(old);
    if (!identical(old.rankings, widget.rankings)) _setTargets(widget.rankings, animate: !_still);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _morph.dispose();
    super.dispose();
  }

  static Vec3 _positionOf(CareerScore s) => Vec3(
        (s.components.fit - 0.5) * 2,
        (s.components.market - 0.5) * 2,
        (s.components.feasibility - 0.5) * 2,
      );

  static double _radiusOf(CareerScore s) => 4 + (s.prism100 / 100) * 10;

  void _setTargets(List<CareerScore> list, {required bool animate}) {
    final t = Curves.easeInOutCubic.transform(_morph.value);
    final currentPos = <String, Vec3>{
      for (final id in _to.keys) id: Vec3.lerp(_from[id] ?? _to[id]!, _to[id]!, t),
    };
    final currentR = <String, double>{
      for (final id in _rTo.keys) id: (_rFrom[id] ?? _rTo[id]!) + (_rTo[id]! - (_rFrom[id] ?? _rTo[id]!)) * t,
    };
    _to = {for (final s in list) s.careerId: _positionOf(s)};
    _rTo = {for (final s in list) s.careerId: _radiusOf(s)};
    if (animate && currentPos.isNotEmpty) {
      _from = {for (final id in _to.keys) id: currentPos[id] ?? _to[id]!};
      _rFrom = {for (final id in _rTo.keys) id: currentR[id] ?? _rTo[id]!};
      _morph.forward(from: 0);
    } else {
      _from = Map.of(_to);
      _rFrom = Map.of(_rTo);
      _morph.value = 1;
    }
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _time += dt;
    final idle = !_dragging && DateTime.now().difference(_lastTouch).inMilliseconds > 2500;
    if (idle) _yaw += 0.12 * dt;
    setState(() {});
  }

  void _touched() => _lastTouch = DateTime.now();

  void _reset() => setState(() {
        _yaw = _defaultYaw;
        _pitch = _defaultPitch;
        _zoom = 1.0;
        _touched();
      });

  static Color _strongestColor(ScoreComponents c) {
    final values = [c.fit, c.market, c.feasibility, c.roiNorm];
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return PrismColors.spectrum[best];
  }

  List<_Node> _nodes() {
    final t = Curves.easeInOutCubic.transform(_morph.value);
    return [
      for (var i = 0; i < widget.rankings.length; i++)
        () {
          final s = widget.rankings[i];
          final id = s.careerId;
          final to = _to[id] ?? _positionOf(s);
          final from = _from[id] ?? to;
          final rTo = _rTo[id] ?? _radiusOf(s);
          final rFrom = _rFrom[id] ?? rTo;
          return _Node(s, i + 1, Vec3.lerp(from, to, t), rFrom + (rTo - rFrom) * t, _strongestColor(s.components));
        }(),
    ];
  }

  _Drawn? _hit(Offset at) {
    _Drawn? best;
    var bestDist = double.infinity;
    for (final d in _drawn) {
      final dist = (d.at - at).distance;
      if (dist <= d.radius + 8 && dist < bestDist) {
        best = d;
        bestDist = dist;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hovered = _hoverId == null ? null : widget.rankings.where((s) => s.careerId == _hoverId).firstOrNull;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LayoutBuilder(builder: (context, box) {
        final width = box.maxWidth;
        final height = width > 700 ? width * 9 / 16 : width;
        final size = Size(width, height);
        final cam = PerspectiveCamera(center: Offset(width / 2, height * 0.54), scale: math.min<double>(width, height) * 0.30 * _zoom, distance: 5);
        final pulse = _still ? 0.0 : math.sin(_time * 4) * 0.5 + 0.5;

        // Project every sphere now so taps and hovers can hit-test against the same positions the painter draws.
        final drawn = <_Drawn>[];
        for (final n in _nodes()) {
          final rot = rotateYawPitch(n.world, _yaw, _pitch);
          final pr = cam.project(rot);
          var radius = n.baseRadius * pr.k * _zoom;
          if (n.score.careerId == widget.selectedId) radius *= 1 + 0.15 * pulse;
          drawn.add(_Drawn(n, pr.offset, radius, rot.z));
        }
        drawn.sort((a, b) => a.depth.compareTo(b.depth)); // far first
        _drawn = drawn;

        final labelStyle = (tt.labelMedium ?? const TextStyle()).copyWith(color: cs.onSurface.fade(0.9));
        final axisStyle = displayFont(tt.labelLarge ?? const TextStyle());

        return SizedBox(
          width: width,
          height: height,
          child: Listener(
            onPointerSignal: (e) {
              if (e is PointerScrollEvent) {
                GestureBinding.instance.pointerSignalResolver.register(e, (event) {
                  final scroll = event as PointerScrollEvent;
                  setState(() {
                    _zoom = (_zoom * (1 - scroll.scrollDelta.dy * 0.0012)).clamp(0.6, 1.8);
                    _touched();
                  });
                });
              }
            },
            child: MouseRegion(
              cursor: _hoverId != null ? SystemMouseCursors.click : SystemMouseCursors.grab,
              onHover: (e) {
                final hit = _hit(e.localPosition);
                setState(() {
                  _hoverId = hit?.node.score.careerId;
                  _hoverAt = e.localPosition;
                });
              },
              onExit: (_) => setState(() => _hoverId = null),
              child: GestureDetector(
                onDoubleTap: _reset,
                onTapUp: (d) {
                  final hit = _hit(d.localPosition);
                  if (hit != null) widget.onSelect(hit.node.score.careerId);
                },
                onScaleStart: (_) {
                  _dragging = true;
                  _zoomAtStart = _zoom;
                  _touched();
                },
                onScaleUpdate: (d) => setState(() {
                  if (d.pointerCount >= 2) {
                    _zoom = (_zoomAtStart * d.scale).clamp(0.6, 1.8);
                  } else {
                    _yaw += d.focalPointDelta.dx * 0.01;
                    _pitch = (_pitch + d.focalPointDelta.dy * 0.008).clamp(-1.25, 0.25);
                  }
                  _touched();
                }),
                onScaleEnd: (_) {
                  _dragging = false;
                  _touched();
                },
                child: Stack(children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: size,
                      painter: _ConstellationPainter(
                        drawn: drawn,
                        yaw: _yaw,
                        pitch: _pitch,
                        cam: cam,
                        selectedId: widget.selectedId,
                        hoverId: _hoverId,
                        grid: cs.onSurface,
                        dark: dark,
                        labelStyle: labelStyle,
                        axisStyle: axisStyle,
                      ),
                    ),
                  ),
                  if (hovered != null)
                    Positioned(
                      left: (_hoverAt.dx + 14).clamp(0.0, math.max<double>(0.0, width - 220)),
                      top: math.max<double>(0.0, _hoverAt.dy - 54),
                      child: IgnorePointer(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 210),
                          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
                          decoration: BoxDecoration(
                            color: dark ? PrismColors.surfaceDarkHigh : Colors.white,
                            borderRadius: BorderRadius.circular(Radii.nested),
                            border: Border.all(color: cs.onSurface.fade(0.14)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(hovered.career.name, style: tt.labelLarge),
                            Text('PRISM ${hovered.prism100.round()}, click to open', style: tt.bodySmall),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        );
      }),
      const SizedBox(height: Spacing.md),
      Text('Across is fit, up is job demand, depth is affordability. Bigger spheres have higher PRISM scores; '
          'each colour is that career\'s strongest score.', style: tt.bodySmall),
      const SizedBox(height: Spacing.xs),
      Text('Drag to rotate, scroll or pinch to zoom, double-tap to reset.', style: tt.bodySmall),
    ]);
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<_Drawn> drawn;
  final double yaw, pitch;
  final PerspectiveCamera cam;
  final String? selectedId, hoverId;
  final Color grid;
  final bool dark;
  final TextStyle labelStyle, axisStyle;

  _ConstellationPainter({
    required this.drawn,
    required this.yaw,
    required this.pitch,
    required this.cam,
    required this.selectedId,
    required this.hoverId,
    required this.grid,
    required this.dark,
    required this.labelStyle,
    required this.axisStyle,
  });

  Offset _p(Vec3 v) => cam.project(rotateYawPitch(v, yaw, pitch)).offset;

  void _line(Canvas canvas, Vec3 a, Vec3 b, Paint paint) => canvas.drawLine(_p(a), _p(b), paint);

  void _text(Canvas canvas, String s, Offset at, TextStyle style, {bool centre = false}) {
    final tp = TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr, maxLines: 1)..layout();
    tp.paint(canvas, centre ? at - Offset(tp.width / 2, tp.height / 2) : at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Floor grid at the bottom of the cube.
    final gridPaint = Paint()
      ..color = grid.fade(0.07)
      ..strokeWidth = 1;
    for (var i = -2; i <= 2; i++) {
      final v = i / 2;
      _line(canvas, Vec3(v, -1, -1), Vec3(v, -1, 1), gridPaint);
      _line(canvas, Vec3(-1, -1, v), Vec3(1, -1, v), gridPaint);
    }

    // Wireframe cube.
    final edge = Paint()
      ..color = grid.fade(0.14)
      ..strokeWidth = 1;
    const c = [
      Vec3(-1, -1, -1), Vec3(1, -1, -1), Vec3(1, 1, -1), Vec3(-1, 1, -1),
      Vec3(-1, -1, 1), Vec3(1, -1, 1), Vec3(1, 1, 1), Vec3(-1, 1, 1),
    ];
    const edges = [
      [0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7],
    ];
    for (final e in edges) {
      _line(canvas, c[e[0]], c[e[1]], edge);
    }

    // The three axes in their score colours, with labels.
    const origin = Vec3(-1, -1, -1);
    Paint axis(Color col) => Paint()
      ..color = col.fade(0.85)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    _line(canvas, origin, const Vec3(1, -1, -1), axis(PrismColors.fit));
    _line(canvas, origin, const Vec3(-1, 1, -1), axis(PrismColors.market));
    _line(canvas, origin, const Vec3(-1, -1, 1), axis(PrismColors.feasibility));
    _text(canvas, 'Fit', _p(const Vec3(1.22, -1, -1)), axisStyle.copyWith(color: PrismColors.fit), centre: true);
    _text(canvas, 'Job demand', _p(const Vec3(-1, 1.18, -1)), axisStyle.copyWith(color: PrismColors.market), centre: true);
    _text(canvas, 'Affordability', _p(const Vec3(-1, -1, 1.25)), axisStyle.copyWith(color: PrismColors.feasibility), centre: true);

    // Spheres, far to near.
    if (drawn.isEmpty) return;
    final minZ = drawn.first.depth, maxZ = drawn.last.depth;
    final span = (maxZ - minZ).abs() < 1e-6 ? 1.0 : (maxZ - minZ);
    for (final d in drawn) {
      final near = (d.depth - minZ) / span; // 0 far .. 1 near
      final alpha = 0.45 + 0.55 * near;
      final id = d.node.score.careerId;
      final isSel = id == selectedId;
      final isHover = id == hoverId;
      final featured = d.node.rank <= 5 || isSel;
      final col = d.node.color;

      if (featured || isHover) {
        canvas.drawCircle(d.at, d.radius * 2.1, Paint()..color = col.fade(0.16 * alpha));
      }
      final rect = Rect.fromCircle(center: d.at, radius: d.radius);
      canvas.drawCircle(
        d.at,
        d.radius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            colors: [
              (Color.lerp(col, Colors.white, 0.6) ?? col).fade(alpha),
              col.fade(alpha),
              (Color.lerp(col, Colors.black, 0.35) ?? col).fade(alpha),
            ],
            stops: const [0, 0.55, 1],
          ).createShader(rect),
      );
      if (isSel || isHover) {
        canvas.drawCircle(d.at, d.radius + 3, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = (dark ? Colors.white : PrismColors.inkLight).fade(0.85));
      }
      if (featured) {
        final name = d.node.rank <= 5 ? '${d.node.rank}. ${d.node.score.career.name}' : d.node.score.career.name;
        _text(canvas, name, d.at + Offset(d.radius + 6, -8), labelStyle.copyWith(color: labelStyle.color?.fade(0.55 + 0.45 * near)));
      }
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) => true;
}
