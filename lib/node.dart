import 'dart:collection';

import 'package:backbone/archetype.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';

/// Nodes are a collection of game objects. Nodes can
/// have traits. Nodes are processed by systems.
mixin ANode on HasGameRef {
  /// Realm of the node, null if not yet added to a realm
  Realm? realm;
  bool isBackboneMounted = false;

  /// Archetype of this node, based on the used traits
  Archetype? bucket;
  final List<ATrait> _traits = [];

  Archetype get archetype => Archetype(_traits.map((c) => c.runtimeType));

  // Integrate into Flame
  @override
  void onMount() {
    super.onMount();
    realm = findRealmParent();
    assert(realm != null, 'Nodes must be added to a Realm');
    isBackboneMounted = true;
    realm!.registerNode(this);
  }

  @override
  void onRemove() {
    super.onRemove();
    realm!.removeNode(this);
  }

  // Methods
  /// Get all registered traits of a node
  List<ATrait> get traits => _traits.toList();

  /// Get traites sorted by the comparer
  List<ATrait> get sortedTraits {
    final List<ATrait> sorted = _traits.toList();
    sorted.sort((a, b) => a.toString().compareTo(b.toString()));
    return sorted;
  }

  // Tree searching

  /// Get the parent of the node, it might return null
  ANode? findNodeParent() {
    var componentToCheck = parent;
    ANode? parentNode;
    while (componentToCheck != null) {
      if (componentToCheck is ANode) {
        parentNode = componentToCheck;
        break;
      }
      componentToCheck = componentToCheck.parent;
    }
    return parentNode;
  }

  /// Get all child nodes of the current node
  List<ANode> findNodeChildren() {
    var result = <ANode>[];
    var childrenToCheck = Queue<Component>();
    childrenToCheck.addAll(children);

    while (childrenToCheck.isNotEmpty) {
      final component = childrenToCheck.removeFirst();
      if (component is ANode) {
        result.add(component);
      }
      childrenToCheck.addAll(component.children);
    }

    return result;
  }

  /// Get the Realm of the parent
  Realm? findRealmParent() {
    var componentToCheck = parent;
    Realm? parentRealm;
    while (componentToCheck != null) {
      if (componentToCheck is Realm) {
        parentRealm = componentToCheck;
        break;
      }
      componentToCheck = componentToCheck.parent!;
    }
    return parentRealm;
  }

  /// Get all child components of the node
  List<C> findChildren<C extends Component>() {
    var result = <C>[];
    var childrenToCheck = Queue<Component>();
    childrenToCheck.addAll(children);

    while (childrenToCheck.isNotEmpty) {
      final component = childrenToCheck.removeFirst();
      if (component is C) {
        result.add(component);
      }
      if (component is ANode) {
        continue;
      }
      childrenToCheck.addAll(component.children);
    }

    return result;
  }

  // Traits
  /// Add a trait to this node
  void addTrait(ATrait trait) {
    if (trait.node != null && trait.node != this) {
      throw Exception(
          'Trait $trait is already added to another node ${trait.node}');
    }

    _traits.add(trait);
    trait.node = this;
    trait.onAdd(this);
    try {
      realm?.addTraitToNode(trait, this);
    } catch (e) {
      _traits.remove(trait);
      realm?.addTraitToNode(trait, this);
      rethrow;
    }
  }

  /// Remove a trait from a node
  void removeTrait<T extends ATrait>() {
    final trait =
        _traits.cast<ATrait?>().firstWhere((c) => c is T, orElse: () => null);
    if (trait != null) {
      _traits.remove(trait);
      trait.onRemove(this);
      trait.node = null;
      realm?.removeTraitFromNode(trait, this);
    }
  }

  /// Try get a trait from the node
  T? tryGet<T extends ATrait>() {
    final traitsLength = _traits.length;
    for (var i = 0; i < traitsLength; i++) {
      final trait = _traits[i];
      if (trait is T) {
        return trait;
      }
    }
    return null;
  }

  /// Get an existing trait otherwise throws
  T get<T extends ATrait>() {
    final traitsLength = _traits.length;
    for (var i = 0; i < traitsLength; i++) {
      final trait = _traits[i];
      if (trait is T) {
        return trait;
      }
    }
    throw Exception('Trait ${T.toString()} not found');
  }

  /// Gets an existing trait or adds the one returned
  /// by orElse to the trait list.
  T getOrElse<T extends ATrait>(T Function() orElse) {
    final traitsLength = _traits.length;
    for (var i = 0; i < traitsLength; i++) {
      final trait = _traits[i];
      if (trait is T) {
        return trait;
      }
    }
    final elseTrait = orElse();
    addTrait(elseTrait);
    return elseTrait;
  }

  /// Checks if a trait exists in this node
  bool hasTrait<T extends ATrait>() {
    final traitsLength = _traits.length;
    for (var i = 0; i < traitsLength; i++) {
      final trait = _traits[i];
      if (trait is T) {
        return true;
      }
    }
    return false;
  }

  // Utilities
  int compareToOnPriority(ANode other) {
    return priority.compareTo(other.priority);
  }
}
