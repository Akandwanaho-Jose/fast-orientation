import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('fastInitialPath')
external JSString? get _capturedInitialPath;

String? browserInitialRoute() {
  final capturedRoute = _routeFromLocation(_capturedInitialPath?.toDart);
  if (capturedRoute != null) {
    return capturedRoute;
  }

  final hash = web.window.location.hash;
  if (hash.startsWith('#/')) {
    return hash.substring(1);
  }

  final path = web.window.location.pathname;
  if (path.isNotEmpty) {
    return path;
  }

  return null;
}

String? _routeFromLocation(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final parsed = Uri.tryParse(value);
  final fragment = parsed?.fragment ?? '';
  if (fragment.startsWith('/')) {
    return fragment;
  }

  final path = parsed?.path ?? value;
  return path.isNotEmpty ? path : null;
}
