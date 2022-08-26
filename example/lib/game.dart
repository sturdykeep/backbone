import 'dart:math';

import 'package:backbone/builders.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/world.dart';
import 'package:example/bouncer.dart';
import 'package:example/message_systems.dart';
import 'package:example/systems.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MainGame extends FlameGame with HasTappables {
  late final World world;
  MainGame();

  @override
  void onTapDown(int pointerId, TapDownInfo info) {
    super.onTapDown(pointerId, info);
    world.onTapDown(pointerId, info);
  }

  @override
  void onTapUp(int pointerId, TapUpInfo info) {
    super.onTapUp(pointerId, info);
    world.onTapUp(pointerId, info);
  }

  @override
  void onTapCancel(int pointerId) {
    super.onTapCancel(pointerId);
    world.onTapCancel(pointerId);
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
