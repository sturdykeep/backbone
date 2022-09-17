import 'package:backbone/position_node.dart';
import 'package:backbone/trait.dart';
import 'package:example/drag_rect.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

/// Used to react on game resize events
class GameResizeTrait extends ATrait {
  final VoidCallback resized;
  GameResizeTrait(this.resized);
}

/// Used to find nodes that spawn dragBoxes, like a tag
class DragBoxSpawnerTrait extends ATrait {}

class DragBar extends PositionNode {
  static const double space = 80;

  void setPositionAndSize({Vector2? screenSize}) {
    screenSize ??= gameRef.size;
    if (screenSize.x >= screenSize.y) {
      transformTrait.position = Vector2(0, screenSize.y - space);
      transformTrait.size = Vector2(screenSize.x, space);
    } else {
      transformTrait.position = Vector2(screenSize.x - space, 0);
      transformTrait.size = Vector2(space, screenSize.y);
    }
  }

  DragBar(Vector2 screenSize) {
    addTrait(GameResizeTrait(setPositionAndSize));
    addTrait(DragBoxSpawnerTrait());
    setPositionAndSize(screenSize: screenSize);
  }

  @override
  Future<void>? onLoad() {
    add(DragRect(Vector2(transformTrait.size.x / 2, 40)));
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(transformTrait.rect, debugPaint);
  }
}
