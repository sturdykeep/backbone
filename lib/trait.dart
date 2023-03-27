import 'package:backbone/node.dart';
import 'package:flame/game.dart';

/// Basic class for all traits.
abstract class ATrait<T extends FlameGame> {
  ANode<T>? node;

  /// Called when the trait is added to a node
  void onAdd(ANode<T> node) {}

  /// Called when the trait is removed from a node
  void onRemove(ANode<T> node) {}
}
