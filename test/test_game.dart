import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:backbone/world.dart' as world;

class TestGame extends FlameGame
    with HasTappableComponents, HasDraggableComponents {
  TestGame();

  world.World getWorld() {
    return children.first as world.World;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final world = getWorld();
    world.onTapDown(event);
    super.onTapDown(event);
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    final world = getWorld();
    world.onLongTapDown(event);
    super.onLongTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    final world = getWorld();
    world.onTapUp(event);
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    final world = getWorld();
    world.onTapCancel(event);
    super.onTapCancel(event);
  }

  @override
  void onDragStart(DragStartEvent event) {
    final world = getWorld();
    world.onDragStart(event);
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final world = getWorld();
    world.onDragUpdate(event);
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    final world = getWorld();
    world.onDragEnd(event);
    super.onDragEnd(event);
  }
}
