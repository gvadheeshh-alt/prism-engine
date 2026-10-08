import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'motion.dart';

const _viewType = 'prism-hero-iframe';
const _viewTypeStill = 'prism-hero-iframe-still';
bool _registered = false;

void _registerOnce() {
  if (_registered) return;
  _registered = true;
  web.HTMLIFrameElement make(String src) {
    final f = web.HTMLIFrameElement();
    f.src = src;
    f.title = 'PRISM 3D hero: a glass prism refracting the words Choose Your Future';
    f.style.border = 'none';
    f.style.width = '100%';
    f.style.height = '100%';
    f.style.display = 'block';
    return f;
  }

  ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => make('hero/index.html'));
  ui_web.platformViewRegistry.registerViewFactory(_viewTypeStill, (int viewId) => make('hero/index.html?still=1'));
}

/// Web: the three.js scene in web/hero/index.html, shown in an iframe.
Widget buildHeroScene(BuildContext context, {required List<String> labels, ValueChanged<double>? onScroll}) {
  return _WebHero(onScroll: onScroll);
}

class _WebHero extends StatefulWidget {
  final ValueChanged<double>? onScroll;
  const _WebHero({this.onScroll});

  @override
  State<_WebHero> createState() => _WebHeroState();
}

class _WebHeroState extends State<_WebHero> {
  JSFunction? _listener;

  @override
  void initState() {
    super.initState();
    _registerOnce();
    // The hero page posts "prism-wheel:<dy>" when the user scrolls over it.
    _listener = ((web.MessageEvent e) {
      final data = e.data.dartify();
      if (data is String && data.startsWith('prism-wheel:')) {
        final dy = double.tryParse(data.substring('prism-wheel:'.length));
        if (dy != null) widget.onScroll?.call(dy);
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final height = (h * 0.72).clamp(420.0, 760.0);
    return Semantics(
      label: 'Glass prism refracting the words Choose Your Future. Drag to rotate.',
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: HtmlElementView(viewType: reduceMotion(context) ? _viewTypeStill : _viewType),
      ),
    );
  }
}
