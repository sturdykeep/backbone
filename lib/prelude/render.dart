import 'dart:ui';

import 'package:backbone/filter.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

class DrawRectangleTrait extends Trait {
  Color color;

  DrawRectangleTrait(this.color);
}

/// A simple render system that renders a rectangle on the canvas.
void rectangleRenderSystem(Realm realm, Canvas canvas) {
  final query = realm.query(Has([TransformTrait, DrawRectangleTrait]));
  for (final node in query) {
    final transform = node.get<TransformTrait>();
    final draw = node.get<DrawRectangleTrait>();
    final points = [];

    // Creates a rectangle from the transform size
    for (var i = 0; i < 4; i++) {
      final x = i % 2 == 0 ? transform.size.x : 0;
      final y = i < 2 ? transform.size.y : 0;
      points.add(transform.position + Vector2(x.toDouble(), y.toDouble()));
    }

    // Now use the transform to rotate and translate the rectangle
    final matrix = transform.transformMatrix;
    final transformedPoints = points.map((p) => matrix.transform2(p));

    // Finally draw the rectangle
    canvas.drawPath(
      Path()
        ..addPolygon(transformedPoints.map((v) => v.toOffset()).toList(), true),
      Paint()..color = draw.color,
    );
  }
}
