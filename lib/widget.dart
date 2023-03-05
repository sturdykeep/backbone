import 'package:backbone/log.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/realm_mixin.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class BackboneGameWidget<T extends HasRealm> extends StatefulWidget {
  /// Your game extending HasRealm
  final T game;

  /// A function that creates a [Game] that this widget will render.
  final GameFactory<T>? gameFactory;

  /// The text direction to be used in text elements in a game.
  final TextDirection? textDirection;

  /// Builder to provide a widget tree to be built while the Game's [Future]
  /// provided via `Game.onLoad` and `Game.onMount` is not resolved.
  /// By default this is an empty Container().
  final GameLoadingWidgetBuilder? loadingBuilder;

  /// If set, errors during the onLoad method will not be thrown
  /// but instead this widget will be shown. If not provided, errors are
  /// propagated up.
  final GameErrorWidgetBuilder? errorBuilder;

  /// Builder to provide a widget tree to be built between the game elements and
  /// the background color provided via [Game.backgroundColor].
  final WidgetBuilder? backgroundBuilder;

  /// A map to show widgets overlay.
  ///
  /// See also:
  /// - [GameWidget]
  /// - [Game.overlays]
  final Map<String, OverlayWidgetBuilder<T>>? overlayBuilderMap;

  /// The [FocusNode] to control the games focus to receive event inputs.
  /// If omitted, defaults to an internally controlled focus node.
  final FocusNode? focusNode;

  /// Whether the [focusNode] requests focus once the game is mounted.
  /// Defaults to true.
  final bool autofocus;

  /// Mouse cursor to use for the game
  final MouseCursor? mouseCursor;

  /// List of overlay widgets that should be active when the game starts
  final List<String>? initialActiveOverlays;
  const BackboneGameWidget({
    Key? key,
    required this.game,
    this.textDirection,
    this.loadingBuilder,
    this.errorBuilder,
    this.backgroundBuilder,
    this.overlayBuilderMap,
    this.initialActiveOverlays,
    this.focusNode,
    this.autofocus = true,
    this.mouseCursor,
    this.gameFactory,
  }) : super(key: key);

  @override
  State<BackboneGameWidget<T>> createState() => _BackboneGameWidgetState<T>();
}

class _BackboneGameWidgetState<T extends HasRealm>
    extends State<BackboneGameWidget<T>> {
  _BackboneGameWidgetState() {
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handleEvent);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_getWidgetInfo);
  }

  void _getWidgetInfo(_) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    if (widget.game.realmReady) {
      widget.game.realm.getResource<Input>().widgetOffset =
          renderBox.localToGlobal(Offset.zero);
    }
  }

  @override
  void dispose() {
    super.dispose();
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handleEvent);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  void _handleEvent(PointerEvent event) {
    if (widget.game.realmReady == false) return;
    final start = DateTime.now();

    if (event is PointerAddedEvent) {
      widget.game.realm.getResource<Input>().onPointerAdded(event);
    } else if (event is PointerHoverEvent) {
      widget.game.realm.getResource<Input>().onPointerHover(event);
    } else if (event is PointerRemovedEvent) {
      widget.game.realm.getResource<Input>().onPointerRemoved(event);
    } else if (event is PointerDownEvent) {
      widget.game.realm.getResource<Input>().onPointerDown(event);
    } else if (event is PointerMoveEvent) {
      widget.game.realm.getResource<Input>().onPointerMove(event);
    } else if (event is PointerUpEvent) {
      widget.game.realm.getResource<Input>().onPointerUp(event);
    }
    if (widget.game.realm.logPerformanceData) {
      Log.logSystemPerformance("pointerRouter", null,
          DateTime.now().difference(start).inMilliseconds);
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (widget.game.realmReady == false) return false;
    return widget.game.onKeyEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: widget.game,
      autofocus: widget.autofocus,
      backgroundBuilder: widget.backgroundBuilder,
      errorBuilder: widget.errorBuilder,
      focusNode: widget.focusNode,
      initialActiveOverlays: widget.initialActiveOverlays,
      key: widget.key,
      loadingBuilder: widget.loadingBuilder,
      mouseCursor: widget.mouseCursor,
      overlayBuilderMap: widget.overlayBuilderMap,
      textDirection: widget.textDirection,
    );
  }
}
