import 'package:backbone/builders.dart';
import 'package:backbone/prelude/sprite/system.dart';
import 'package:backbone/prelude/sprite/trait.dart';
import 'package:flame/game.dart';

/// Add the spritetrait and spriteSystem to your relam
void spritePlugin<T extends FlameGame>(RealmBuilder<T> builder) {
  builder.withTrait(SpriteTrait<T>);
  builder.withSystem(spriteSystem);
}
