import 'package:backbone/trait.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

/// All information to for a sprite or SpriteAnimationData
class SpriteTrait extends Trait {
  var _offset = Vector2.zero();
  Vector2 get offset => _offset;
  set offset(Vector2 value) {
    if (_offset != value) {
      _offset = value;
      dirty = true;
    }
  }

  var _paint = Paint();
  Paint get paint => _paint;
  set paint(Paint value) {
    if (value != _paint) {
      _paint = value;
      dirty = true;
    }
  }

  int _priority = 0;
  int get priority => _priority;
  set priority(int value) {
    if (_priority != value) {
      _priority = value;
      dirty = true;
    }
  }

  bool dirty = true;

  void Function(int currentIndex)? onFrame;
  void Function()? onComplete;

  Sprite? _sprite;
  Sprite? get sprite => _sprite;
  set sprite(Sprite? sprite) {
    if (_sprite != sprite) {
      _sprite = sprite;
      dirty = true;
    }
  }

  SpriteAnimation? _animationData;
  SpriteAnimation? get animationData => _animationData;
  set animationData(SpriteAnimation? data) {
    if (_animationData != data) {
      _animationData = data;
      dirty = true;
    }
  }
}
