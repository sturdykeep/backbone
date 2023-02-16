import 'package:backbone/builders.dart';
import 'package:backbone/entity.dart';
import 'package:backbone/node.dart';
import 'package:backbone/position_node.dart';
import 'package:backbone/trait.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

/// Plugin to register the TransformTrait and transformSystem in your realm
/// Both are used to handle PositionComponent basics setter for:
/// - position
/// - scale
/// - angle
/// - size
/// - anchor
/// - priority
void transformPlugin(RealmBuilder builder) {
  builder.withTrait(TransformTrait);
}

class TransformTrait extends Trait {
  Node? node;

  Vector2 _position = Vector2.zero();
  Vector2 _scale = Vector2.all(1.0);
  Vector2 _size = Vector2.zero();
  double _rotation = 0.0;
  Anchor _anchor = Anchor.topLeft;
  int _priority = 0;

  // -- position
  Vector2 get position => _position;
  set position(Vector2 value) {
    if (_position != value) {
      _position = value;
      if (node != null && node is PositionNode) {
        (node as PositionNode).position = value;
      }
    }
  }

  // -- scale
  Vector2 get scale => _scale;
  set scale(Vector2 value) {
    if (_scale != value) {
      _scale = value;
      if (node != null && node is PositionNode) {
        (node as PositionNode).scale = value;
      }
    }
  }

  // -- rotation
  double get rotation => _rotation;
  set rotation(double value) {
    if (_rotation != value) {
      _rotation = value;
      if (node != null && node is PositionNode) {
        (node as PositionNode).angle = value;
      }
    }
  }

  // -- size
  Vector2 get size => _size;
  set size(Vector2 value) {
    if (_size != value) {
      _size = value;
      if (node != null && node is PositionNode) {
        (node as PositionNode).size = value;
      }
    }
  }

  // -- anchor
  Anchor get anchor => _anchor;
  set anchor(Anchor value) {
    if (_anchor != value) {
      _anchor = value;
      if (node != null && node is PositionNode) {
        (node as PositionNode).anchor = value;
      }
    }
  }

  // -- priority
  int get priority => _priority;
  set priority(int value) {
    if (_priority != value) {
      _priority = value;
      if (node != null && node is PositionNode) {
        (node as PositionNode).priority = value;
      }
    }
  }

  // Utilities
  Rect get localRect => Rect.fromLTWH(0, 0, size.x, size.y);

  /// Transform matrix, that takes anchor into account for scaling and rotation.
  Matrix4 get transformMatrix {
    final origin = anchor.toVector2()..multiply(size);
    return Matrix4.identity()
      ..translate(position.x, position.y)
      ..translate(origin.x, origin.y)
      ..rotateZ(rotation)
      ..scale(scale.x, scale.y)
      ..translate(-origin.x, -origin.y);
  }

  Matrix4 get inverseTransformMatrix => transformMatrix.clone()..invert();

  bool containsPoint(Vector2 point) {
    final localPoint = inverseTransformMatrix.transform2(point);
    return localRect.contains(localPoint.toOffset());
  }

  int compareToOnPriority(TransformTrait other) {
    return priority.compareTo(other.priority);
  }

  @override
  void onAdd() {
    node = entity.tryGet<NodeTrait>()?.node;

    if (node != null && node is PositionNode) {
      final positionNode = node as PositionNode;
      positionNode.position = position;
      positionNode.scale = scale;
      positionNode.angle = rotation;
      positionNode.size = size;
      positionNode.anchor = anchor;
      positionNode.priority = priority;
    }
  }
}
