import 'dart:math';
import 'dart:ui';

import 'package:backbone/builders.dart';
import 'package:backbone/entity.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/mod.dart';
import 'package:backbone/prelude/render/sprite.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/time.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:flame/components.dart';
import 'package:playground/games/base.dart';
import 'package:window_manager/window_manager.dart';

class ResourceHolder {
  late Sprite dashSprite;

  ResourceHolder();
}

void dashSpawner(Realm realm) {
  final time = realm.resource<Time>();
  final input = realm.resource<Input>();
  final mouse = input.mouse();

  if (mouse != null && mouse.isPressed) {
    const amountPerSecond = 1000;
    final amount = (amountPerSecond * time.delta).toInt();
    for (var i = 0; i < amount; i++) {
      // Create a dash at 0,0 every frame
      final dash =
          DashEntity(realm, realm.resource<ResourceHolder>().dashSprite);
      dash.get<Transform>().position = mouse.position;
      dash.get<DashTrait>().velocity = Vector2(
        4 * cos(i * 2 * pi / amount),
        4 * sin(i * 2 * pi / amount),
      );
      realm.registerEntity(dash);
    }
  }
}

// Makes dashes bounce up and down, off walls too, like in bunnymark from PixiJS
void dashBouncer(Realm realm) {
  final query = realm.query(Has([DashTrait]));
  for (final entity in query) {
    final dash = entity.get<DashTrait>();
    final transform = entity.get<Transform>();

    // Move the dash
    transform.position += dash.velocity;

    // Bounce off walls
    if (transform.position.x < 0) {
      transform.position.x = 0;
      dash.velocity.x = -dash.velocity.x;
    } else if (transform.position.x > realm.gameRef.size.x) {
      transform.position.x = realm.gameRef.size.x;
      dash.velocity.x = -dash.velocity.x;
    }

    if (transform.position.y < 0) {
      transform.position.y = 0;
      dash.velocity.y = -dash.velocity.y;
    } else if (transform.position.y > realm.gameRef.size.y) {
      transform.position.y = realm.gameRef.size.y;
      dash.velocity.y = -dash.velocity.y;
    }

    // Add gravity
    dash.velocity += Vector2(0, 0.3);
  }
}

class DashTrait extends Trait {
  Vector2 velocity = Vector2(4, 0);
}

class DashEntity extends Entity {
  DashEntity(super.realm, Sprite sprite) {
    add(DashTrait());
    final transform = Transform();
    transform.size = Vector2.all(50);
    transform.anchor = Anchor.center;
    add(transform);
    final renderTrait = Renderable();
    renderTrait.visual = SpriteVisual(sprite: sprite);
    add(renderTrait);
  }
}

class DashmarkGame extends PlaygroundGame {
  late Sprite dashSprite;

  DashmarkGame();

  @override
  Realm realmBuilder() {
    return RealmBuilder()
        .withPlugin(defaultPlugin)
        .withResource(ResourceHolder, ResourceHolder())
        .withTrait(DashTrait)
        .withSystem(dashSpawner)
        .withSystem(dashBouncer)
        .build();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    dashSprite = await loadSprite('dash.png');
    realm.resource<ResourceHolder>().dashSprite = dashSprite;
  }

  final lastFrameTimes = <double>[];
  @override
  void update(double dt) {
    super.update(dt);

    lastFrameTimes.add(dt);
    // keep the list max length
    if (lastFrameTimes.length > 10) {
      lastFrameTimes.removeAt(0);
    }
    final fps =
        1 / (lastFrameTimes.fold(0.0, (a, b) => a + b) / lastFrameTimes.length);
    final fpsRounded = fps.round();
    final entities = realm.query(Has([DashTrait])).length;
    windowManager.ensureInitialized();
    windowManager.setTitle('Dashmark - $fpsRounded FPS - $entities entities');
  }
}
