import 'package:backbone/builders.dart';
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
void transformPlugin(RealmBuilder builder) {
  builder.withTrait(TransformTrait);
}

class TransformTrait extends Trait {
  Node? node;

  Vector3 _position = Vector3.zero();
  Vector2 _scale = Vector2.all(1.0);
  Vector2 _size = Vector2.zero();
  double _rotation = 0.0;
  Anchor _anchor = Anchor.topLeft;

  // -- position
  Vector3 get position => _position;
  set position(Vector3 value) {
    if (_position != value) {
      _position = value;
      if (node != null && node is PositionNode) {
        final positionNode = node as PositionNode;
        positionNode.position = value.xy;
        positionNode.priority = value.z.toInt();
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

  Vector2 toLocal(Vector2 point) {
    final transforms = entity.findAllReverse<TransformTrait>();
    final localPoint = point;
    for (final transform in transforms) {
      final inverse = transform.inverseTransformMatrix;
      localPoint.setFrom(inverse.transform2(localPoint));
    }
    return localPoint;
  }

  Vector2 toWorld(Vector2 point) {
    final transforms = entity.findAll<TransformTrait>();
    final worldPoint = point;
    for (final transform in transforms) {
      final matrix = transform.transformMatrix;
      worldPoint.setFrom(matrix.transform2(worldPoint));
    }
    return worldPoint;
  }

  bool containsPoint(Vector2 point) {
    final localPoint = toLocal(point);
    return localRect.contains(localPoint.toOffset());
  }

  int compareToOnPriority(TransformTrait other) {
    return position.z.compareTo(other.position.z);
  }

  Vector2 worldPosition() {
    if (node == null) {
      return toWorld(position.xy);
    } else {
      // Find the first parent, which is a PositionComponent
      var parent = node!.parent;
      while (parent != null) {
        if (parent is PositionComponent) {
          return Vector3(parent.absolutePositionOf(position.xy));
        }
        parent = parent.parent;
      }
      return position;
    }
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
