import 'package:backbone/position_node.dart';
import 'package:backbone/prelude/input/plugins/hoverable.dart';
import 'package:backbone/prelude/input/plugins/selectable.dart';
import 'package:backbone/prelude/input/plugins/taps.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/trait.dart';
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
  var hovered = false;
  var selected = false;

  Paint get currentPaint => (children.first as RectangleComponent).paint;

  Color colorFromFlags() {
    if (hovered) {
      return Colors.red;
    } else if (selected) {
      return Colors.blue;
    } else {
      return color;
    }
  }

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
          debugPrint('Bouncer tapped');
        }
      },
    );
    addTrait(tappableTrait);

    oldColor = color;
    // Receive hover
    final hoverableTrait = HoverableTrait(
      onHoverEnter: (pointer) {
        hovered = true;
        currentPaint.color = colorFromFlags();
      },
      onHoverExit: (pointer) {
        hovered = false;
        currentPaint.color = colorFromFlags();
      },
    );
    addTrait(hoverableTrait);

    // Selectable trait
    final selectableTrait = SelectableTrait(
      onSelected: (pointer) {
        selected = true;
        currentPaint.color = colorFromFlags();
        pointer?.handled = true;
        return true;
      },
      onDeselected: (pointer) {
        selected = false;
        currentPaint.color = colorFromFlags();
        pointer?.handled = true;
        return true;
      },
    );
    addTrait(selectableTrait);

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
