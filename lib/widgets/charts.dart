import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/models.dart';
import '../theme.dart';
import 'india_outline.dart';
import 'motion.dart';
import 'three_d.dart';

/// Radar: student profile vs. a career's requirement, on a fixed 0..1 scale.
class ProfileRadar extends StatelessWidget {
  final Vector15 student;
  final Vector15 requirement;
  final String careerName;
  const ProfileRadar({super.key, required this.student, required this.requirement, required this.careerName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grid = cs.onSurface.fade(0.12);
    final dims = Dimension.values;
    RadarDataSet set(Vector15 v, Color c, {bool hidden = false}) => RadarDataSet(
          dataEntries: [for (final d in dims) RadarEntry(value: v[d])],
          fillColor: hidden ? Colors.transparent : c.fade(0.18),
          borderColor: hidden ? Colors.transparent : c,
          borderWidth: hidden ? 0 : 2,
          entryRadius: hidden ? 0 : 2,
        );
    final zeros = Vector15({for (final d in dims) d: 0.0});
    final ones = Vector15({for (final d in dims) d: 1.0});
    return Column(children: [
      AspectRatio(
        aspectRatio: 1.15,
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            dataSets: [
              set(ones, Colors.transparent, hidden: true),
              set(zeros, Colors.transparent, hidden: true),
              set(requirement, PrismColors.market),
              set(student, PrismColors.fit),
            ],
            getTitle: (index, angle) => RadarChartTitle(text: dims[index].short),
            titleTextStyle: TextStyle(fontSize: 11, color: cs.onSurface.fade(0.75)),
            titlePositionPercentageOffset: 0.12,
            tickCount: 4,
            ticksTextStyle: const TextStyle(fontSize: 1, color: Colors.transparent),
            tickBorderData: BorderSide(color: grid),
            gridBorderData: BorderSide(color: grid),
            radarBorderData: BorderSide(color: grid),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 16, children: [
        _Key(color: PrismColors.fit, text: 'You'),
        _Key(color: PrismColors.market, text: '$careerName needs'),
      ]),
    ]);
  }
}

class _Key extends StatelessWidget {
  final Color color;
  final String text;
  const _Key({required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 14, height: 3, color: color),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ]);
}

/// India map (official boundary) with job hubs: bubble size and colour show demand.
class DemandMap extends StatelessWidget {
  final List<RegionDemand> demand;

  /// Show the "inside your range" note (results page). Career pages have no student, so they hide it.
  final bool showRange;
  const DemandMap({super.key, required this.demand, this.showRange = true});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final abroad = demand.where((d) => d.region.isAbroad).toList();
    final hubs = demand.where((d) => !d.region.isAbroad).toList();
    final top = [...hubs]..sort((a, b) => b.demand.compareTo(a.demand));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
        label: 'Map of India. Strongest demand: ${top.take(3).map((d) => '${d.region.name} ${(d.demand * 100).round()}%').join(', ')}.',
        child: AspectRatio(
          aspectRatio: _IndiaPainter.aspectRatio,
          child: CustomPaint(
            painter: _IndiaPainter(
              hubs,
              outline: cs.onSurface.fade(0.35),
              fill: cs.onSurface.fade(0.05),
              label: cs.onSurface.fade(0.85),
              halo: Theme.of(context).scaffoldBackgroundColor,
              showRange: showRange,
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      if (abroad.isNotEmpty)
        Text(
          'Demand abroad: ${(abroad.first.demand * 100).round()}%${showRange && !abroad.first.inRange ? ' (outside the distance you chose)' : ''}',
          style: tt.bodySmall,
        ),
      Text(
        showRange
            ? 'Bigger, greener bubbles mean more demand. Solid bubbles are within the distance you are willing to move.'
            : 'Bigger, greener bubbles mean more demand (illustrative).',
        style: tt.bodySmall?.copyWith(color: tt.bodySmall?.color?.fade(0.7)),
      ),
      Text('Boundary: Government of India official map (DataMeet composite).',
          style: tt.bodySmall?.copyWith(color: tt.bodySmall?.color?.fade(0.5), fontSize: 10.5)),
    ]);
  }
}

class _IndiaPainter extends CustomPainter {
  final List<RegionDemand> demand;
  final Color outline, fill, label, halo;
  final bool showRange;
  _IndiaPainter(this.demand, {required this.outline, required this.fill, required this.label, required this.halo, required this.showRange});

