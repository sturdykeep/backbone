import 'dart:async';
import 'dart:collection';

import 'package:backbone/archetype.dart';
import 'package:backbone/entity.dart';
import 'package:backbone/iterable.dart';
import 'package:backbone/log.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/time.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/message.dart';
import 'package:backbone/system.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';

typedef SlowMessageDebugCallback = void Function(AMessage slowMessage);

/// Realm is the main entry point for all backbone systems.
/// You can have multiple realm in your game.
class Realm extends Component with HasGameRef {
  int nextUniqueId = 0;

  /// Get a unique id for this world instance.
  /// IDs are only unqiue within a realm.
  int getNextUniqueId() => nextUniqueId++;

  /// All registered trait types within this realm.
  late final HashSet<Type> registeredTraits;

  /// Entities sorted into buckets based on their archetype.
  late final HashMap<Archetype, List<Entity>> archetypeBuckets;
  late final List<Archetype> archetypeBucketsKeys;
  late final List<List<Entity>> archetypeBucketsValues;
  final List<Archetype> nonEmptyBucketKeys = [];
  final List<List<Entity>> nonEmptyBucketValues = [];

  /// List of all registered systems
  late final List<System> systems;
  late final HashMap<System, SystemResult> systemResults = HashMap();

  /// List of all messages systems
  late final List<MessageSystem> messageSystems;

  // List of all render systems
  final List<RenderSystem> renderSystems;

  /// Map of types with the connected resource
  late final HashMap<Type, dynamic> resources;

  /// Current frame number being processed
  int frame = 0;
  static int globalFrame = 0;

  bool logPerformanceData = false;

  /// Create a new Realm and provide the traids, ???, systems, messages and resources
  Realm(this.registeredTraits, this.archetypeBuckets, this.systems,
      this.messageSystems, this.renderSystems, this.resources) {
    archetypeBucketsKeys = archetypeBuckets.keys.toList();
    archetypeBucketsValues = archetypeBuckets.values.toList();
    addResource(Time());
    addResource(Input());
  }

  /// Used for debugging
  SlowMessageDebugCallback? slowMessageDebugCallback;

  // Message system
  bool messageSystemPaused = false;
  int messageSystemTimeBudget = 8;
  final Queue<AMessage> messageQueue = Queue();
  final HashMap<AMessage, Completer<dynamic>> messageCompleters = HashMap();

  /// Push a new message to the end of the queue
  Future<T?> pushMessage<T>(AMessage<T> message) {
    final completer = Completer();
    messageQueue.add(message);
    messageCompleters.putIfAbsent(message, () => completer);
    return completer.future.then((v) => v as T?);
  }

  /// Push a message to the first pposition in the queue
  Future<T?> pushMessageToFront<T>(AMessage<T> message) {
    final completer = Completer();
    messageQueue.addFirst(message);
    messageCompleters.putIfAbsent(message, () => completer);
    return completer.future.then((v) => v as T?);
  }

  /// Push a message right after a given message
  Future<T?> pushMessageAfter<T>(AMessage<T> message, AMessage after) {
    final completer = Completer();
    final oldMessages = messageQueue.toList();
    messageQueue.clear();
    for (var oldMessage in oldMessages) {
      messageQueue.add(oldMessage);
      if (oldMessage == after) {
        messageQueue.add(message);
      }
    }
    messageCompleters.putIfAbsent(message, () => completer);
    return completer.future.then((v) => v as T?);
  }

  /// Push multiple messages to the queue
  Future<List<dynamic>> pushMessagesToFrontInOrder(
      Iterable<AMessage> messages) {
    // messages: [a, b, c]
    // messageQueue: [c, b, a] (reverse, but execute in order)
    var messagesReverse = messages.toList().reversed;
    final List<Completer> completers = [];
    for (var message in messagesReverse) {
      final completer = Completer();
      messageQueue.addFirst(message);
      messageCompleters.putIfAbsent(message, () => completer);
      completers.add(completer);
    }
    return Future.wait(completers.map((e) => e.future));
  }

