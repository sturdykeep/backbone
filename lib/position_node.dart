import 'package:backbone/node.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// A node using the positioned component of Flame to allow
/// child components or nodes to be placed relative to the parent.
/// Using this node requires you to register TransformTrait with your
/// realm!
class PositionNode<T extends FlameGame> extends PositionComponent
    with HasGameRef<T>, ANode<T> {
  TransformTrait<T> get transformTrait => get<TransformTrait<T>>();

  PositionNode({TransformTrait<T>? transformTrait}) {
    addTrait(transformTrait ?? TransformTrait<T>());
  }
}
