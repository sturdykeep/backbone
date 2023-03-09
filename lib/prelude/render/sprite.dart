import 'dart:ui';

import 'package:backbone/entity.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/prelude/render/mod.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/render/visual.dart';
import 'package:backbone/prelude/time.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, debugPrint;

class SpriteVisual extends Visual {
  Sprite? sprite;
  Paint? overridePaint;
  Color? overrideColor;
  SpriteVisual({this.sprite, this.overridePaint});

  Image? get image => sprite?.image;
  Paint? get paint => overridePaint ?? sprite?.paint;
  Color get color => overrideColor ?? Colors.white;
}

class SpriteAnimationVisual extends Visual {
  SpriteAnimation? animation;
  Paint? overridePaint;
  Color? overrideColor;
  SpriteAnimationVisual({this.animation, this.overridePaint});

  Image? get image => animation?.currentFrame.sprite.image;
  Paint? get paint => overridePaint ?? animation?.currentFrame.sprite.paint;
  Color get color => overrideColor ?? Colors.white;
  bool get isComplete => animation?.done() ?? true;
}

/// System that advances the animation of all entities with a SpriteAnimationVisual.
void spriteAnimationSystem(Realm realm) {
  final time = realm.resource<Time>();
  final entities = realm.query(Has([Renderable]));

  for (final entity in entities) {
    final renderTrait = entity.get<Renderable>();
    final visual = renderTrait.visual;
    if (visual is SpriteAnimationVisual) {
      visual.animation?.update(time.delta);
    }
  }
}

class SpriteRenderer extends Renderer {
  Image? currentImage;
  Paint? currentPaint;

  bool paintsAreSame(Paint a, Paint b) {
    return a.color == b.color &&
        a.blendMode == b.blendMode &&
        a.maskFilter == b.maskFilter &&
        a.filterQuality == b.filterQuality &&
        a.invertColors == b.invertColors &&
        a.shader == b.shader &&
        a.colorFilter == b.colorFilter &&
        a.imageFilter == b.imageFilter &&
        a.isAntiAlias == b.isAntiAlias &&
        a.strokeWidth == b.strokeWidth &&
        a.strokeCap == b.strokeCap &&
        a.strokeJoin == b.strokeJoin &&
        a.strokeMiterLimit == b.strokeMiterLimit &&
        a.style == b.style &&
        a.color == b.color &&
        a.maskFilter == b.maskFilter &&
        a.filterQuality == b.filterQuality &&
        a.invertColors == b.invertColors &&
        a.shader == b.shader &&
        a.colorFilter == b.colorFilter &&
        a.imageFilter == b.imageFilter &&
        a.isAntiAlias == b.isAntiAlias &&
        a.strokeWidth == b.strokeWidth &&
        a.strokeCap == b.strokeCap &&
        a.strokeJoin == b.strokeJoin &&
        a.strokeMiterLimit == b.strokeMiterLimit &&
        a.style == b.style;
  }

  @override
  Visual? matches(Entity entity) {
    final renderTrait = entity.tryGet<Renderable>();
    if (renderTrait != null) {
      final visual = renderTrait.visual;
      if (visual is SpriteVisual) {
        if (currentImage == null && currentPaint == null) {
          currentImage = visual.image;
          currentPaint = visual.paint;
        } else if (currentImage != visual.image ||
            paintsAreSame(currentPaint!, visual.paint!) == false) {
          return null;
        }

        return visual;
      }

      if (visual is SpriteAnimationVisual) {
        if (currentImage == null && currentPaint == null) {
          currentImage = visual.image;
          currentPaint = visual.paint;
        } else if (currentImage != visual.image ||
            paintsAreSame(currentPaint!, visual.paint!) == false) {
          return null;
        }

        return visual;
      }
    }
    return null;
  }

  @override
  void render(Iterable<Renderee> renderees, Realm realm, Canvas canvas) {
    if (renderees.isEmpty) return;
    if (currentImage == null || currentPaint == null) return;

    List<RSTransform> transforms = [];
    List<Rect> rects = [];
    List<Color> colors = [];
    for (final renderee in renderees) {
      final transformTrait = renderee.transformTrait;

      if (transformTrait != null) {
        if (renderee.matchedVisual is SpriteVisual) {
          final sprite = renderee.matchedVisual as SpriteVisual;
          transforms.add(transformTrait.calculateGlobalRSTransform(
              spriteSize: sprite.sprite!.srcSize));
          rects.add(sprite.sprite!.src);
          colors.add(sprite.color);
        } else if (renderee.matchedVisual is SpriteAnimationVisual) {
          final sprite = renderee.matchedVisual as SpriteAnimationVisual;
          transforms.add(transformTrait.calculateGlobalRSTransform(
              spriteSize: sprite.animation!.currentFrame.sprite.srcSize));
          rects.add(sprite.animation!.currentFrame.sprite.src);
          colors.add(sprite.color);
        } else {
          throw Exception('Unknown visual type for SpriteRenderer');
        }
      }
    }

    canvas.drawAtlas(currentImage!, transforms, rects, colors,
        BlendMode.modulate, null, currentPaint!);

    currentImage = null;
    currentPaint = null;
  }
}
