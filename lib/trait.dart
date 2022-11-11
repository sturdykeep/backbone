import 'package:backbone/node.dart';

/// Basic class for all traits.
abstract class ATrait {
  ANode? node;

  /// Called when the trait is added to a node
  void onAdd(ANode node) {}

  /// Called when the trait is removed from a node
  void onRemove(ANode node) {}
}
