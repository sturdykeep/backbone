import 'dart:math';
import 'dart:ui';

import 'package:backbone/builders.dart';
import 'package:backbone/entity.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/pointer.dart';
import 'package:backbone/prelude/mod.dart';
import 'package:backbone/prelude/time.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:flame/extensions.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:playground/games/base.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/render/rectangle.dart';

class PlayerTrait extends Trait {}

// System that takes the current mouse position and rotates the player
// to face it
void rotateSystem(Realm realm) {
  final query = realm.query(Has([PlayerTrait]));
  final player = query.first;
  final transform = player.get<Transform>();

  final input = realm.getResource<Input>();
  final mouseInputs = input.pointers().where(
      (p) => p.kind == PointerDeviceKind.mouse && p.state is PointerStateHover);
  final mouse = mouseInputs.isNotEmpty ? mouseInputs.first : null;
  if (mouse != null) {
    final mousePos = mouse.position;
    final playerPos = transform.position;
    final angle = atan2(mousePos.y - playerPos.y, mousePos.x - playerPos.x);
    transform.rotation = angle;
  }
}

// System that moves the player around using WASD
void moveSystem(Realm realm) {
  final query = realm.query(Has([PlayerTrait]));
  final player = query.first;
  final transform = player.get<Transform>();

  final input = realm.getResource<Input>();
  final time = realm.getResource<Time>();
  const speed = 400.0;
  if (input.pressed(LogicalKeyboardKey.keyW)) {
    transform.position += Vector2(0, -speed * time.delta);
  }
  if (input.pressed(LogicalKeyboardKey.keyA)) {
    transform.position += Vector2(-speed * time.delta, 0);
  }
  if (input.pressed(LogicalKeyboardKey.keyS)) {
    transform.position += Vector2(0, speed * time.delta);
  }
  if (input.pressed(LogicalKeyboardKey.keyD)) {
    transform.position += Vector2(speed * time.delta, 0);
  }
}

class TopdownGame extends PlaygroundGame {
  TopdownGame();

  @override
  Realm realmBuilder() {
    return RealmBuilder()
        .withPlugin(defaultPlugin)
        .withTrait(PlayerTrait)
        .withSystem(rotateSystem)
        .withSystem(moveSystem)
        .build();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final playerEntity = Entity();
    final playerTransform = Transform();
    playerTransform.position = Vector2(100, 100);
    playerTransform.size = Vector2(100, 100);
    playerTransform.anchor = Anchor.center;
    playerEntity.add(playerTransform);
    playerEntity.add(PlayerTrait());
    final render = Renderable();
    final rectangle = RectangleVisual(Colors.blue);
    render.visual = rectangle;
    playerEntity.add(render);
    realm.addEntity(playerEntity);
  }
}
