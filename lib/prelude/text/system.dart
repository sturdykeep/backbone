import 'package:backbone/filter.dart';
import 'package:backbone/prelude/text/trait.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';

/// Handle any text rendering including, zoom, position and padding
/// The node requires to have the TextTrait and TransformTrait and one TextComponent
/// If multiple are found only the first is used
void textSystem(Realm realm) {
  final query = realm.query(Has([TextTrait, TransformTrait]));
  final cameraZoom = realm.gameRef.camera.zoom;
  final counterZoom = Vector2.all(cameraZoom + (-2.0 * (cameraZoom - 1.0)));

  for (var node in query) {
    final trait = node.get<TextTrait>();
    if (trait.dirty) {
      final textChildList = node.findChildren<TextComponent>();
      if (textChildList.isNotEmpty) {
        final textChild = textChildList.first;
        textChild.text = trait.text;
        textChild.textRenderer = TextPaint(style: trait.style);

        final textSize = textChild.textRenderer.measureText(textChild.text);
        if (trait.counterZoom) {
          textSize.scale(counterZoom.x);
        }

        //Just transform
        final transformTrait = node.get<TransformTrait>();
        centerX() =>
            textChild.position.x = ((transformTrait.size.x - textSize.x) / 2);
        centerY() =>
            textChild.position.y = ((transformTrait.size.y - textSize.y) / 2);
        fullBottom() => textChild.position.y = transformTrait.size.y;
        right() =>
            textChild.position.x = ((transformTrait.size.x - textSize.x));

        if (trait.anchor == Anchor.center) {
          centerX();
          centerY();
        } else if (trait.anchor == Anchor.topCenter) {
          centerX();
        } else if (trait.anchor == Anchor.bottomCenter) {
          centerX();
          fullBottom();
        } else if (trait.anchor == Anchor.bottomLeft) {
          fullBottom();
        } else if (trait.anchor == Anchor.bottomRight) {
          fullBottom();
          right();
        } else if (trait.anchor == Anchor.topRight) {
          right();
        } else if (trait.anchor == Anchor.centerLeft) {
          centerY();
        } else if (trait.anchor == Anchor.centerRight) {
          centerY();
          right();
        }
        transformTrait.position += trait.padding;
        transformTrait.scale = counterZoom;
      }
      trait.dirty = false;
    }
  }
}