  /// Get the first message in the queue without removing it
  AMessage peekMessage() {
    return messageQueue.first;
  }

  /// Get the first message in the queue and remove it
  AMessage popMessage() {
    return messageQueue.removeFirst();
  }

  /// Resolves the `Future` of the given message with a result.
  /// Always returns true for use in message systems on return.
  /// ```
  /// bool exampleMessageSystem(Realm realm, AMessage message) {
  ///   if (message is ExampleMessage) {
  ///     return realm.resolveMessage(message, 'result');
  ///   }
  ///   return false;
  /// }
  /// ```
  bool resolveMessage<T>(AMessage<T> message, T result) {
    final completer = messageCompleters.remove(message);
    if (completer != null) {
      completer.complete(result);
    }
    return true;
  }

  /// Is there any message in the queue
  bool get hasMessage => messageQueue.isNotEmpty;

  /// Pause the message system
  void pauseMessageSystem() {
    messageSystemPaused = true;
  }

  /// Resume the message system
  void resumeMessageSystem() {
    messageSystemPaused = false;
  }

  // Add a new resource to the Realm
  void addResource<R extends dynamic>(R resource) {
    resources[R] = resource;
  }

  // Return a resource or null
  R? tryGetResource<R extends dynamic>() {
    return resources[R] as R?;
  }

  // Return a resource that must exists
  R getResource<R extends dynamic>() {
    return resources[R]! as R;
  }

  /// Try to remove a resource and return it, might be null
  R? removeResource<R extends dynamic>() {
    return resources.remove(R) as R?;
  }

  // Systems and their results
  /// Make sure the system was run this frame, or run it.
  /// Returns the result of the system.
  R checkOrRunSystem<R>(System system, {bool force = false}) {
    if (force == false) {
      if (systemResults.containsKey(system) == false) {
        systemResults[system] = system(this);
      }
    } else {
      systemResults[system] = system(this);
    }
    return systemResults[system] as R;
  }

  /// Make sure the system was run this frame, or run it.
  /// Returns the result of the system.
  R checkOrRunSystemByName<R>(String name, {bool force = false}) {
    return checkOrRunSystem<R>(
        systems.firstWhere((s) => getSystemName(s) == name),
        force: force);
  }

  // Traits and entities
  /// Remove an entity from a bucket
  void removeFromBuckets(Entity entity) {
    // Remove the trait from the existing archetype storage
    final currentBucket = entity.archetype;
    final currentBucketList = archetypeBuckets[currentBucket]!;
    currentBucketList.remove(entity);

    // also remove from the non-empty bucket cache
    final index = nonEmptyBucketKeys.indexOf(currentBucket);
    if (index != -1) {
      // check if it's actually empty now
      if (nonEmptyBucketValues[index].isEmpty) {
        nonEmptyBucketKeys.removeAt(index);
        nonEmptyBucketValues.removeAt(index);
      }
    }
  }

  /// Push an entity into an existing archetype
  void putIntoBucket(Entity entity) {
    // Add the trait to the new archetype storage
    final archetype = entity.archetype;
    if (archetype.length > 0) {
      if (archetypeBuckets.containsKey(archetype) == false) {
        throw Exception('Archetype $archetype is not registered');
      }
      archetypeBuckets[archetype]!.add(entity);

      // if necessary add to the non-empty bucket cache
      final index = nonEmptyBucketKeys.indexOf(archetype);
      if (index == -1) {
        nonEmptyBucketKeys.add(archetype);
        nonEmptyBucketValues.add(archetypeBuckets[archetype]!);
      }
    }
  }

  /// Register an entity in the realm.
  /// You cannot register an entity twice.
  void addEntity(Entity entity) {
    if (entity.realm != null) {
      throw Exception('Entity $entity is already registered in a realm.');
    }
    entity.realm = this;
    putIntoBucket(entity);
  }

  /// Remove an entity from the realm.
  bool removeEntity(Entity entity) {
    if (entity.realm == this) {
      removeFromBuckets(entity);
      return true;
    }
    return false;
  }

