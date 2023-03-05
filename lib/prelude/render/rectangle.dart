import 'package:backbone/entity.dart';
import 'package:backbone/prelude/render/mod.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/render/visual.dart';
import 'package:backbone/realm.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

class RectangleVisual extends Visual {
  Color color;

  RectangleVisual(this.color);
}

class RectangleRenderer extends Renderer {
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
      final visual = renderee.matchedVisual as RectangleVisual;
      final transform = renderee.transformTrait;

      if (transform != null) {
        final paint = Paint()..color = visual.color;
        canvas.save();
        canvas.transform(transform.globalTransformMatrix.storage);
        canvas.drawRect(transform.localRect, paint);
        canvas.restore();
      }
    }
  }
}
