import 'dart:ui';

import 'package:backbone/entity.dart';
import 'package:backbone/prelude/render/mod.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';

class RectangleRenderer extends Renderer {
  @override
  Trait? matches(Entity entity) {
    return entity.tryGet<RectangleTrait>();
  }

  @override
  void render(Iterable<Renderee> renderees, Realm realm, Canvas canvas) {
    for (final renderee in renderees) {
      final rectangleTrait = renderee.matchedTrait as RectangleTrait;
      final transformTrait = renderee.transformTrait;

      if (transformTrait != null) {
        final paint = Paint()..color = rectangleTrait.color;
        canvas.save();
        canvas.transform(transformTrait.transformMatrix.storage);
        canvas.drawRect(transformTrait.localRect, paint);
        canvas.restore();
      }
    }
  }
}

class RectangleTrait extends Trait {
  RectangleTrait(this.color);

  final Color color;
}