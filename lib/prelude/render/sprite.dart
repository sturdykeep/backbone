import 'package:backbone/entity.dart';
import 'package:backbone/prelude/render/mod.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/render/visual.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SpriteVisual extends Visual {
  Sprite? sprite;
  SpriteVisual({this.sprite});
}

class SpriteAnimationVisual extends Visual {
  SpriteAnimation? animation;
  SpriteAnimationVisual({this.animation});
}

class SpriteRenderer extends Renderer {
  @override
  Visual? matches(Entity entity) {
    final renderTrait = entity.tryGet<Renderable>();
    if (renderTrait != null) {
      final visual = renderTrait.visual;
      if (visual is RectangleVisual) {
        return visual;
      }
    }
    return null;
  }

  @override
  void render(Iterable<Renderee> renderees, Realm realm, Canvas canvas) {
    for (final renderee in renderees) {
      final rectangleTrait = renderee.matchedVisual as RectangleVisual;
      final transformTrait = renderee.transformTrait;

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
