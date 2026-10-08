import 'package:flutter/material.dart';

import '../theme.dart';
import 'charts.dart';

/// Non-web platforms: the pure-Dart 3D prism.
Widget buildHeroScene(BuildContext context, {required List<String> labels, ValueChanged<double>? onScroll}) {
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 980),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.lg, 0),
        child: Prism3DHero(labels: labels),
      ),
    ),
  );
}
