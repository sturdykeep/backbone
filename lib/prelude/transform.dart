import 'package:backbone/builders.dart';
import 'package:backbone/node.dart';
import 'package:backbone/position_node.dart';
import 'package:backbone/trait.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';

/// Plugin to register the TransformTrait and transformSystem in your realm
/// Both are used to handle PositionComponent basics setter for:
/// - position
/// - scale
/// - angle
/// - size
/// - anchor
void transformPlugin<T extends FlameGame>(RealmBuilder<T> builder) {
  builder.withTrait(TransformTrait<T>);
}

class TransformTrait<T extends FlameGame> extends ATrait<T> {
  Vector2 _position = Vector2.zero();
  Vector2 _scale = Vector2.all(1.0);
  Vector2 _size = Vector2.zero();
  double _rotation = 0.0;
  Anchor _anchor = Anchor.topLeft;

  // -- position
  Vector2 get position => _position;
  set position(Vector2 value) {
    if (_position != value) {
      _position = value;
      if (node != null && node is PositionNode<T>) {
        (node as PositionNode<T>).position = value;
      }
    }
  }

  // -- scale
  Vector2 get scale => _scale;
  set scale(Vector2 value) {
    if (_scale != value) {
      _scale = value;
      if (node != null && node is PositionNode<T>) {
        (node as PositionNode<T>).scale = value;
      }
    }
  }

  // -- rotation
  double get rotation => _rotation;
  set rotation(double value) {
    if (_rotation != value) {
      _rotation = value;
      if (node != null && node is PositionNode<T>) {
        (node as PositionNode<T>).angle = value;
      }
    }
  }

  // -- size
  Vector2 get size => _size;
  set size(Vector2 value) {
    if (_size != value) {
      _size = value;
      if (node != null && node is PositionNode<T>) {
        (node as PositionNode<T>).size = value;
      }
    }
  }

  // -- anchor
  Anchor get anchor => _anchor;
  set anchor(Anchor value) {
    if (_anchor != value) {
      _anchor = value;
      if (node != null && node is PositionNode<T>) {
        (node as PositionNode<T>).anchor = value;
      }
    }
  }

  Rect get rect => Rect.fromLTWH(position.x - anchor.x * size.x,
      position.y - anchor.y * size.y, size.x, size.y);

  // Convert current local position to global (world) coordinate space.
  Vector2 absolutePosition(ANode<T> node) {
    // Find the first parent, which is a PositionComponent
    var parent = node.parent;
    while (parent != null) {
      if (parent is PositionComponent) {
        return parent.absolutePositionOf(position);
      }
      parent = parent.parent;
    }
    return position;
  }

  @override
  void onAdd(ANode<T> node) {
    if (node is PositionNode<T>) {
      node.position = position;
      node.scale = scale;
      node.angle = rotation;
      node.size = size;
      node.anchor = anchor;
    }
  }
}
