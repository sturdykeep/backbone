import 'dart:math';

import 'package:backbone/builders.dart';
import 'package:backbone/entity.dart';
import 'package:backbone/prelude/mod.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:flame/extensions.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:playground/games/base.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/render/rectangle.dart';

Entity buildRectangle({Entity? parent, Color? color}) {
  final entity = Entity();
  entity.parent = parent;

  final transform = Transform();
  transform.size = Vector2(50, 50);
  entity.add(transform);

  final renderTrait = Renderable();
  entity.add(renderTrait);

  final rectangle = RectangleVisual(color ?? Colors.blue);
  renderTrait.visual = rectangle;

  return entity;
}

class TransformGame extends PlaygroundGame {
  TransformGame();

  @override
  Realm realmBuilder() {
    return RealmBuilder().withPlugin(defaultPlugin).build();
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
  }

  Future<void> sampleOne() async {
    final entity = buildRectangle();
    final transform = entity.get<Transform>();
    transform.position = Vector2(10, 10);
    realm.addEntity(entity);
  }

  Future<void> sampleTwo() async {
    final entity = buildRectangle();
    final transform = entity.get<Transform>();
    transform.position = Vector2(150, 10);
    transform.rotation = 45 * (pi / 180);
    realm.addEntity(entity);

    // Second rectangle, offset by 0,10
    final entity2 = buildRectangle();
    final transform2 = entity2.get<Transform>();
    transform2.position = Vector2(0, 50 + 10);
    realm.addEntity(entity2);
    entity2.parent = entity;
  }

  Future<void> sampleThree() async {
    final entity = buildRectangle();
    final transform = entity.get<Transform>();
    transform.position = Vector2(250, 10 + 50 / 2);
    transform.anchor = Anchor.center;
    realm.addEntity(entity);
  }

  Future<void> sampleFour() async {
    final entity = buildRectangle();
    final transform = entity.get<Transform>();
    transform.position = Vector2(350, 10 + 50 / 2);
    transform.anchor = Anchor.center;
    realm.addEntity(entity);

    // Second rectangle
    final entity2 = buildRectangle();
    final transform2 = entity2.get<Transform>();
    transform2.position = Vector2(0, 0);
    transform2.size = Vector2(25, 25);
    transform2.anchor = Anchor.center;
    realm.addEntity(entity2);
    entity2.parent = entity;

    // Set color of child
    final renderTrait = entity2.get<Renderable>();
    final rectangle = renderTrait.visual as RectangleVisual;
    rectangle.color = Colors.red;
  }
}
