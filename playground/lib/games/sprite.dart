import 'dart:ui';

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

class SpriteGame extends PlaygroundGame {
  late Sprite dashSprite;

  SpriteGame();

  Entity createSpriteEntity(Sprite sprite) {
    final entity = Entity(realm);
    final transform = Transform();
    transform.size = Vector2.all(150);
    entity.add(transform);
    final renderTrait = Renderable();
    renderTrait.visual = SpriteVisual(sprite: sprite);
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

    dashSprite = await loadSprite('dash.png');

    // Create first dash sprite at 10,10
    final dash1 = createSpriteEntity(dashSprite);
    dash1.get<Transform>().position = Vector2(10, 10);
    realm.registerEntity(dash1);

    // Same as before, but anchored to the center
    final dash2 = createSpriteEntity(dashSprite);
    dash2.get<Transform>().position = Vector2(180 + 150 / 2, 10 + 150 / 2);
    dash2.get<Transform>().anchor = Anchor.center;
    realm.registerEntity(dash2);

    // Centered sprite with another one painted green on top
    // scaled 0.5 and rotated 45 degrees
    final dash3 = createSpriteEntity(dashSprite);
    dash3.get<Transform>().position = Vector2(360 + 150 / 2, 10 + 150 / 2);
    dash3.get<Transform>().anchor = Anchor.center;
    realm.registerEntity(dash3);

    final dash4 = createSpriteEntity(dashSprite);
    dash4.get<Transform>().position = Vector2(0, 0);
    dash4.get<Transform>().anchor = Anchor.center;
    dash4.get<Transform>().scale = Vector2.all(0.5);
    dash4.get<Transform>().rotationDegrees = 45;
    realm.registerEntity(dash4);
    dash4.parent = dash3;

    // Build a "scorpion tail" with 4 sprites one after the other
    final dash5 = createSpriteEntity(dashSprite);
    dash5.get<Transform>().position = Vector2(540, 10);
    realm.registerEntity(dash5);

    final dash6 = createSpriteEntity(dashSprite);
    dash6.get<Transform>().position = Vector2(150, 150);
    dash6.get<Transform>().rotationDegrees = 10;
    dash6.get<Transform>().scale = Vector2.all(0.5);
    realm.registerEntity(dash6);
    dash6.parent = dash5;

    final dash7 = createSpriteEntity(dashSprite);
    dash7.get<Transform>().position = Vector2(150, 150);
    dash7.get<Transform>().rotationDegrees = 10;
    dash7.get<Transform>().scale = Vector2.all(0.5);
    realm.registerEntity(dash7);
    dash7.parent = dash6;

    final dash8 = createSpriteEntity(dashSprite);
    dash8.get<Transform>().position = Vector2(150, 150);
    dash8.get<Transform>().rotationDegrees = 10;
    dash8.get<Transform>().scale = Vector2.all(0.5);
    realm.registerEntity(dash8);
    dash8.parent = dash7;

    // A sample with override green paint
    final dash9 = createSpriteEntity(dashSprite);
    dash9.get<Transform>().position = Vector2(750, 10);
    dash9.get<Renderable>().as<SpriteVisual>().overrideColor = Colors.green;
    realm.registerEntity(dash9);

    // Draw three sprites on top of each other with reversed priority
    final dash10 = createSpriteEntity(dashSprite);
    dash10.get<Transform>().position = Vector2(10, 200);
    dash10.get<Transform>().priority = 3;
    realm.registerEntity(dash10);

    final dash11 = createSpriteEntity(dashSprite);
    dash11.get<Transform>().position = Vector2(60, 200);
    dash11.get<Transform>().priority = 2;
    dash11.get<Renderable>().as<SpriteVisual>().overrideColor = Colors.red;
    realm.registerEntity(dash11);

    final dash12 = createSpriteEntity(dashSprite);
    dash12.get<Transform>().position = Vector2(110, 200);
    dash12.get<Transform>().priority = 1;
    realm.registerEntity(dash12);
  }
}
