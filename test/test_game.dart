import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:backbone/realm.dart' as realm;

class TestGame extends FlameGame
    with HasTappableComponents, HasDraggableComponents {
  TestGame();

  realm.Realm getrealm() {
    return children.first as realm.Realm;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final realm = getrealm();
    realm.onTapDown(event);
    super.onTapDown(event);
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    final realm = getrealm();
    realm.onLongTapDown(event);
    super.onLongTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    final realm = getrealm();
    realm.onTapUp(event);
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    final realm = getrealm();
    realm.onTapCancel(event);
    super.onTapCancel(event);
  }

  @override
  void onDragStart(DragStartEvent event) {
    final realm = getrealm();
    realm.onDragStart(event);
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final realm = getrealm();
    realm.onDragUpdate(event);
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    final realm = getrealm();
    realm.onDragEnd(event);
    super.onDragEnd(event);
  }
}
