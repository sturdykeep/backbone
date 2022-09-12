import 'dart:math';

import 'package:backbone/backbone.dart';
import 'package:backbone/builders.dart';
import 'package:backbone/realm.dart';
import 'package:example/bouncer.dart';
import 'package:example/message_systems.dart';
import 'package:example/systems.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MainGame extends FlameGame
    with
        HasTappableComponents,
        HasDraggableComponents,
        KeyboardEvents,
        HasHoverables,
        HasRealm {
  @override
  Future<void> onLoad() async {
    realm = RealmBuilder()
        .withPlugin(defaultPlugin)
        .withTrait(BouncerTrait)
        .withSystem(bounceSystem)
        .withSystem(tapSpawnSystem)
        .withMessageSystem(removeBounceMessageSystem)
        .build();
    add(realm);

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
      realm.add(bouncer);
    }
  }
}
