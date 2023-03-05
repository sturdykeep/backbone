import 'dart:ui';

import 'package:backbone/entity.dart';
import 'package:backbone/prelude/render/mod.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/render/visual.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';

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
    for (final renderee in renderees) {
      SpriteVisual? spriteVisual;
      SpriteAnimationVisual? animationVisual;
      final transformTrait = renderee.transformTrait;

      if (renderee.matchedVisual is SpriteVisual) {
        spriteVisual = renderee.matchedVisual as SpriteVisual;
      } else if (renderee.matchedVisual is SpriteAnimationVisual) {
        animationVisual = renderee.matchedVisual as SpriteAnimationVisual;
      }

      if (transformTrait != null) {
        final paint = Paint()..color = rectangleTrait.color;
        canvas.save();
        canvas.transform(transformTrait.globalTransformMatrix.storage);
        canvas.drawRect(transformTrait.localRect, paint);
        canvas.restore();
      }
    }
  }
}
