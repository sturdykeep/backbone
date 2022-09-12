import 'package:backbone/node.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/trait.dart';
import 'package:example/messages.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/painting.dart';

/// Marker trait for entities that can be bounced.
class BouncerTrait extends ATrait {}

class BouncerNode extends ANode with TapCallbacks, DragCallbacks {
  final Vector2 size;
  final Color color;
  final Vector2 direction;
  final double speed;

  TransformTrait get transform => get<TransformTrait>();

  BouncerNode(this.size, this.color, this.direction, this.speed) {
    // Add your traits here
    // Make sure to add your traits in the constructor
    // so that the external code can access them directly
    // via getters
    final transformTrait = TransformTrait();
    transformTrait.size = size;
    addTrait(transformTrait);
    addTrait(BouncerTrait());
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return get<TransformTrait>().rect.containsPoint(point);
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

  @override
  void onDragEnd(DragEndEvent event) {
    realm!.pushMessage(RemoveBouncerMessage(this));
    event.handled = true;
  }
}
