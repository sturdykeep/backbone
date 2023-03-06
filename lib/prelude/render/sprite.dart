import 'dart:ui';

import 'package:backbone/entity.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/prelude/render/mod.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/render/visual.dart';
import 'package:backbone/prelude/time.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

class SpriteVisual extends Visual {
  Sprite? sprite;
  SpriteVisual({this.sprite});

  Image? get image => sprite?.image;
  Paint? get paint => sprite?.paint;
}

class SpriteAnimationVisual extends Visual {
  SpriteAnimation? animation;
  SpriteAnimationVisual({this.animation});

  Image? get image => animation?.currentFrame.sprite.image;
  Paint? get paint => animation?.currentFrame.sprite.paint;
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

  @override
  Visual? matches(Entity entity) {
    final renderTrait = entity.tryGet<Renderable>();
    if (renderTrait != null) {
      final visual = renderTrait.visual;
      if (visual is SpriteVisual) {
        if (currentImage == null) {
          currentImage = visual.image;
          currentPaint = visual.paint;
        } else if (currentImage != visual.image) {
          return null;
        }

        return visual;
      }

      if (visual is SpriteAnimationVisual) {
        if (currentImage == null) {
          currentImage = visual.image;
          currentPaint = visual.paint;
        } else if (currentImage != visual.image) {
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
    for (final renderee in renderees) {
      final transformTrait = renderee.transformTrait;

      if (transformTrait != null) {
        if (renderee.matchedVisual is SpriteVisual) {
          transforms.add(transformTrait.rstTransform(
              spriteSize:
                  (renderee.matchedVisual as SpriteVisual).sprite!.srcSize));
          rects.add((renderee.matchedVisual as SpriteVisual).sprite!.src);
        } else if (renderee.matchedVisual is SpriteAnimationVisual) {
          transforms.add(transformTrait.rstTransform(
              spriteSize: (renderee.matchedVisual as SpriteAnimationVisual)
                  .animation!
                  .currentFrame
                  .sprite
                  .srcSize));
          rects.add((renderee.matchedVisual as SpriteAnimationVisual)
              .animation!
              .currentFrame
              .sprite
              .src);
        } else {
          throw Exception('Unknown visual type for SpriteRenderer');
        }
      }
    }

    canvas.drawAtlas(
        currentImage!, transforms, rects, null, null, null, currentPaint!);
  }
}
