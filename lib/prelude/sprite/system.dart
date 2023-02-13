import 'package:backbone/filter.dart';
import 'package:backbone/prelude/sprite/trait.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';

/// Render Sprite- and SpriteAnimationComponent
void spriteSystem(Realm realm) {
  final realmQuery = realm.query(Has([SpriteTrait]), onlyLoaded: true);

  for (final node in realmQuery) {
    final spriteTrait = node.get<SpriteTrait>();
    if (spriteTrait.dirty) {
      final sprite = spriteTrait.sprite;
      final animation = spriteTrait.animationData;
      if (sprite != null || animation != null) {
        final transformTrait = node.tryGet<TransformTrait>();
        // Search for a SpriteComponent in the tree
        if (animation == null) {
          final spriteComponents = node.findChildren<SpriteComponent>();
          if (spriteComponents.isNotEmpty) {
            final spriteComponent = spriteComponents.first;
            spriteComponent.sprite = sprite;
            spriteComponent.position = spriteTrait.offset;
            spriteComponent.priority = spriteTrait.priority;
            spriteComponent.size = transformTrait?.size ?? sprite!.srcSize;
            spriteComponent.paint = spriteTrait.paint;
          }
        } else {
          final animationComponents =
              node.findChildren<SpriteAnimationComponent>();
          if (animationComponents.isNotEmpty) {
            final component = animationComponents.first;
            component.animation = animation;
            component.animation!.onComplete = spriteTrait.onComplete;
            component.animation!.onFrame = spriteTrait.onFrame;
            component.position = spriteTrait.offset;
            component.priority = spriteTrait.priority;
            component.size =
                transformTrait?.size ?? animation.frames.first.sprite.srcSize;
            component.paint = spriteTrait.paint;
          }
        }
      }
      spriteTrait.dirty = false;
    }
  }
}
