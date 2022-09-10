import 'dart:math';

import 'package:backbone/builders.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:example/bouncer.dart';
import 'package:example/message_systems.dart';
import 'package:example/systems.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MainGame extends FlameGame
    with HasTappableComponents, HasDraggableComponents {
  late final Realm realm;

  @override
  void onTapDown(TapDownEvent event) {
    realm.onTapDown(event);
    super.onTapDown(event);
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    realm.onLongTapDown(event);
    super.onLongTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    realm.onTapUp(event);
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    realm.onTapCancel(event);
    super.onTapCancel(event);
  }

  @override
  void onDragStart(DragStartEvent event) {
    realm.onDragStart(event);
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    realm.onDragUpdate(event);
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    realm.onDragEnd(event);
    super.onDragEnd(event);
  }

  @override
  Future<void> onLoad() async {
    realm = RealmBuilder()
        .withPlugin(transformPlugin)
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
