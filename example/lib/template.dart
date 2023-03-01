import 'dart:math';

import 'package:backbone/entity.dart';
import 'package:backbone/prelude/input/plugins/drag.dart';
import 'package:backbone/prelude/render/rectangle.dart';
import 'package:backbone/prelude/render/trait.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:example/bouncer.dart';
import 'package:example/template_bar.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

class TemplateTrait extends Trait {
  Vector2? startingPosition;
  Vector2 dragOffset = Vector2.zero();

  TemplateTrait();
}

Entity buildTemplate(Realm realm, TemplateBar bar, Vector2 position) {
  final fixedSize = Vector2.all(60);
  final entity = Entity();
  final rng = Random();
  // Create a random color
  final color = Color((rng.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

  final transformTrait = TransformTrait();
  transformTrait.size = fixedSize;
  transformTrait.position = position;
  transformTrait.anchor = Anchor.center;
  entity.add(transformTrait);

  final templateTrait = TemplateTrait();
  entity.add(templateTrait);

  // Create callbacks for drag events
  final draggableTrait = DraggableTrait(
    onStart: (pointer, offset) {
      // DEBUG
      debugPrint('DraggableTrait.onStart');
      debugPrint('  offset: $offset');
      debugPrint('  pointer.position: ${pointer.position}');
      debugPrint('  transformTrait.position: ${transformTrait.position}');
      debugPrint(
          '  transformTrait.toLocal(pointer.position): ${transformTrait.toLocal(pointer.position)}');
      debugPrint(
          '  transformTrait.toLocal(pointer.position) - offset: ${transformTrait.toLocal(pointer.position) - offset}');
      // END DEBUG

      templateTrait.startingPosition = transformTrait.position;
      templateTrait.dragOffset = offset;
      pointer.handled = true;
      return DraggablePointerPayload(entity, null);
    },
    onUpdate: (pointer) {
      transformTrait.position =
          entity.parent!.get<TransformTrait>().toLocal(pointer.position) -
              templateTrait.dragOffset;
    },
    onEnd: (pointer) {
      final bouncer = BouncerNode(
          Vector2.all(50.0 + 50.0 * rng.nextDouble()),
          color,
          (Vector2.all(-1.0) + Vector2.random(rng) * 2.0),
          200.0 + 200.0 * rng.nextDouble());
      bouncer.transformTrait.position = pointer.position;
      realm.add(bouncer);
      transformTrait.position = templateTrait.startingPosition!;
      templateTrait.startingPosition = null;
      pointer.handled = true;
    },
  );
  entity.add(draggableTrait);

  // Rendering
  final renderTrait = RenderTrait();
  entity.add(renderTrait);

  final rectangleTrait = RectangleTrait(color);
  entity.add(rectangleTrait);

  realm.addEntity(entity);
  entity.parent = bar.entity;
  return entity;
}
