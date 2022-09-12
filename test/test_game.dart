import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:backbone/realm.dart' as realm;

class TestGame extends FlameGame
    with
        HasTappableComponents,
        HasDraggableComponents,
        KeyboardEvents,
        HasHoverables,
        realm.HasRealm {
  TestGame();
}
