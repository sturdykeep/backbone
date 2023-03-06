import 'dart:math';

import 'package:backbone/filter.dart';
import 'package:backbone/position_node.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/input/plugins/selectable.dart';
import 'package:backbone/prelude/time.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:example/bouncer.dart';
import 'package:example/dash.dart';
import 'package:example/messages.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/services.dart';

import 'template_bar.dart';

/// System that bounces boxes off screen edges
void bounceSystem(Realm realm) {
  final time = realm.resource<Time>();
  final realmQuery = realm.query(Has([Transform, BouncerTrait]));
  // or
  // final realmQuery = realm.query(And([Has([TransformTrait]), Has([BouncerTrait])]));
  final dragBarQuery = realm.query(Has([TemplateSpawnerTrait, Transform]));
  final dragBarTransform = dragBarQuery.first.get<Transform>();
  final dragBarSize = Vector2(
      dragBarTransform.position.y == 0 ? TemplateBar.space : 0,
      dragBarTransform.position.x == 0 ? TemplateBar.space : 0);
  final gameSizeWithoutDragBar = realm.gameRef.canvasSize - dragBarSize;
  for (final node in realmQuery) {
    final bounceTrait = node.get<BouncerTrait>();

    final transform = node.get<Transform>();

    // Move them in the direction at the speed of `speed` pixels per second
    transform.position +=
        bounceTrait.direction.normalized() * time.delta * bounceTrait.speed;

    // Now bounce them from edges
    if (transform.position.x < 0) {
      bounceTrait.direction.x = bounceTrait.direction.x.abs();
    }
    if (transform.position.x + transform.size.x > gameSizeWithoutDragBar.x) {
      bounceTrait.direction.x = -bounceTrait.direction.x.abs();
    }
    if (transform.position.y < 0) {
      bounceTrait.direction.y = bounceTrait.direction.y.abs();
    }
    if (transform.position.y + transform.size.y > gameSizeWithoutDragBar.y) {
      bounceTrait.direction.y = -bounceTrait.direction.y.abs();
    }
  }
}

/// System that spawns new boxes on click
void tapSpawnSystem(Realm realm) {
  final rng = Random();
  final input = realm.resource<Input>();
  final pointers = input.justReleasedPointers();
  for (var pointer in pointers) {
    if (pointer.handled == false) {
      late final PositionNode bouncer;
      if (rng.nextBool()) {
        bouncer = DashNode(
          direction: (Vector2.all(-1.0) + Vector2.random(rng) * 2.0),
          speed: 200.0 + 200.0 * rng.nextDouble(),
        );
      } else {
        bouncer = BouncerNode(
            Vector2.all(50.0 + 50.0 * rng.nextDouble()),
            Color.fromARGB(
                255,
                (rng.nextDouble() * 255.0).toInt(),
                (rng.nextDouble() * 255.0).toInt(),
                (rng.nextDouble() * 255.0).toInt()),
            (Vector2.all(-1.0) + Vector2.random(rng) * 2.0),
            200.0 + 200.0 * rng.nextDouble());
      }

      bouncer.transformTrait.position = pointer.position;
      realm.add(bouncer);
    }
  }
}

void deleteRemoveSystem(Realm realm) {
  final selected = realm.resource<Selection>();
  final toRemove = selected.entities.toList();
  final input = realm.resource<Input>();
  if (input.justPressed(LogicalKeyboardKey.delete)) {
    for (final node in toRemove) {
      realm.pushMessage(RemoveBouncerMessage(node as BouncerNode));
    }
  }
}
