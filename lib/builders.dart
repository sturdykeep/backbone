import 'dart:collection';

import 'package:backbone/archetype.dart';
import 'package:backbone/message.dart';
import 'package:backbone/node.dart';
import 'package:backbone/system.dart';
import 'package:backbone/realm.dart';

typedef Plugin = void Function(RealmBuilder builder);

class RealmBuilder {
  // Traits
  final HashSet<Type> registeredTraits = HashSet();
  RealmBuilder withTrait(Type trait) {
    if (registeredTraits.contains(trait) == false) {
      registeredTraits.add(trait);
    }
    return this;
  }

  // Systems
  final List<System> systems = [];
  final List<MessageSystem> messageSystems = [];
  RealmBuilder withSystem(System system) {
    systems.add(system);
    return this;
  }

  RealmBuilder withMessageSystem(MessageSystem system) {
    messageSystems.add(system);
    return this;
  }

  // Resources
  final HashMap<Type, dynamic> resources = HashMap();
  RealmBuilder withResource(Type resourceType, dynamic resource) {
    resources[resourceType] = resource;
    return this;
  }

  // Plugins
  RealmBuilder withPlugin(Plugin plugin) {
    plugin(this);
    return this;
  }

  Realm build() {
    var possibleArchetypes = Archetype.allCombinations(registeredTraits);
    var archetypeBuckets = HashMap<Archetype, List<ANode>>();
    for (var archetype in possibleArchetypes) {
      archetypeBuckets[archetype] = [];
    }

    return Realm(
      registeredTraits,
      archetypeBuckets,
      systems,
      messageSystems,
      resources,
    );
  }
}
