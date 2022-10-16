import 'package:backbone/position_node.dart';
import 'package:backbone/prelude/input/plugins/hoverable.dart';
import 'package:backbone/prelude/input/plugins/taps.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/trait.dart';
import 'package:example/messages.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

/// Marker trait for entities that can be bounced.
class BouncerTrait extends ATrait {}

class BouncerNode extends PositionNode {
  final Color color;
  final Vector2 direction;
  final double speed;
  var oldColor = Colors.white;

  Paint get currentPaint => (children.first as RectangleComponent).paint;

  BouncerNode(
    Vector2 size,
    this.color,
    this.direction,
    this.speed,
  ) : super(
          transformTrait: TransformTrait()..size = size,
        ) {
    // Receive tap ups
    final tappableTrait = TappableTrait(
      onJustReleased: (pointer) {
        if (pointer.handled == false) {
          realm!.pushMessage(RemoveBouncerMessage(this));
          pointer.handled = true;
        }
      },
    );
    addTrait(tappableTrait);

    // Receive hover
    final hoverableTrait = HoverableTrait(
      onHoverEnter: (pointer) {
        oldColor = currentPaint.color;
        currentPaint.color = Colors.red;
      },
      onHoverExit: (pointer) {
        currentPaint.color = oldColor;
      },
    );
    addTrait(hoverableTrait);

    addTrait(BouncerTrait());
  }

  @override
  Future<void>? onLoad() {
    // Add child components here
    add(RectangleComponent(
        size: transformTrait.size, paint: Paint()..color = color));

    return super.onLoad();
  }
}
