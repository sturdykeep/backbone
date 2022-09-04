import 'dart:math';

import 'package:backbone/filter.dart';
import 'package:backbone/prelude/input.dart';
import 'package:backbone/prelude/time.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/world.dart';
import 'package:example/bouncer.dart';
import 'package:flame/extensions.dart';

// System that bounces boxes off screen edges
void bounceSystem(World world) {
  final time = world.getResource<Time>();
  final worldQuery = world.query(Has([TransformTrait, BouncerTrait]));
  // or
  // final worldQuery = world.query(And([Has([TransformTrait]), Has([BouncerTrait])]));
  final queryLength = worldQuery.length;
  for (var i = 0; i < queryLength; i++) {
    final node = worldQuery.elementAt(i) as BouncerNode;
    final transform = node.transform;

    // Move them in the direction at the speed of `speed` pixels per second
    transform.position += node.direction.normalized() * time.delta * node.speed;

    // Now bounce them from edges
    if (transform.position.x < 0) {
      node.direction.x = node.direction.x.abs();
    }
    if (transform.position.x + transform.size.x > world.gameRef.canvasSize.x) {
      node.direction.x = -node.direction.x.abs();
    }
    if (transform.position.y < 0) {
      node.direction.y = node.direction.y.abs();
    }
    if (transform.position.y + transform.size.y > world.gameRef.canvasSize.y) {
      node.direction.y = -node.direction.y.abs();
    }
  }
}

// System that spawns new boxes on click
void tapSpawnSystem(World world) {
  final rng = Random();
  final input = world.getResource<Input>();
  final ups = input.tapUps;
  for (var i = 0; i < ups.length; i++) {
    final id = ups.elementAt(i);
    final info = input.taps[id];
    if (info != null && info.handled == false) {
      final bouncer = BouncerNode(
          Vector2.all(50.0 + 50.0 * rng.nextDouble()),
          Color.fromARGB(
              255,
              (rng.nextDouble() * 255.0).toInt(),
              (rng.nextDouble() * 255.0).toInt(),
              (rng.nextDouble() * 255.0).toInt()),
          (Vector2.all(-1.0) + Vector2.random(rng) * 2.0),
          200.0 + 200.0 * rng.nextDouble());
      bouncer.transform.position = info.eventPosition.game;
      world.add(bouncer);
    }
  }
}
