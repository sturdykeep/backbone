import 'dart:collection';

import 'package:backbone/archetype.dart';
import 'package:backbone/entity.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';

/// Nodes are a collection of game objects. Nodes can
/// have traits and their entities can be processed by systems.
mixin Node on HasGameRef {
  /// Realm of the node, null if not yet added to a realm.
  Realm? realm;
  /// Entity of the node, null if not yet added to a realm.
  Entity? entity;
  /// Archetype of the underlying entity.
  Archetype get archetype => entity?.archetype ?? Archetype([]);
  /// Whether the node is mounted to a realm.
  bool get isMountedToRealm => realm != null;

  // Integrate into Flame
  @override
  void onMount() {
    super.onMount();
    realm = findRealmParent();
    assert(realm != null, 'Node must be a child of a realm');
    entity = realm!.newEntity();
    entity!.add(NodeTrait(this));
  }

  @override
  void onRemove() {
    super.onRemove();
    realm!.removeEntity(entity!);
    entity = null;
  }

  // Methods
  // Tree searching
  /// Get the parent of the node, it might return null
  Node? findNodeParent() {
    var componentToCheck = parent;
    Node? parentNode;
    while (componentToCheck != null) {
      if (componentToCheck is Node) {
        parentNode = componentToCheck;
        break;
      }
      componentToCheck = componentToCheck.parent;
    }
    return parentNode;
  }

  /// Get all child nodes of the current node
  List<Node> findNodeChildren() {
    var result = <Node>[];
    var childrenToCheck = Queue<Component>();
    childrenToCheck.addAll(children);

    while (childrenToCheck.isNotEmpty) {
      final component = childrenToCheck.removeFirst();
      if (component is Node) {
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
      if (component is Node) {
        continue;
      }
      childrenToCheck.addAll(component.children);
    }

    return result;
  }

  // Utilities
  int compareToOnPriority(Node other) {
    return priority.compareTo(other.priority);
  }
}

/// A trait that allows to access a node through the entity.
class NodeTrait extends Trait {
  /// The node that this trait is attached to.
  final Node node;

  NodeTrait(this.node);
}