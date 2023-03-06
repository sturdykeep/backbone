import 'package:backbone/builders.dart';
import 'package:backbone/entity.dart';
import 'package:backbone/prelude/mod.dart';
import 'package:backbone/prelude/render/sprite.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:playground/games/base.dart';

class AnimationGame extends PlaygroundGame {
  late SpriteAnimation explosion;

  AnimationGame();

  Entity createSpriteEntity(SpriteAnimation animation) {
    final entity = Entity();
    final transform = Transform();
    transform.size = Vector2.all(150);
    entity.add(transform);
    final renderTrait = Renderable();
    renderTrait.visual = SpriteAnimationVisual(animation: animation);
    entity.add(renderTrait);
    return entity;
  }

  @override
  Realm realmBuilder() {
    return RealmBuilder().withPlugin(defaultPlugin).build();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    explosion = await loadSpriteAnimation(
      'explosion.png',
      SpriteAnimationData.sequenced(
        stepTime: 0.2,
        amount: 6,
        textureSize: Vector2.all(32),
        loop: true,
      ),
    );

    // Create an explosion sprite at 10,10
    final explosion1 = createSpriteEntity(explosion);
    explosion1.get<Transform>().position = Vector2(10, 10);
    realm.addEntity(explosion1);

    // Crate an explosion with green tint center-anchored
    final explosion2 = createSpriteEntity(explosion);
    explosion2.get<Transform>().position = Vector2(180 + 150 / 2, 10 + 150 / 2);
    explosion2.get<Transform>().anchor = Anchor.center;
    explosion2.get<Renderable>().as<SpriteAnimationVisual>().overrideColor =
        Colors.green;
    realm.addEntity(explosion2);

    // Normal explosion, but rotated 45 degrees
    final explosion3 = createSpriteEntity(explosion);
    explosion3.get<Transform>().position = Vector2(360 + 150 / 2, 10 + 150 / 2);
    explosion3.get<Transform>().anchor = Anchor.center;
    explosion3.get<Transform>().rotationDegrees = 45;
    realm.addEntity(explosion3);
  }
}
