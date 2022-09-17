import 'dart:math';

import 'package:backbone/position_node.dart';
import 'package:backbone/prelude/input/plugins/drag.dart';
import 'package:example/bouncer.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

class DragRect extends PositionNode {
  final Vector2 fixedSize = Vector2.all(60);
  late final Color color;
  final rng = Random();

  DragRect(Vector2 position) {
    // Create a random color
    color = Color((rng.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
    // Set position and size

    transformTrait.size = fixedSize;
    transformTrait.position = position;
    transformTrait.anchor = Anchor.center;

    // Create callbacks for drag events
    final draggableTrait = DraggableTrait(
      onUpdate: (pointer) {
        transformTrait.position = absoluteToLocal(pointer.position);
      },
      onEnd: (pointer, node) {
        final bouncer = BouncerNode(
            Vector2.all(50.0 + 50.0 * rng.nextDouble()),
            color,
            (Vector2.all(-1.0) + Vector2.random(rng) * 2.0),
            200.0 + 200.0 * rng.nextDouble());
        bouncer.transformTrait.position = pointer.position;
        realm!.add(bouncer);
      },
    );
    addTrait(draggableTrait);
  }

  @override
  Future<void>? onLoad() {
    // Add the actual visible element of this node
    add(RectangleComponent(
        size: transformTrait.size, paint: Paint()..color = color));
    return super.onLoad();
  }
}
