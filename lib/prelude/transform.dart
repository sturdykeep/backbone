import 'package:backbone/builders.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

/// TODO add docu

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
    final transform = node.get<TransformTrait>();

    // Check if the node has PositionComponent children
    final positionChildren = node.children.whereType<PositionComponent>();
    for (var positionChild in positionChildren) {
      positionChild.position = transform.position;
      positionChild.scale = transform.scale;
      positionChild.angle = transform.rotation;
      positionChild.size = transform.size;
      positionChild.anchor = transform.anchor;
    }
  }
}
