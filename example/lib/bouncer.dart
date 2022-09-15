import 'package:backbone/node.dart';
import 'package:backbone/prelude/input/plugins/drag.dart';
import 'package:backbone/prelude/input/plugins/hoverable.dart';
import 'package:backbone/prelude/input/plugins/taps.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/trait.dart';
import 'package:example/messages.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

/// Marker trait for entities that can be bounced.
class BouncerTrait extends ATrait {}

class BouncerNode extends ANode with TapCallbacks, DragCallbacks {
  final Vector2 size;
  final Color color;
  final Vector2 direction;
  final double speed;
  var oldColor = Colors.white;

  TransformTrait get transform => get<TransformTrait>();
  Paint get currentPaint =>
      (children.elementAt(0).children.elementAt(0) as RectangleComponent).paint;

  BouncerNode(
    this.size,
    this.color,
    this.direction,
    this.speed,
  ) {
    // Add your traits here
    // Make sure to add your traits in the constructor
    // so that the external code can access them directly
    // via getters. All traits MUST be registered in your Realm first!
    final transformTrait = TransformTrait();
    transformTrait.size = size;
    addTrait(transformTrait);
    // Receive drags
    final dragReceiverTrait = DragReceiverTrait(onReceive: ((pointer, payload) {
      if (payload != null &&
          payload.data != null &&
          payload.data is Color &&
          payload.initiator != this) {
        currentPaint.color = payload.data as Color;
      } else {
        realm!.pushMessage(RemoveBouncerMessage(this));
      }
      pointer.handled = true;
    }));
    addTrait(dragReceiverTrait);

    // Start drags
    final draggableTrait = DraggableTrait(onStart: ((pointer) {
      return DraggablePointerPayload(this, currentPaint.color);
    }));
    addTrait(draggableTrait);

    // Receive tap ups
    final tappableTrait = TappableTrait(
      onTapUp: (pointer) {
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
    final positionComponent = PositionComponent();
    add(positionComponent);
    positionComponent
        .add(RectangleComponent(size: size, paint: Paint()..color = color));

    return super.onLoad();
  }

  @override
  void onTapUp(TapUpEvent event) {
    realm!.pushMessage(RemoveBouncerMessage(this));
    event.handled = true;
  }
}
