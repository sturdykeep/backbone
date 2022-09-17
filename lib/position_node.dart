import 'package:backbone/node.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:flame/components.dart';

class PositionNode extends PositionComponent with HasGameRef, ANode {
  TransformTrait get transformTrait => get<TransformTrait>();

  PositionNode({TransformTrait? transformTrait}) {
    addTrait(transformTrait ?? TransformTrait());
  }
}
