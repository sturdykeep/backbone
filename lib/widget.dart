import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/realm.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

class BackboneGameWidget<T extends HasRealm> extends StatelessWidget {
  final T game;

  const BackboneGameWidget({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      child: MouseRegion(
        child: GameWidget(
          game: game,
        ),
        onEnter: (event) => game.realm.getResource<Input>().onHoverEnter(event),
        onHover: (event) => game.realm.getResource<Input>().onHover(event),
        onExit: (event) => game.realm.getResource<Input>().onHoverLeave(event),
      ),
    );
  }
}
