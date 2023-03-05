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
      final rectangleTrait = renderee.matchedVisual as RectangleVisual;
      final transformTrait = renderee.transformTrait;

      if (transformTrait != null) {
        final paint = Paint()..color = rectangleTrait.color;
        canvas.save();
        canvas.transform(transformTrait.globalTransformMatrix.storage);
        canvas.drawRect(transformTrait.localRect, paint);
        canvas.restore();

        // For debugging, draw a circle at each transformed corner
        // of the rectangle
        final debugPaint = Paint()..color = Colors.red;
        final localRect = transformTrait.localRect;
        final corners = [
          localRect.topLeft,
          localRect.topRight,
          localRect.bottomRight,
          localRect.bottomLeft,
        ];
        for (final corner in corners) {
          canvas.drawCircle(
            transformTrait.globalTransformMatrix
                .transform2(corner.toVector2())
                .toOffset(),
            5,
            debugPaint,
          );
        }

        // Draw a circle at the center of the rectangle
        // based on calls to `toLocal` -> `toGlobal`
        final globalCenter = transformTrait.globalTransformMatrix
            .transform2(localRect.center.toVector2());
        final localCenter = transformTrait.toLocal(globalCenter);
        final newGlobalCenter = transformTrait.toWorld(localCenter);
        canvas.drawCircle(
          newGlobalCenter.toOffset(),
          5,
          debugPaint,
        );
      }
    }
  }
}
