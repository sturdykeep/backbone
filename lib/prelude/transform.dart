import 'dart:math';
import 'dart:ui';

import 'package:backbone/builders.dart';
import 'package:backbone/component.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/position_component.dart';
import 'package:backbone/realm.dart';
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
  builder.withTrait(Transform);
  builder.withSystem(rebuildMatrixCacheSystem);
}

void rebuildMatrixCacheSystem(Realm realm) {
  final entities = realm.query(Has([Transform]));
  for (final entity in entities) {
    final transform = entity.get<Transform>();
    if (transform._cacheIsDirty) {
      transform._populateCaches();
    }
  }
}

class Transform extends Trait {
  HasEntity? node;

  Vector2 _position = Vector2.zero();
  Vector2 _scale = Vector2.all(1.0);
  Vector2 _size = Vector2.zero();
  double _rotation = 0.0;
  Anchor _anchor = Anchor.topLeft;
  int _priority = 0;

  // Cache
  bool initialized = false;
  bool _cacheIsDirty = true;
  Matrix4 _matrix = Matrix4.identity();
  Matrix4 _matrixInverse = Matrix4.identity();
  Matrix4 _matrixWithoutOrigin = Matrix4.identity();
  Matrix4 _matrixWithoutOriginInverse = Matrix4.identity();

  // -- position
  Vector2 get position => _position;
  set position(Vector2 value) {
    if (_position != value) {
      _position = value;
      _cacheIsDirty = true;
      if (node != null && node is PositionEntityComponent) {
        final positionNode = node as PositionEntityComponent;
        positionNode.position = value;
      }
    }
  }

  // -- scale
  Vector2 get scale => _scale;
  set scale(Vector2 value) {
    if (_scale != value) {
      _scale = value;
      _cacheIsDirty = true;
      if (node != null && node is PositionEntityComponent) {
        (node as PositionEntityComponent).scale = value;
      }
    }
  }

  // -- rotation
  double get rotation => _rotation;
  set rotation(double value) {
    if (_rotation != value) {
      _rotation = value;
      _cacheIsDirty = true;
      if (node != null && node is PositionEntityComponent) {
        (node as PositionEntityComponent).angle = value;
      }
    }
  }

  // -- rotation in degrees
  double get rotationDegrees => _rotation * 180.0 / pi;
  set rotationDegrees(double value) {
    rotation = value * pi / 180.0;
  }

  // -- size
  Vector2 get size => _size;
  set size(Vector2 value) {
    if (_size != value) {
      _size = value;
      _cacheIsDirty = true;
      if (node != null && node is PositionEntityComponent) {
        (node as PositionEntityComponent).size = value;
      }
    }
  }

  // -- anchor
  Anchor get anchor => _anchor;
  set anchor(Anchor value) {
    if (_anchor != value) {
      _anchor = value;
      _cacheIsDirty = true;
      if (node != null && node is PositionEntityComponent) {
        (node as PositionEntityComponent).anchor = value;
      }
    }
  }

  // -- priority
  int get priority => _priority;
  set priority(int value) {
    if (_priority != value) {
      _priority = value;
      if (node != null && node is PositionEntityComponent) {
        (node as PositionEntityComponent).priority = value;
      }
    }
  }

  // Utilities
  Vector2 get origin => anchor.toVector2()..multiply(size);
  Rect get localRect => Rect.fromLTWH(0, 0, size.x, size.y);

  /// Transform matrix, that takes anchor into account for scaling and rotation.
  Matrix4 get transformMatrix {
    return Matrix4.identity()
      ..translate(position.x, position.y)
      ..rotateZ(rotation)
      ..scale(scale.x, scale.y)
      ..translate(-origin.x, -origin.y);
  }

  Matrix4 get inverseTransformMatrix => transformMatrix.clone()..invert();

  Matrix4 get transformMatrixWithoutOrigin {
    return Matrix4.identity()
      ..translate(position.x, position.y)
      ..rotateZ(rotation)
      ..scale(scale.x, scale.y);
  }

  Matrix4 get inverseTransformMatrixWithoutOrigin =>
      transformMatrixWithoutOrigin..invert();

  RSTransform globalRSTransform({Vector2? spriteSize}) {
    final scaleToSize = spriteSize != null
        ? Vector2(size.x / spriteSize.x, size.y / spriteSize.y)
        : Vector2.all(1.0);
    final globalTransform = globalTransformMatrix;

    final transformedPosition = globalTransform.transform2(origin);
    // figure out the scale
    final pointA = Vector2(0, 0);
    final pointB = Vector2(1, 0);
    final transformedPointA = globalTransform.transform2(pointA);
    final transformedPointB = globalTransform.transform2(pointB);
    final transformedScale = transformedPointA.distanceTo(transformedPointB);
    final transformedRotation = Vector2(0, 1)
        .angleToSigned(globalTransform.getRotation().transform2(Vector2(0, 1)));

    final anchorX = anchor.x * (spriteSize?.x ?? size.x);
    final anchorY = anchor.y * (spriteSize?.y ?? size.y);
    return RSTransform.fromComponents(
      rotation: transformedRotation,
      scale: transformedScale * scaleToSize.x,
      anchorX: anchorX,
      anchorY: anchorY,
      translateX: transformedPosition.x,
      translateY: transformedPosition.y,
    );
  }

  /// Transform matrix, that takes parent transforms into account.
  Matrix4 get globalTransformMatrix {
    final transforms = entity.findAllReverse<Transform>();
    final matrix = Matrix4.identity();
    for (final transform in transforms) {
      final last = transform == transforms.last;
      matrix
          .multiply(last ? transform._matrix : transform._matrixWithoutOrigin);
    }
    return matrix;
  }

  Matrix4 get globalInverseTransformMatrix => globalTransformMatrix..invert();

  void _populateCaches() {
    _matrix = transformMatrix;
    _matrixInverse = inverseTransformMatrix;
    _matrixWithoutOrigin = transformMatrixWithoutOrigin;
    _matrixWithoutOriginInverse = inverseTransformMatrixWithoutOrigin;
    _cacheIsDirty = false;
    initialized = true;
  }

  Vector2 toLocal(Vector2 point) {
    final transforms = entity.findAllReverse<Transform>();
    var localPoint = point;
    for (final transform in transforms) {
      final last = transform == transforms.last;
      final inverse = last
          ? transform._matrixInverse
          : transform._matrixWithoutOriginInverse;
      localPoint = inverse.transform2(localPoint);
    }
    return localPoint;
  }

  Vector2 toWorld(Vector2 point) {
    final transforms = entity.findAll<Transform>();
    var worldPoint = point;
    for (final transform in transforms) {
      final first = transform == transforms.first;
      final matrix = first ? transform._matrix : transform._matrixWithoutOrigin;
      worldPoint = matrix.transform2(worldPoint);
    }

    return worldPoint;
  }

  bool containsPoint(Vector2 point) {
    final localPoint = toLocal(point);
    return localRect.contains(localPoint.toOffset());
  }

  int compareToOnPriority(Transform other) {
    return priority.compareTo(other.priority);
  }

  @override
  void onAdd() {
    node = entity.tryGet<ComponentTrait>()?.node;

    if (node != null && node is PositionEntityComponent) {
      final positionNode = node as PositionEntityComponent;
      positionNode.position = position;
      positionNode.scale = scale;
      positionNode.angle = rotation;
      positionNode.size = size;
      positionNode.anchor = anchor;
      positionNode.priority = priority;
    }
  }
}