  /// Add a trait to an existing entity.
  void addTrait<C extends Trait>(C trait, Entity entity) {
    trait.entity = entity;
    if (entity.realm != this) {
      throw Exception('Entity $entity doesn\'t exist in this realm.');
    }
    if (trait.entity != entity) {
      throw Exception(
          'Trait $trait is already added to another entity ${trait.entity}');
    }

    removeFromBuckets(entity);
    entity.traits.add(trait);
    putIntoBucket(entity);
    trait.onAdd();
  }

  /// Remove a trait from an existing entity.
  void removeTrait<C extends Trait>(C trait, Entity entity) {
    if (entity.realm != this) {
      throw Exception('Entity $entity doesn\'t exist in this realm.');
    }

    removeFromBuckets(entity);
    entity.traits.remove(trait);
    putIntoBucket(entity);
    trait.onRemove();
  }

  // Query
  /// Query the realm for a list of entities that match the filter.
  /// This operation is O(n) where n is the number of Archetypes (combination of possible traits).
  MultiIterableView<Entity> query<F extends Filter>(F filter) {
    List<List<Entity>> result = [];
    final length = nonEmptyBucketKeys.length;
    for (var i = 0; i < length; i++) {
      final archetype = nonEmptyBucketKeys[i];
      final entities = nonEmptyBucketValues[i];

      if (entities.isNotEmpty && filter.matches(archetype)) {
        result.add(entities);
      }
    }
    return MultiIterableView(result);
  }

  // Update Loop
  /// Update all details of the realm, called by Flame
  @override
  void update(double dt) {
    // Globally the frame would be set only once at the beginning of the frame
    if (globalFrame != frame) {
      globalFrame = frame;
    }

    final updateStart = DateTime.now();
    // Update the time
    getResource<Time>().delta = dt;

    // Reset the system results
    systemResults.clear();

    // Update all the systems
    while (true) {
      // Run the first system which doesn't have a result yet
      final system = systems
          .firstWhereOrNull((s) => systemResults.containsKey(s) == false);
      if (system == null) {
        break;
      }
      checkOrRunSystem(system);
    }

    // Proccess the message queue
    // ...and try to keep at least 60 fps
    final messagesProcessStartTime = DateTime.now();
    while (messageSystemPaused == false) {
      if (messageQueue.isEmpty) break;
      if (DateTime.now().difference(messagesProcessStartTime).inMilliseconds >
          messageSystemTimeBudget) break;

      final currentMessage = popMessage();
      final messageProcessTimeStart = DateTime.now();

      for (final system in messageSystems) {
        if (system(this, currentMessage)) {
          // Make sure completer is cleaned up
          // and future is resolved
          final completer = messageCompleters.remove(currentMessage);
          if (completer != null) {
            completer.complete();
          }
          break;
        }
      }

      // Debug code for development
      if (logPerformanceData) {
        final messageExecutionTime =
            DateTime.now().difference(messageProcessTimeStart);
        if (messageExecutionTime.inMilliseconds >= messageSystemTimeBudget) {
          debugPrint(
              '(Warning) Message ${currentMessage.runtimeType} took too long (${messageExecutionTime.inMilliseconds} ms) to process');
          slowMessageDebugCallback?.call(currentMessage);
        }
      }
    }

    // Clear the inputs
    final input = getResource<Input>();
    input.clear();
    // Update the frame count
    frame += 1;
    if (logPerformanceData) {
      Log.logPerformance('Update',
          DateTime.now().difference(updateStart).inMilliseconds.toString());
      // Try to process the log
      Log.processPerformanceLogs();
    }
  }

  @override
  void onMount() {
    if (logPerformanceData) {
      Log.logPerformance('Running', 'true');
    }
  }

  @override
  void renderTree(Canvas canvas) {
    final renderStart = DateTime.now();
    super.renderTree(canvas);
    if (logPerformanceData) {
      Log.logPerformance('Render',
          DateTime.now().difference(renderStart).inMilliseconds.toString());
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Render the systems
    for (final system in renderSystems) {
      system(this, canvas);
    }
  }
}
