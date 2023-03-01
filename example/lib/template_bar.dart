import 'dart:async';

import 'package:backbone/position_node.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/trait.dart';
import 'package:example/template.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

/// Used to react on game resize events
class GameResizeTrait extends Trait {
  final VoidCallback resized;
  GameResizeTrait(this.resized);
}

/// Used to find nodes that spawn dragBoxes, like a tag
class TemplateSpawnerTrait extends Trait {}

class TemplateBar extends PositionNode {
  static const double space = 80;
  bool landscapeMode = false;
  final Paint barBorderPaint = Paint()..color = Colors.white;

  void setPositionAndSize({Vector2? screenSize}) {
    screenSize ??= gameRef.size;
    if (screenSize.x >= screenSize.y) {
      transformTrait.position = Vector2(0, screenSize.y - space);
      transformTrait.size = Vector2(screenSize.x, space);
      landscapeMode = true;
    } else {
      transformTrait.position = Vector2(screenSize.x - space, 0);
      transformTrait.size = Vector2(space, screenSize.y);
      landscapeMode = false;
    }

    // Update children
    if (hasChildren) {
      (findNodeChildren().first as PositionNode).transformTrait.position =
          getChildStartingPosition();
    }
    if (entity.children.length > 1) {
      entity.children.first.tryGet<TransformTrait>()!.position =
          getChildStartingPosition();
    }
  }

  Vector2 getChildStartingPosition() {
    if (landscapeMode) {
      return Vector2(transformTrait.size.x / 2, 40);
    }
    return Vector2(40, transformTrait.size.y / 2);
  }

  TemplateBar(Vector2 screenSize) {
    entity.add(GameResizeTrait(setPositionAndSize));
    entity.add(TemplateSpawnerTrait());
    setPositionAndSize(screenSize: screenSize);
  }

  @override
  void onMount() {
    super.onMount();
    buildTemplate(realm!, this, getChildStartingPosition());
  }

  @override
  void render(Canvas canvas) {
    // canvas.drawRect(
    //     Rect.fromLTWH(
    //       0,
    //       0,
    //       transformTrait.size.x,
    //       transformTrait.size.y,
    //     ),
    //     barBorderPaint);
  }
}
