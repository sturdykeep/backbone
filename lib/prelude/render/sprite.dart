import 'dart:ui';

import 'package:backbone/entity.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/prelude/render/mod.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/render/visual.dart';
import 'package:backbone/prelude/time.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart' show Colors, debugPrint;

class BaseSpriteVisual extends Visual {
  Paint? overridePaint;
  Color? overrideColor;

  BaseSpriteVisual({this.overridePaint, this.overrideColor});

  // Transform cache
  Matrix4 _usedMatrix = Matrix4.identity();
  Vector2? _usedSize;
  late RSTransform _transform;

  RSTransform getGlobalRSTransform(Transform transform, Vector2 spriteSize) {
    final globalMatrix = transform.globalMatrix;
    if (_usedSize != transform.size || _usedMatrix != globalMatrix) {
      _usedSize = transform.size;
      _transform =
          calculateGlobalRSTransform(transform, globalMatrix, spriteSize);
    }
    return _transform;
  }

  RSTransform calculateGlobalRSTransform(
      Transform transform, Matrix4 globalMatrix, Vector2 spriteSize) {
    final scaleToSize = Vector2(
        transform.size.x / spriteSize.x, transform.size.y / spriteSize.y);

    final transformedPosition = globalMatrix.transform2(transform.origin);
    // figure out the scale
    final pointA = Vector2(0, 0);
    final pointB = Vector2(1, 0);
    final transformedPointA = globalMatrix.transform2(pointA);
    final transformedPointB = globalMatrix.transform2(pointB);
    final transformedScale = transformedPointA.distanceTo(transformedPointB);
    final transformedRotation = Vector2(0, 1)
        .angleToSigned(globalMatrix.getRotation().transform2(Vector2(0, 1)));

    final anchorX = transform.anchor.x * spriteSize.x;
    final anchorY = transform.anchor.y * spriteSize.y;

    // for cache
    _usedMatrix = globalMatrix;
    _usedSize = spriteSize;

    return RSTransform.fromComponents(
      rotation: transformedRotation,
      scale: transformedScale * scaleToSize.x,
      anchorX: anchorX,
      anchorY: anchorY,
      translateX: transformedPosition.x,
      translateY: transformedPosition.y,
    );
  }
}

class SpriteVisual extends BaseSpriteVisual {
  Sprite? sprite;
  SpriteVisual({this.sprite});

  Image? get image => sprite?.image;
  Paint? get paint => overridePaint ?? sprite?.paint;
  Color get color => overrideColor ?? Colors.white;
}

class SpriteAnimationVisual extends BaseSpriteVisual {
  SpriteAnimation? animation;
  SpriteAnimationVisual({this.animation});

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
  Visual? matches(Entity entity, Renderable renderable, Transform? transform) {
    final visual = renderable.visual;
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
          transforms.add(sprite.getGlobalRSTransform(
              transformTrait, sprite.sprite!.srcSize));
          rects.add(sprite.sprite!.src);
          colors.add(sprite.color);
        } else if (renderee.matchedVisual is SpriteAnimationVisual) {
          final sprite = renderee.matchedVisual as SpriteAnimationVisual;
          transforms.add(sprite.getGlobalRSTransform(
              transformTrait, sprite.animation!.currentFrame.sprite.srcSize));
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
