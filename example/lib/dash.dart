import 'dart:async';

import 'package:backbone/position_node.dart';
import 'package:backbone/prelude/sprite/trait.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:example/bouncer.dart';
import 'package:flame/components.dart';

class DashNode extends PositionNode {
  DashNode({
    required Vector2 direction,
    required double speed,
  }) : super(
          transformTrait: TransformTrait()..size = Vector2(35, 35),
        ) {
    final spriteTrait = SpriteTrait();
    entity.add(spriteTrait);
    entity.add(BouncerTrait(
      direction,
      speed,
    ));
  }

  @override
  FutureOr<void> onLoad() async {
    final spriteTrait = entity.get<SpriteTrait>();
    spriteTrait.sprite = await gameRef.loadSprite('dash.png');
    add(SpriteComponent(sprite: spriteTrait.sprite));
    return super.onLoad();
  }
}
