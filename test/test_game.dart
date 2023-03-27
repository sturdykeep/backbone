import 'package:backbone/realm_mixin.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';

class TestGame extends FlameGame
    with
        HasTappableComponents,
        HasDraggableComponents,
        KeyboardEvents,
        HasHoverables,
        Hoverable,
        HasRealm<TestGame> {
  TestGame();
}
