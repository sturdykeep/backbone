import 'dart:math';

import 'package:backbone/node.dart';
import 'package:backbone/prelude/input/plugins/drag.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:example/bouncer.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

class DragRect extends ANode {
  final Vector2 size;
  final Color color;
  final rng = Random();
  TransformTrait get transform => get<TransformTrait>();

  DragRect(this.size, this.color, Vector2 position) {
    final transformTrait = TransformTrait();
    transformTrait.size = size;
    transformTrait.position = position;
    transformTrait.anchor = Anchor.center;
    addTrait(transformTrait);
    final draggableTrait = DraggableTrait(
      onUpdate: (pointer) {
        transform.position = pointer.position;
      },
      onEnd: (pointer, node) {
        final bouncer = BouncerNode(
            Vector2.all(50.0 + 50.0 * rng.nextDouble()),
            Color.fromARGB(
                255,
                (rng.nextDouble() * 255.0).toInt(),
                (rng.nextDouble() * 255.0).toInt(),
                (rng.nextDouble() * 255.0).toInt()),
            (Vector2.all(-1.0) + Vector2.random(rng) * 2.0),
            200.0 + 200.0 * rng.nextDouble());
        bouncer.transform.position = pointer.position;
        realm!.add(bouncer);
      },
    );
    addTrait(draggableTrait);
  }

  @override
  Future<void>? onLoad() {
    add(RectangleComponent(size: size, paint: Paint()..color = color));
    return super.onLoad();
  }
}
