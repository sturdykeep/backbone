import 'package:backbone/builders.dart';
import 'package:backbone/prelude/sprite/system.dart';
import 'package:backbone/prelude/sprite/trait.dart';

/// Add the spritetrait and spriteSystem
void spritePlugin(RealmBuilder builder) {
  builder.withTrait(SpriteTrait);
  builder.withSystem(spriteSystem);
}
