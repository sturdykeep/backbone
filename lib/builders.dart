import 'dart:collection';

import 'package:backbone/archetype.dart';
import 'package:backbone/node.dart';
import 'package:backbone/system.dart';
import 'package:backbone/world.dart';

typedef Plugin = void Function(WorldBuilder builder);

class WorldBuilder {
  // Traits
  final HashSet<Type> registeredTraits = HashSet();
  WorldBuilder withTrait(Type trait) {
    if (registeredTraits.contains(trait) == false) {
      registeredTraits.add(trait);
    }
    return this;
  }

  // Systems
  final List<System> systems = [];
  final List<MessageSystem> messageSystems = [];
  WorldBuilder withSystem(System system) {
    systems.add(system);
    return this;
  }

  WorldBuilder withMessageSystem(MessageSystem system) {
    messageSystems.add(system);
    return this;
  }

  // Resources
  final HashMap<Type, dynamic> resources = HashMap();
  WorldBuilder withResource(Type resourceType, dynamic resource) {
    resources[resourceType] = resource;
    return this;
  }

  // Plugins
  WorldBuilder withPlugin(Plugin plugin) {
    plugin(this);
    return this;
  }

  World build() {
    var possibleArchetypes = Archetype.allCombinations(registeredTraits);
    var archetypeBuckets = HashMap<Archetype, List<ANode>>();
    for (var archetype in possibleArchetypes) {
      archetypeBuckets[archetype] = [];
    }

    return World(
      registeredTraits,
      archetypeBuckets,
      systems,
      messageSystems,
      resources,
    );
  }
}
