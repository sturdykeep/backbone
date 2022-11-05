import 'package:backbone/builders.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/log.dart';
import 'package:backbone/node.dart';
import 'package:backbone/position_node.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/realm.dart';
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
  builder.withSystem(transformSystem);
}

class TransformTrait extends ATrait {
  Vector2 _position = Vector2.zero();
  Vector2 _scale = Vector2.all(1.0);
  Vector2 _size = Vector2.zero();
  double _rotation = 0.0;
  Anchor _anchor = Anchor.topLeft;

  // Wrappers and dirty flags
  void setDirty({bool value = false}) {
    dirtyPosition = value;
    dirtyScale = value;
    dirtySize = value;
    dirtyRotation = value;
    dirtyAnchor = value;
  }

  // -- position
  bool dirtyPosition = false;
  Vector2 get position => _position;
  set position(Vector2 value) {
    if (_position != value) {
      _position = value;
      dirtyPosition = true;
    }
  }

  // -- scale
  bool dirtyScale = false;
  Vector2 get scale => _scale;
  set scale(Vector2 value) {
    if (_scale != value) {
      _scale = value;
      dirtyScale = true;
    }
  }

  // -- rotation
  bool dirtyRotation = false;
  double get rotation => _rotation;
  set rotation(double value) {
    if (_rotation != value) {
      _rotation = value;
      dirtyRotation = true;
    }
  }

  // -- size
  bool dirtySize = false;
  Vector2 get size => _size;
  set size(Vector2 value) {
    if (_size != value) {
      _size = value;
      dirtySize = true;
    }
  }

  // -- anchor
  bool dirtyAnchor = false;
  Anchor get anchor => _anchor;
  set anchor(Anchor value) {
    if (_anchor != value) {
      _anchor = value;
      dirtyAnchor = true;
    }
  }

  Rect get rect => Rect.fromLTWH(position.x - anchor.x * size.x,
      position.y - anchor.y * size.y, size.x, size.y);

  // Convert current local position to global (world) coordinate space.
  Vector2 absolutePosition(ANode node) {
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
}

/// Default system for TransformTrait, any PositionNode using the trait will
/// get updated values every frame for:
/// - position
/// - scale
/// - angle
/// - size
/// - anchor
void transformSystem(Realm realm) {
  final queryWatch = LogStopwatch();
  final realmQuery = realm.query(Has([TransformTrait]));
  Log.transformQueryTime += queryWatch.stop();

  for (final node in realmQuery) {
    final bodyWatch = LogStopwatch();
    if (node is PositionNode) {
      final transform = node.get<TransformTrait>();
      if (transform.dirtyPosition) {
        node.position = transform.position;
      }
      if (transform.dirtyScale) {
        node.scale = transform.scale;
      }
      if (transform.dirtyRotation) {
        node.angle = transform.rotation;
      }
      if (transform.dirtySize) {
        node.size = transform.size;
      }
      if (transform.dirtyAnchor) {
        node.anchor = transform.anchor;
      }
      transform.setDirty(value: false);
    }
    Log.transformBodyTime += bodyWatch.stop();
  }
}
