import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/realm.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class BackboneGameWidget<T extends HasRealm> extends StatefulWidget {
  final T game;

  const BackboneGameWidget({Key? key, required this.game}) : super(key: key);

  @override
  State<BackboneGameWidget<T>> createState() => _BackboneGameWidgetState<T>();
}

class _BackboneGameWidgetState<T extends HasRealm>
    extends State<BackboneGameWidget<T>> {
  _BackboneGameWidgetState() {
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handleEvent);
  }

  @override
  void dispose() {
    super.dispose();
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handleEvent);
  }

  void _handleEvent(PointerEvent event) {
    if (event is PointerAddedEvent) {
      widget.game.realm.getResource<Input>().onPointerAdded(event);
    } else if (event is PointerHoverEvent) {
      widget.game.realm.getResource<Input>().onHover(event);
    } else if (event is PointerRemovedEvent) {
      widget.game.realm.getResource<Input>().onPointerRemoved(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      child: GameWidget(
        game: widget.game,
      ),
    );
  }
}
