import 'dart:math';

import 'package:backbone/builders.dart';
import 'package:backbone/entity.dart';
import 'package:backbone/prelude/input/plugins/hoverable.dart';
import 'package:backbone/prelude/mod.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:flame/extensions.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:playground/games/base.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/render/rectangle.dart';

class TransformGame extends PlaygroundGame {
  TransformGame();

  @override
  Realm realmBuilder() {
    return RealmBuilder().withPlugin(defaultPlugin).build();
  }

  Entity buildRectangle({Entity? parent, Color? color}) {
    final entity = Entity(realm);
    entity.parent = parent;

    final transform = Transform();
    transform.size = Vector2(50, 50);
    entity.add(transform);

    final renderTrait = Renderable();
    entity.add(renderTrait);

    final rectangle = RectangleVisual(color ?? Colors.blue);
    renderTrait.visual = rectangle;

    Color oldColor = rectangle.color;
    final hoverable = Hoverable(onHoverEnter: (p) {
      oldColor = rectangle.color;
      rectangle.color = Colors.red;
    }, onHoverExit: (p) {
      rectangle.color = oldColor;
    });
    entity.add(hoverable);

    return entity;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Just a simple rectangle with size
    await sampleOne();
    // Two rectangles, one turned 45 degrees
    await sampleTwo();
    // Rectangle with a center anchor
    await sampleThree();
    // A box with a center anchor and it's child with a center anchor
    // but smaller, lives at 0,0
    await sampleFour();
    // A box with a center anchor and it's child with a normal anchor
    // but smaller, lives at 0,0
    await sampleFive();
    // A box with a center anchor and it's child with a normal anchor
    // but smaller, lives at 0,0 and is rotated 45 degrees
    await sampleSix();
    // Same as before, but first box is also rotated 45 degrees
    await sampleSeven();
    // First box with normal anchor, second box is rotated 10 degrees at 0,0
    // each next box is rotated 10 degrees more
    await sampleEight();
  }

  Future<void> sampleOne() async {
    final entity = buildRectangle();
    final transform = entity.get<Transform>();
    transform.position = Vector2(10, 10);
    realm.registerEntity(entity);
  }

  Future<void> sampleTwo() async {
    final entity = buildRectangle();
    final transform = entity.get<Transform>();
    transform.position = Vector2(150, 10);
    transform.rotationDegrees = 45;
    realm.registerEntity(entity);

    // Second rectangle, offset by 0,10
    final entity2 = buildRectangle();
    final transform2 = entity2.get<Transform>();
    transform2.position = Vector2(0, 50 + 10);
    realm.registerEntity(entity2);
    entity2.parent = entity;
  }

  Future<void> sampleThree() async {
    final entity = buildRectangle();
    final transform = entity.get<Transform>();
    transform.position = Vector2(250, 10 + 50 / 2);
    transform.anchor = Anchor.center;
    realm.registerEntity(entity);
  }

  Future<void> sampleFour() async {
    final entity = buildRectangle();
    final transform = entity.get<Transform>();
    transform.position = Vector2(350, 10 + 50 / 2);
    transform.anchor = Anchor.center;
    realm.registerEntity(entity);

    // Second rectangle
    final entity2 = buildRectangle();
    final transform2 = entity2.get<Transform>();
    transform2.position = Vector2(0, 0);
    transform2.size = Vector2(25, 25);
    transform2.anchor = Anchor.center;
    transform2.rotationDegrees = 45;
    realm.registerEntity(entity2);
    entity2.parent = entity;

    // Set color of child
    final renderTrait = entity2.get<Renderable>();
    final rectangle = renderTrait.visual as RectangleVisual;
    rectangle.color = Colors.green;
  }

  Future<void> sampleFive() async {
    final entity = buildRectangle();
    final transform = entity.get<Transform>();
    transform.position = Vector2(450, 10 + 50 / 2);
    transform.anchor = Anchor.center;
    realm.registerEntity(entity);

    // Second rectangle
    final entity2 = buildRectangle();
    final transform2 = entity2.get<Transform>();
    transform2.position = Vector2(0, 0);
    transform2.size = Vector2(25, 25);
    realm.registerEntity(entity2);
    entity2.parent = entity;

    // Set color of child
    final renderTrait = entity2.get<Renderable>();
    final rectangle = renderTrait.visual as RectangleVisual;
    rectangle.color = Colors.green;
  }

  Future<void> sampleSix() async {
    final entity = buildRectangle();
    final transform = entity.get<Transform>();
    transform.position = Vector2(550, 10 + 50 / 2);
    transform.anchor = Anchor.center;
    realm.registerEntity(entity);

    // Second rectangle
    final entity2 = buildRectangle();
    final transform2 = entity2.get<Transform>();
    transform2.position = Vector2(0, 0);
    transform2.size = Vector2(25, 25);
    transform2.rotationDegrees = 45;
    realm.registerEntity(entity2);
    entity2.parent = entity;

    // Set color of child
    final renderTrait = entity2.get<Renderable>();
    final rectangle = renderTrait.visual as RectangleVisual;
    rectangle.color = Colors.green;
  }

  Future<void> sampleSeven() async {
    final entity = buildRectangle();
    final transform = entity.get<Transform>();
    transform.position = Vector2(650, 10 + 50 / 2);
    transform.anchor = Anchor.center;
    transform.rotationDegrees = 45;
    realm.registerEntity(entity);

    // Second rectangle
    final entity2 = buildRectangle();
    final transform2 = entity2.get<Transform>();
    transform2.position = Vector2(0, 0);
    transform2.size = Vector2(25, 25);
    transform2.rotationDegrees = 45;
    realm.registerEntity(entity2);
    entity2.parent = entity;

    // Set color of child
    final renderTrait = entity2.get<Renderable>();
    final rectangle = renderTrait.visual as RectangleVisual;
    rectangle.color = Colors.green;
  }

  Future<void> sampleEight() async {
    final entity = buildRectangle();
    final transform = entity.get<Transform>();
    transform.position = Vector2(720, 10);
    realm.registerEntity(entity);

    // Second rectangle
    final entity2 = buildRectangle();
    final transform2 = entity2.get<Transform>();
    transform2.position = Vector2(50, 50);
    transform2.rotationDegrees = 10;
    realm.registerEntity(entity2);
    entity2.parent = entity;

    // Set color of child
    final renderTrait = entity2.get<Renderable>();
    final rectangle = renderTrait.visual as RectangleVisual;
    rectangle.color = Colors.green;

    // Third rectangle
    final entity3 = buildRectangle();
    final transform3 = entity3.get<Transform>();
    transform3.position = Vector2(50, 50);
    transform3.rotationDegrees = 10;
    realm.registerEntity(entity3);
    entity3.parent = entity2;

    // Set color of child
    final renderTrait3 = entity3.get<Renderable>();
    final rectangle3 = renderTrait3.visual as RectangleVisual;
    rectangle3.color = Colors.blue;

    // Fourth rectangle
    final entity4 = buildRectangle();
    final transform4 = entity4.get<Transform>();
    transform4.position = Vector2(50, 50);
    transform4.rotationDegrees = 10;
    realm.registerEntity(entity4);
    entity4.parent = entity3;

    // Set color of child
    final renderTrait4 = entity4.get<Renderable>();
    final rectangle4 = renderTrait4.visual as RectangleVisual;
    rectangle4.color = Colors.yellow;
  }
}
