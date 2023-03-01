import 'dart:math';
import 'dart:ui';

import 'package:backbone/backbone.dart';
import 'package:backbone/builders.dart';
import 'package:backbone/entity.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/render/rectangle.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/realm_mixin.dart';
import 'package:backbone/trait.dart';
import 'package:example/bouncer.dart';
import 'package:example/bouncer_counter.dart';
import 'package:example/message_systems.dart';
import 'package:example/systems.dart';
import 'package:example/template.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'template_bar.dart';
import 'messages.dart';

class MouseDebugTrait extends Trait {}

void mouseDebugSystem(Realm realm) {
  final input = realm.getResource<Input>();
  try {
    final mouse = input
        .pointers()
        .firstWhere((p) => p.kind == PointerDeviceKind.mouse && p.isHovering);
    final query = realm.query(Has([MouseDebugTrait]));
    if (query.isNotEmpty) {
      final entity = query.first;
      final transform = entity.get<TransformTrait>();
      // transform.position = mouse.position;
      // use toLocal -> toGlobal to get the position instead
      // transform.position = transform.toWorld(transform.toLocal(mouse.position));
    }
  } catch (e) {
    // No mouse
  }
}

class MainGame extends FlameGame with HasRealm {
  @override
  Future<void> onLoad() async {
    realm = RealmBuilder()
        .withPlugin(defaultPlugin)
        .withTrait(BouncerTrait)
        .withTrait(GameResizeTrait)
        .withTrait(TemplateSpawnerTrait)
        .withTrait(TemplateTrait)
        .withTrait(BouncerCounterTrait)
        .withTrait(MouseDebugTrait)
        .withSystem(bouncerCounterSystem)
        .withSystem(bounceSystem)
        .withSystem(tapSpawnSystem)
        .withSystem(deleteRemoveSystem)
        .withSystem(mouseDebugSystem)
        .withMessageSystem(removeBounceMessageSystem)
        .withMessageSystem(resizeMessageSystem)
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
      bouncer.transformTrait.position =
          Vector2(canvasSize.x / 2, canvasSize.y / 2);
      realm.add(bouncer);
    }
    realm.add(TemplateBar(size));
    realm.add(BouncerCounterNode());
    realm.getResource<Input>().debugMode = true;

    // Mouse Debug parent
    final mouseDebugParent = Entity();
    final mouseDebugParentTransform = TransformTrait();
    mouseDebugParentTransform.position = Vector2.all(20.0);
    mouseDebugParent.add(mouseDebugParentTransform);
    realm.addEntity(mouseDebugParent);

    // Mouse Debug
    final mouseDebug = Entity();
    mouseDebug.add(MouseDebugTrait());
    final mouseDebugTransform = TransformTrait();
    mouseDebugTransform.size = Vector2.all(20.0);
    mouseDebugTransform.anchor = Anchor.center;
    mouseDebug.add(mouseDebugTransform);
    final mouseDebugRendering = RenderTrait();
    mouseDebug.add(mouseDebugRendering);
    final mouseDebugRectangle = RectangleTrait(Colors.pink);
    mouseDebug.add(mouseDebugRectangle);
    realm.addEntity(mouseDebug);
    mouseDebugParent.addChild(mouseDebug);

    // Mouse Debug child
    final mouseDebugChild = Entity();
    final mouseDebugChildTransform = TransformTrait();
    mouseDebugChildTransform.position = Vector2.all(20.0);
    mouseDebugChildTransform.size = Vector2.all(10.0);
    mouseDebugChildTransform.anchor = Anchor.center;
    mouseDebugChild.add(mouseDebugChildTransform);
    final mouseDebugChildRendering = RenderTrait();
    mouseDebugChild.add(mouseDebugChildRendering);
    final mouseDebugChildRectangle = RectangleTrait(Colors.blue);
    mouseDebugChild.add(mouseDebugChildRectangle);
    realm.addEntity(mouseDebugChild);
    mouseDebug.addChild(mouseDebugChild);

    realmReady = true;
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    if (realmReady) {
      realm.pushMessage(GameResizseMessage());
    }
  }
}
