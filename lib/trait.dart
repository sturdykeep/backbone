import 'package:backbone/entity.dart';

/// Basic class for all traits.
abstract class Trait {
  late Entity entity;

  /// Called when the trait is added to an entity.
  void onAdd() {}
  /// Called when the trait is removed from an entity.
  void onRemove() {}
}
