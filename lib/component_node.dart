import 'package:backbone/node.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// Default node that comes without any traits. This node is based on the
/// component class of Flame.
abstract class ComponentNode<T extends FlameGame> extends Component
    with HasGameRef<T>, ANode<T> {}
