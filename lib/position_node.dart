
import 'package:backbone/node.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:flame/components.dart';

/// A node using the positioned component of Flame to allow
/// child components or nodes to be placed relative to the parent.
/// Using this node requires you to register TransformTrait with your
/// realm!
class PositionNode extends PositionComponent with HasGameRef, ANode {
  TransformTrait get transformTrait => get<TransformTrait>();

  PositionNode({TransformTrait? transformTrait}) {
    addTrait(transformTrait ?? TransformTrait());
  }
}
