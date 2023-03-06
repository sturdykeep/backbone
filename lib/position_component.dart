import 'package:backbone/component.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:flame/components.dart';

/// Flame [PositionComponent] that contains and internal [Entity] with a [Transform] trait.
class PositionEntityComponent extends PositionComponent
    with HasGameRef, HasEntity {
  late Transform transformTrait;

  PositionEntityComponent({Transform? transformTrait}) {
    this.transformTrait = transformTrait ?? Transform();
  }

  @override
  void onMount() {
    super.onMount();
    entity.add(transformTrait);
  }
}
