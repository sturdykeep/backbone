import 'package:backbone/trait.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';

/// Basic text trait allowing to set:
/// - Padding
/// - Anchor (inside the parent)
/// - Text
/// - Text style (default color white)
/// - Counter zoom allows to render text unzoomed or changed based on your camera
class TextTrait<T extends FlameGame> extends ATrait<T> {
  /// Setting this will force the system to reset the properties of the trait to the node
  bool dirty = false;

  Vector2 _padding = Vector2.zero();
  Vector2 get padding => _padding;
  set padding(Vector2 value) {
    if (value != _padding) {
      _padding = value;
      dirty = true;
    }
  }

  bool _counterZoom = true;

  /// By default true, unzoom your text based on the current camera
  bool get counterZoom => _counterZoom;
  set counterZoom(bool value) {
    if (value != _counterZoom) {
      _counterZoom = value;
      dirty = true;
    }
  }

  Anchor _anchor = Anchor.topLeft;
  Anchor get anchor => _anchor;
  set anchor(Anchor value) {
    if (value != _anchor) {
      _anchor = value;
      dirty = true;
    }
  }

  String _text = "";
  String get text => _text;
  set text(String value) {
    if (_text != value) {
      _text = value;
      dirty = true;
    }
  }

  TextStyle _style = TextStyle(color: BasicPalette.white.color);
  TextStyle get style => _style;
  set style(TextStyle style) {
    if (style != _style) {
      _style = style;
      dirty = true;
    }
  }
}
