import 'dart:math';

import 'package:backbone/builders.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/world.dart';
import 'package:example/bouncer.dart';
import 'package:example/message_systems.dart';
import 'package:example/systems.dart';
import 'package:flame/experimental.dart' hide World;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MainGame extends FlameGame
    with HasTappableComponents, HasDraggableComponents {
  late final World world;

  @override
  void onTapDown(TapDownEvent event) {
    world.onTapDown(event);
    super.onTapDown(event);
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    world.onLongTapDown(event);
    super.onLongTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    world.onTapUp(event);
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    world.onTapCancel(event);
    super.onTapCancel(event);
  }

  @override
  void onDragStart(DragStartEvent event) {
    world.onDragStart(event);
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    world.onDragUpdate(event);
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    world.onDragEnd(event);
    super.onDragEnd(event);
  }

  @override
  Future<void> onLoad() async {
    world = WorldBuilder()
        .withPlugin(transformPlugin)
        .withTrait(BouncerTrait)
        .withSystem(bounceSystem)
        .withSystem(tapSpawnSystem)
        .withMessageSystem(removeBounceMessageSystem)
        .build();
    add(world);

    // Generate some bouncers
    final rng = Random();
    for (var i = 0; i < 5; i++) {
      final bouncer = BouncerNode(
          Vector2.all(50.0 + 50.0 * rng.nextDouble()),
          Color.fromARGB(
              255,
              (rng.nextDouble() * 255.0).toInt(),
              (rng.nextDouble() * 255.0).toInt(),
              (rng.nextDouble() * 255.0).toInt()),
          (Vector2.all(-1.0) + Vector2.random(rng) * 2.0),
          200.0 + 200.0 * rng.nextDouble());
      bouncer.transform.position = Vector2(canvasSize.x / 2, canvasSize.y / 2);
      world.add(bouncer);
    }
  }
}
