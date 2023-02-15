import 'dart:async';

import 'package:backbone/filter.dart';
import 'package:backbone/position_node.dart';
import 'package:backbone/prelude/text/trait.dart';
import 'package:backbone/prelude/transform.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:example/bouncer.dart';
import 'package:flame/components.dart';

class BouncerCounterTrait extends Trait {}

class BouncerCounterNode extends PositionNode {
  BouncerCounterNode()
      : super(transformTrait: TransformTrait()..position = Vector2(10, 10)) {
    addTrait(TextTrait());
    addTrait(BouncerCounterTrait());
  }

  @override
  FutureOr<void> onLoad() {
    add(TextComponent());
    return super.onLoad();
  }
}

void bouncerCounterSystem(Realm realm) {
  final totalBouncer = realm.query(Has([BouncerTrait])).length;
  final counterNodes = realm.query(Has([BouncerCounterTrait, TextTrait]));
  for (final node in counterNodes) {
    node.get<TextTrait>().text = "Bouncer: $totalBouncer";
  }
}
