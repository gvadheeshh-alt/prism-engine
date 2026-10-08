import 'package:flutter/material.dart';

import 'hero_scene_stub.dart' if (dart.library.js_interop) 'hero_scene_web.dart' as impl;

/// Full-width landing hero.
/// - Web: the three.js glass-prism scene from web/hero/index.html (real refraction with
///   chromatic dispersion), embedded as an iframe.
/// - Android / other platforms: the pure-Dart [Prism3DHero].
class HeroScene extends StatelessWidget {
  final List<String> labels;

  /// Called with a scroll delta when the user scrolls (mouse wheel or vertical swipe) over the web hero,
  /// so the page can scroll even though the iframe receives those events.
  final ValueChanged<double>? onScroll;

  const HeroScene({super.key, required this.labels, this.onScroll});

  @override
  Widget build(BuildContext context) => impl.buildHeroScene(context, labels: labels, onScroll: onScroll);
}
