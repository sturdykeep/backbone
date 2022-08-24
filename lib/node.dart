import 'dart:collection';

import 'package:backbone/archetype.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/world.dart';
import 'package:flame/components.dart';

abstract class ANode extends Component with HasGameRef {
  World? world;
  Archetype? bucket;
  final List<ATrait> _traits = [];

  ANode();
  Archetype get archetype => Archetype(_traits.map((c) => c.runtimeType));

  // Integrate into Flame
  @override
  void onMount() {
    super.onMount();
    world = findWorldParent();
    world?.addNode(this);
  }

  @override
  void onRemove() {
    super.onRemove();
    world?.removeNode(this);
  }

  // Methods
  List<ATrait> get traits => _traits.toList();
  List<ATrait> get sortedTraits {
    final List<ATrait> sorted = _traits.toList();
    sorted.sort((a, b) => a.toString().compareTo(b.toString()));
    return sorted;
  }

  // Tree searching
  ANode? findNodeParent() {
    var componentToCheck = parent;
    ANode? parentNode;
    while (componentToCheck != null) {
      if (componentToCheck is ANode) {
        parentNode = componentToCheck;
        break;
      }
      componentToCheck = componentToCheck.parent!;
    }
    return parentNode;
  }

  List<ANode> findNodeChildren() {
    var children = <ANode>[];
    var childrenToCheck = Queue<Component>();
    childrenToCheck.addAll(children);

    while (childrenToCheck.isNotEmpty) {
      final component = childrenToCheck.removeFirst();
      if (component is ANode) {
        children.add(component);
      }
      childrenToCheck.addAll(component.children);
    }

    return children;
  }

  World? findWorldParent() {
    var componentToCheck = parent;
    World? parentWorld;
    while (componentToCheck != null) {
      if (componentToCheck is World) {
        parentWorld = componentToCheck;
        break;
      }
      componentToCheck = componentToCheck.parent!;
    }
    return parentWorld;
  }

  List<C> findChildren<C extends Component>() {
    var children = <C>[];
    var childrenToCheck = Queue<Component>();
    childrenToCheck.addAll(this.children);

    while (childrenToCheck.isNotEmpty) {
      final component = childrenToCheck.removeFirst();
      if (component is C) {
        children.add(component);
      }
      if (component is ANode) {
        continue;
      }
      childrenToCheck.addAll(component.children);
    }

    return children;
  }

  // Traits
  void addTrait(ATrait trait) {
    _traits.add(trait);
    world?.addTraitToNode(trait, this);
  }

  void removeTrait<T extends ATrait>() {
    final trait =
        _traits.cast<ATrait?>().firstWhere((c) => c is T, orElse: () => null);
    if (trait != null) {
      _traits.remove(trait);
      world?.removeTraitFromNode(trait, this);
    }
  }

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
}
