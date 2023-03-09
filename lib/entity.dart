import 'package:backbone/archetype.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/trait.dart';
import 'package:collection/collection.dart';

class Entity {
  Realm? realm;
  final List<Trait> traits = [];

  Entity({this.realm});

  Archetype get archetype => Archetype(traits.map((t) => t.runtimeType));
  // Parent
  Entity? _parent;
  Entity? get parent => _parent;
  set parent(Entity? value) {
    if (_parent != value) {
      value?.addChild(this);
    }
  }

  // Children
  final List<Entity> _children = [];
  List<Entity> get children => List.unmodifiable(_children);

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
    for (final trait in traits) {
      if (trait is T) {
        return trait;
      }
    }
    return null;
  }

  /// Get a trait, otherwise throw an exception.
  T get<T extends Trait>() {
    final trait = tryGet<T>();
    if (trait != null) {
      return trait;
    } else {
      throw Exception('Trait not found: ${T.toString()}');
    }
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

  /// Try to get a trait by walking up the entity tree, otherwise return null.
  T? find<T extends Trait>({bool includeSelf = true}) {
    if (includeSelf) {
      final trait = tryGet<T>();
      if (trait != null) {
        return trait;
      }
    }
    if (_parent != null) {
      return _parent!.find<T>(includeSelf: true);
    }
    return null;
  }

  /// Gather all traits of a given type by walking up the entity tree.
  /// Returned order is from the entity itself to the root.
  List<T> findAll<T extends Trait>({bool includeSelf = true}) {
    final traits = <T>[];
    Entity? toCheck = includeSelf ? this : parent;
    while (toCheck != null) {
      final trait = toCheck.tryGet<T>();
      if (trait != null) {
        traits.add(trait);
      }
      toCheck = toCheck.parent;
    }
    return traits;
  }

  /// Gather all traits of a given type by walking up the entity tree.
  /// Returned order is from the root to the entity itself.
  Iterable<T> findAllReverse<T extends Trait>({bool includeSelf = true}) {
    return findAll<T>(includeSelf: includeSelf).reversed;
  }

  /// Find the first trait of a given type by walking up the entity tree.
  /// The search doesn't include the entity itself.
  T? findFirst<T extends Trait>() {
    Entity? toCheck = parent;
    while (toCheck != null) {
      final trait = toCheck.tryGet<T>();
      if (trait != null) {
        return trait;
      }
      toCheck = toCheck.parent;
    }
    return null;
  }

  // Children
  void addChild(Entity child) {
    if (child.realm != realm) {
      throw Exception('Cannot add child to entity in different realm.');
    }
    if (child._parent != null) {
      child._parent = null;
    }

    _children.add(child);
    child._parent = this;
  }

  void removeChild(Entity child) {
    if (child._parent != this) {
      throw Exception(
          'Cannot remove child from entity that is not its parent.');
    }

    _children.remove(child);
    child._parent = null;
  }
}
