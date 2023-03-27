import 'package:backbone/builders.dart';
import 'package:backbone/prelude/text/system.dart';
import 'package:backbone/prelude/text/trait.dart';
import 'package:flame/game.dart';

/// Adding trait and system for default text handling
void textPlugin<T extends FlameGame>(RealmBuilder<T> builder) {
  builder.withTrait(TextTrait<T>);
  builder.withSystem(textSystem);
}
