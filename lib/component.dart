import 'dart:collection';

import 'package:backbone/archetype.dart';
import 'package:backbone/entity.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/realm.dart';
import 'package:flame/components.dart';

/// EntityComponent are a collection of game objects. EntityComponent can
/// have traits and their entities can be processed by systems.
mixin HasEntity on Component {
  /// Realm of the node, null if not yet added to a realm.
  late Realm realm;

  /// Entity of the node, null if not yet added to a realm.
  late Entity entity;

  /// Archetype of the underlying entity.
  Archetype get archetype => entity.archetype;

  // Integrate into Flame
  @override
  void onMount() {
    super.onMount();
    final foundRealm = findRealmParent();
    if (foundRealm != null) {
      realm = foundRealm;
    } else {
      throw Exception('Node must be a child of a realm');
    }
    entity = Entity(realm);
    entity.add(ComponentTrait(this));
  }

  @override
  void onRemove() {
    super.onRemove();
    realm.removeEntity(entity);
  }

  // Methods
  // Tree searching
  /// Get the parent of the node, it might return null
  HasEntity? findNodeParent() {
    var componentToCheck = parent;
    HasEntity? parentNode;
    while (componentToCheck != null) {
      if (componentToCheck is HasEntity) {
        parentNode = componentToCheck;
        break;
      }
      componentToCheck = componentToCheck.parent;
    }
    return parentNode;
  }

  /// Get all child nodes of the current node
  List<HasEntity> findNodeChildren() {
    var result = <HasEntity>[];
    var childrenToCheck = Queue<Component>();
    childrenToCheck.addAll(children);

    while (childrenToCheck.isNotEmpty) {
      final component = childrenToCheck.removeFirst();
      if (component is HasEntity) {
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
      if (component is HasEntity) {
        continue;
      }
      childrenToCheck.addAll(component.children);
    }

    return result;
  }

  // Utilities
  int compareToOnPriority(HasEntity other) {
    return priority.compareTo(other.priority);
  }
}

/// Default node that comes without any traits. This node is based on the
/// component class of Flame.
abstract class EntityComponent extends Component with HasEntity {}

/// A trait that allows to access a component through the entity.
class ComponentTrait extends Trait {
  /// The node that this trait is attached to.
  final HasEntity node;

  ComponentTrait(this.node);
}
