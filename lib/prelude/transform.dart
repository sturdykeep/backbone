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
  bool positionSet = false;

  // Wrappers and dirty flags
  void setDirty({bool value = false}) {
    _dirtyPosition = value;
    _dirtyScale = value;
    _dirtySize = value;
    _dirtyRotation = value;
    _dirtyAnchor = value;
  }

  // -- position
  bool _dirtyPosition = false;
  Vector2 get position => _position;
  set position(Vector2 value) {
    if (_position != value) {
      _position = value;
      _dirtyPosition = true;
    }
  }

  // -- scale
  bool _dirtyScale = false;
  Vector2 get scale => _scale;
  set scale(Vector2 value) {
    if (_scale != value) {
      _scale = value;
      _dirtyScale = true;
    }
  }

  // -- rotation
  bool _dirtyRotation = false;
  double get rotation => _rotation;
  set rotation(double value) {
    if (_rotation != value) {
      _rotation = value;
      _dirtyRotation = true;
    }
  }

  // -- size
  bool _dirtySize = false;
  Vector2 get size => _size;
  set size(Vector2 value) {
    if (_size != value) {
      _size = value;
      _dirtySize = true;
    }
  }

  // -- anchor
  bool _dirtyAnchor = false;
  Anchor get anchor => _anchor;
  set anchor(Anchor value) {
    if (_anchor != value) {
      _anchor = value;
      _dirtyAnchor = true;
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
      if (transform._dirtyPosition) {
        node.position = transform.position;
      }
      if (transform._dirtyScale) {
        node.scale = transform.scale;
      }
      if (transform._dirtyRotation) {
        node.angle = transform.rotation;
      }
      if (transform._dirtySize) {
        node.size = transform.size;
      }
      if (transform._dirtyAnchor) {
        node.anchor = transform.anchor;
      }
      transform.positionSet = true;
      transform.setDirty(value: false);
    }
    Log.transformBodyTime += bodyWatch.stop();
  }
}