  // Bounds of the drawing (covers the mainland and the Andaman and Nicobar Islands).
  static const _minLng = 67.5, _maxLng = 98.0, _minLat = 6.4, _maxLat = 37.6;
  // Longitude is shrunk by cos(22 deg), India's middle latitude, so the country is not stretched sideways.
  static const _k = 0.9272;
  static const aspectRatio = ((_maxLng - _minLng) * _k) / (_maxLat - _minLat);

  Offset _project(double lng, double lat, Size s) =>
      Offset((lng - _minLng) / (_maxLng - _minLng) * s.width, (1 - (lat - _minLat) / (_maxLat - _minLat)) * s.height);

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = fill;
    final strokePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.round;
    for (final ring in indiaOutline) {
      final path = Path();
      for (var i = 0; i < ring.length; i++) {
        final p = _project(ring[i][0], ring[i][1], size);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }

    // Bubbles: small ones on top so they stay visible.
    final placed = <_Bubble>[];
    for (final d in demand) {
      final c = _project(d.region.lng, d.region.lat, size);
      final r = 3.0 + d.demand * size.width * 0.028;
      placed.add(_Bubble(d, c, r));
    }
    final drawOrder = [...placed]..sort((a, b) => b.r.compareTo(a.r));
    for (final b in drawOrder) {
      final color = Color.lerp(PrismColors.feasibility, PrismColors.market, b.d.demand) ?? PrismColors.market;
      final solid = !showRange || b.d.inRange;
      canvas.drawCircle(b.c, b.r, Paint()..color = solid ? color.fade(0.75) : color.fade(0.12));
      canvas.drawCircle(b.c, b.r, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
    }

    // Labels: highest demand first; each label tries right, left, above, below and is skipped
    // if every spot would overlap another label or the dot of another city.
    final taken = <Rect>[for (final b in placed) Rect.fromCircle(center: b.c, radius: 2.5)];
    final fontSize = (size.width * 0.026).clamp(9.0, 12.0);
    final labelOrder = [...placed]..sort((a, b) => b.d.demand.compareTo(a.d.demand));
    for (final b in labelOrder) {
      final tp = TextPainter(
        text: TextSpan(text: b.d.region.name, style: TextStyle(fontSize: fontSize, color: label, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      final w = tp.width, h = tp.height, gap = b.r + 3;
      final candidates = [
        Offset(b.c.dx + gap, b.c.dy - h / 2),
        Offset(b.c.dx - gap - w, b.c.dy - h / 2),
        Offset(b.c.dx - w / 2, b.c.dy - gap - h),
        Offset(b.c.dx - w / 2, b.c.dy + gap),
      ];
      for (final o in candidates) {
        final rect = Rect.fromLTWH(o.dx, o.dy, w, h);
        final inside = rect.left >= 0 && rect.top >= 0 && rect.right <= size.width && rect.bottom <= size.height;
        if (!inside || taken.any((t) => t.overlaps(rect.inflate(1)))) continue;
        // A soft halo keeps text readable on top of bubbles and the border line.
        canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(3)), Paint()..color = halo.fade(0.55));
        tp.paint(canvas, o);
        taken.add(rect);
        break;
      }
    }
  }

  @override
  bool shouldRepaint(_IndiaPainter old) => old.demand != demand || old.outline != outline || old.showRange != showRange;
}

class _Bubble {
  final RegionDemand d;
  final Offset c;
  final double r;
  const _Bubble(this.d, this.c, this.r);
}

/// Landing-page hero: a real 3D glass prism. One white beam (the student) enters and
/// splits into five coloured beams (the five scores). Drag to rotate; it eases back to a
/// slow spin when released. On web the scene follows the mouse slightly (parallax).
class Prism3DHero extends StatefulWidget {
  final List<String> labels;

  /// When set (0..1), scroll position drives the beams instead of the intro animation:
  /// 0..1/3 the white beam enters, then the five coloured beams appear.
  final double? storyProgress;

  /// Width / height of the canvas.
  final double aspectRatio;

  const Prism3DHero({super.key, required this.labels, this.storyProgress, this.aspectRatio = 2.2});

  @override
  State<Prism3DHero> createState() => _Prism3DHeroState();
}

class _Prism3DHeroState extends State<Prism3DHero> with TickerProviderStateMixin {
  static const _basePitch = -0.32;
  static const _spinSpeed = 0.35; // radians per second

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  double _yaw = 0.55;
  double _pitch = _basePitch;
  double _yawVelocity = 0;
  bool _dragging = false;
  Offset _parallax = Offset.zero;
  Offset _parallaxTarget = Offset.zero;
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = reduceMotion(context);
    if (_still) {
      _intro.value = 1;
      if (_ticker.isActive) _ticker.stop();
    } else {
      if (_intro.value == 0 && !_intro.isAnimating) _intro.forward();
      if (!_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    }
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (!_dragging) {
      _yaw += (_spinSpeed + _yawVelocity) * dt;
      _yawVelocity *= 0.94;
      _pitch += (_basePitch - _pitch) * math.min<double>(1.0, dt * 2.5);
    }
    final ease = math.min<double>(1.0, dt * 6);
    _parallax = Offset.lerp(_parallax, _parallaxTarget, ease)!;
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    _intro.dispose();
    super.dispose();
  }

  double get _driver => widget.storyProgress ?? Curves.easeOutCubic.transform(_intro.value);

  double _beamIn() =>
      widget.storyProgress != null ? (_driver * 3).clamp(0.0, 1.0) : (_driver * 2.2).clamp(0.0, 1.0);

  double _beamsOut() => widget.storyProgress != null
      ? ((_driver - 0.34) / 0.5).clamp(0.0, 1.0)
      : ((_driver - 0.45) / 0.55).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = displayFont(Theme.of(context).textTheme.labelLarge ?? const TextStyle())
        .copyWith(color: cs.onSurface.fade(0.9));
    return RepaintBoundary(
      child: Semantics(
        label: 'Animated glass prism: one beam of light splits into five scores. Drag to rotate.',
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: LayoutBuilder(builder: (context, box) {
            return MouseRegion(
              cursor: SystemMouseCursors.grab,
              onHover: (e) {
                if (_still) return;
                _parallaxTarget = Offset(
                  (e.localPosition.dx / box.maxWidth) * 2 - 1,
                  (e.localPosition.dy / box.maxHeight) * 2 - 1,
                );
              },
              onExit: (_) => _parallaxTarget = Offset.zero,
              child: GestureDetector(
                onPanStart: (_) => _dragging = true,
                onPanUpdate: (d) => setState(() {
                  _yaw += d.delta.dx * 0.012;
                  _pitch = (_pitch + d.delta.dy * 0.008).clamp(-1.1, 0.5);
                }),
                onPanEnd: (d) {
                  _dragging = false;
                  _yawVelocity = (d.velocity.pixelsPerSecond.dx / 600).clamp(-3.0, 3.0);
                },
                child: AnimatedBuilder(
                  animation: _intro,
                  builder: (context, _) => CustomPaint(
                    size: Size(box.maxWidth, box.maxHeight),
                    painter: _Prism3DPainter(
                      yaw: _yaw,
                      pitch: _pitch,
                      inT: _beamIn(),
                      outT: _beamsOut(),
                      parallax: _parallax,
                      labels: widget.labels,
                      glass: dark ? Colors.white : PrismColors.inkLight,
                      beam: dark ? Colors.white : PrismColors.inkLight,
                      labelStyle: labelStyle,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Face {
  final List<Vec3> pts; // rotated
  final Vec3 normal; // rotated, outward
  final bool isSide; // one of the three rectangular faces
  const _Face(this.pts, this.normal, this.isSide);
  double get depth => Vec3.average(pts).z;
}

class _Prism3DPainter extends CustomPainter {
  final double yaw, pitch, inT, outT;
  final Offset parallax;
  final List<String> labels;
  final Color glass, beam;
  final TextStyle labelStyle;

  _Prism3DPainter({
    required this.yaw,
    required this.pitch,
    required this.inT,
    required this.outT,
    required this.parallax,
    required this.labels,
    required this.glass,
    required this.beam,
    required this.labelStyle,
  });

  static const _depth = 0.55;
  static const _apex = Vec3(0, 0.62, 0);
  static const _left = Vec3(-0.62, -0.42, 0);
  static const _right = Vec3(0.62, -0.42, 0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final center = Offset(w * 0.40 + parallax.dx * 14, h * 0.52 + parallax.dy * 10);
    final cam = PerspectiveCamera(center: center, scale: h * 0.36, distance: 4.5);

    // Soft glow behind the prism.
    canvas.drawCircle(
      center,
      h * 0.62,
      Paint()
        ..shader = RadialGradient(colors: [PrismColors.fit.fade(0.16), PrismColors.fit.fade(0)])
            .createShader(Rect.fromCircle(center: center, radius: h * 0.62)),
    );

    // Build and rotate the mesh.
    Vec3 r(Vec3 v) => rotateYawPitch(v, yaw, pitch);
    const front = _depth / 2, back = -_depth / 2;
    final a0 = r(Vec3(_apex.x, _apex.y, front)), b0 = r(Vec3(_left.x, _left.y, front)), c0 = r(Vec3(_right.x, _right.y, front));
    final a1 = r(Vec3(_apex.x, _apex.y, back)), b1 = r(Vec3(_left.x, _left.y, back)), c1 = r(Vec3(_right.x, _right.y, back));
    final centroid = Vec3.average([a0, b0, c0, a1, b1, c1]);

    _Face face(List<Vec3> pts, bool isSide) {
      var n = (pts[1] - pts[0]).cross(pts[2] - pts[0]).normalized();
      if (n.dot(Vec3.average(pts) - centroid) < 0) n = n * -1; // make it point outward
      return _Face(pts, n, isSide);
    }

    final faces = [
      face([a0, b0, c0], false),
      face([a1, c1, b1], false),
      face([a0, a1, b1, b0], true),
      face([a0, c0, c1, a1], true),
      face([b0, b1, c1, c0], true),
    ]..sort((x, y) => x.depth.compareTo(y.depth)); // far first

    Offset p(Vec3 v) => cam.project(v).offset;

    // Beam endpoints follow whichever side faces are currently leftmost / rightmost on screen.
    final sides = faces.where((f) => f.isSide).map((f) => p(Vec3.average(f.pts))).toList()
      ..sort((x, y) => x.dx.compareTo(y.dx));
    final entry = sides.first;
    final exit = sides.last;

    // 1. Incoming white beam.
    final start = Offset(0, entry.dy + h * 0.06);
    final beamPaint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, Offset.lerp(start, entry, inT)!, Paint()
      ..color = beam.fade(0.12)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round);
    canvas.drawLine(start, Offset.lerp(start, entry, inT)!, beamPaint..color = beam.fade(0.85));

    // 2. Light travelling inside the glass.
    if (inT >= 1) {
      canvas.drawLine(entry, exit, Paint()
        ..color = beam.fade(0.35)
        ..strokeWidth = 2);
    }

    // 3. Glass faces, back to front, flat-shaded.
    final light = const Vec3(-0.4, 0.6, 0.7).normalized();
    for (final f in faces) {
      final path = Path()..moveTo(p(f.pts[0]).dx, p(f.pts[0]).dy);
      for (final v in f.pts.skip(1)) {
        final q = p(v);
        path.lineTo(q.dx, q.dy);
      }
      path.close();
      final facing = f.normal.z > 0;
      final lit = math.max<double>(0.0, f.normal.dot(light));
      canvas.drawPath(path, Paint()..color = glass.fade(facing ? 0.05 + 0.16 * lit : 0.03));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = facing ? 1.4 : 0.8
          ..strokeJoin = StrokeJoin.round
          ..color = glass.fade(facing ? 0.55 : 0.16),
      );
    }

    // 4. Five coloured beams leaving the prism.
    // Measure the labels first so the beams stop early enough for every label to fit in full.
    final fontSize = (h * 0.055).clamp(12.0, 22.0);
    final painters = [
      for (var i = 0; i < 5; i++)
        TextPainter(
          text: TextSpan(text: i < labels.length ? labels[i] : '', style: labelStyle.copyWith(fontSize: fontSize)),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(),
    ];
    final labelW = painters.map((tp) => tp.width).fold<double>(0, (a, b) => a > b ? a : b);
    final endX = (w - labelW - 22 - parallax.dx.abs() * 6).clamp(w * 0.55, w * 0.86);
    if (outT <= 0) return;
    for (var i = 0; i < 5; i++) {
      final end = Offset(endX + parallax.dx * 6, h * (0.16 + i * 0.17) + parallax.dy * 4);
      final color = PrismColors.spectrum[i];
      final tip = Offset.lerp(exit, end, outT)!;
      canvas.drawLine(exit, tip, Paint()
        ..color = color.fade(0.16)
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round);
      canvas.drawLine(
        exit,
        tip,
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(colors: [color.fade(0.55), color]).createShader(Rect.fromPoints(exit, end)),
      );
      if (outT > 0.95) painters[i].paint(canvas, Offset(end.dx + 10, end.dy - painters[i].height / 2));
    }
  }

  @override
  bool shouldRepaint(_Prism3DPainter old) => true;
}
