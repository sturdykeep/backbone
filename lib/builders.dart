import 'dart:collection';

import 'package:backbone/archetype.dart';
import 'package:backbone/logging/log.dart';
import 'package:backbone/logging/no_op_log.dart';
import 'package:backbone/node.dart';
import 'package:backbone/system.dart';
import 'package:backbone/realm.dart';
import 'package:flame/game.dart';

typedef Plugin<T extends FlameGame> = void Function(RealmBuilder<T> builder);

class RealmBuilder<T extends FlameGame> {
  // Traits
  final HashSet<Type> registeredTraits = HashSet();
  RealmBuilder<T> withTrait(Type trait) {
    if (registeredTraits.contains(trait) == false) {
      registeredTraits.add(trait);
    }
    return this;
  }

  // Systems
  final List<System<T>> systems = [];
  final List<MessageSystem<T>> messageSystems = [];
  RealmBuilder<T> withSystem(System<T> system) {
    systems.add(system);
    return this;
  }

  RealmBuilder<T> withMessageSystem(MessageSystem<T> system) {
    messageSystems.add(system);
    return this;
  }

  // Resources
  final HashMap<Type, dynamic> resources = HashMap();
  RealmBuilder<T> withResource(Type resourceType, dynamic resource) {
    resources[resourceType] = resource;
    return this;
  }

  // Plugins
  RealmBuilder<T> withPlugin(Plugin plugin) {
    plugin(this);
    return this;
  }

  Realm<T> build({
    Log? realmLogger,
  }) {
    var possibleArchetypes = Archetype.allCombinations(registeredTraits);
    var archetypeBuckets = HashMap<Archetype, List<ANode<T>>>();
    for (var archetype in possibleArchetypes) {
      archetypeBuckets[archetype] = [];
    }

    return Realm<T>(
      registeredTraits,
      archetypeBuckets,
      systems,
      messageSystems,
      resources,
      realmLogger ?? NoOpLog(),
    );
  }
}
