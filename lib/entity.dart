import 'package:backbone/archetype.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:collection/collection.dart';

class Entity {
  Realm? realm;
  final List<Trait> traits = [];

  Entity({this.realm});

  Archetype get archetype => Archetype(traits.map((t) => t.runtimeType));

  /// Add a trait to an existing entity.
  void add<C extends Trait>(C trait) {
    if (realm == null) {
      traits.add(trait);
      trait.entity = this;
    } else {
      realm!.addTrait(trait, this);
    }
  }

  /// Remove a trait from an existing entity.
  void remove<C extends Trait>(C trait) {
    if (realm == null) {
      traits.remove(trait);
    } else {
      realm!.removeTrait(trait, this);
    }
  }

  /// Try to get a trait, otherwise return null.
  T? tryGet<T extends Trait>() {
    return traits.firstWhereOrNull((t) => t is T) as T?;
  }

  /// Get a trait, otherwise throw an exception.
  T get<T extends Trait>() {
    return traits.firstWhere((t) => t is T) as T;
  }

  /// Try to get a trait, otherwise add it.
  T getOrAdd<T extends Trait>(T Function() create) {
    final trait = tryGet<T>();
    if (trait != null) {
      return trait;
    } else {
      final newTrait = create();
      add(newTrait);
      return newTrait;
    }
  }
}
