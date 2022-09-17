import 'package:backbone/builders.dart';
import 'package:backbone/filter.dart';
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
  Vector2 position = Vector2.zero();
  Vector2 scale = Vector2.all(1.0);
  Vector2 size = Vector2.zero();
  double rotation = 0.0;
  Anchor anchor = Anchor.topLeft;

  Rect get rect => Rect.fromLTWH(position.x - anchor.x * size.x,
      position.y - anchor.y * size.y, size.x, size.y);
}

void transformSystem(Realm realm) {
  final realmQuery = realm.query(Has([TransformTrait]));
  final queryLength = realmQuery.length;
  for (var i = 0; i < queryLength; i++) {
    final node = realmQuery.elementAt(i);
    if (node is PositionNode) {
      final transform = node.get<TransformTrait>();
      node.position = transform.position;
      node.scale = transform.scale;
      node.angle = transform.rotation;
      node.size = transform.size;
      node.anchor = transform.anchor;
    }
  }
}
