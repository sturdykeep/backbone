import 'dart:async';
import 'dart:collection';

import 'package:backbone/archetype.dart';
import 'package:backbone/iterable.dart';
import 'package:backbone/log.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/time.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/message.dart';
import 'package:backbone/node.dart';
import 'package:backbone/system.dart';
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';

typedef SlowMessageDebugCallback = void Function(AMessage slowMessage);

/// Realm is the main entry point for all backbone systems
/// You can have multiple realm in your game
class Realm extends Component with HasGameRef {
  int nextUniqueId = 0;

  /// Get a unique id for this wolrd instance
  /// ID's are only unqiue by realm
  int getNextUniqueId() => nextUniqueId++;

  /// All type of trais registered in this Realm
  late final HashSet<Type> registeredTraits;

  /// Nodes sorted into lists by their archetype
  late final HashMap<Archetype, List<ANode>> archetypeBuckets;
  late final List<Archetype> archetypeBucketsKeys;
  late final List<List<ANode>> archetypeBucketsValues;
  final List<Archetype> nonEmptyBucketKeys = [];
  final List<List<ANode>> nonEmptyBucketValues = [];

  /// List of all registered systems
  late final List<System> systems;
  late final HashMap<System, SystemResult> systemResults = HashMap();

  /// List of all messages systems
  late final List<MessageSystem> messageSystems;

  /// Map of types with the connected resource
  late final HashMap<Type, dynamic> resources;

  /// Map of nodes sorted by their type
  final HashMap<Type, HashSet<ANode>> nodesByType = HashMap();

  /// Current frame number being processed
  int frame = 0;
  static int globalFrame = 0;

  bool logPerformanceData = false;

  /// Create a new Realm and provide the traids, ???, systems, messages and resources
  Realm(this.registeredTraits, this.archetypeBuckets, this.systems,
      this.messageSystems, this.resources) {
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
    if (force || systemResults.containsKey(system) == false) {
      final systemStart = DateTime.now();
      systemResults[system] = system(this);
      if (logPerformanceData) {
        Log.logSystemPerformance(
          getSystemName(system),
          null,
          DateTime.now().difference(systemStart).inMilliseconds,
        );
      }
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

  // Traits and nodes
  /// Remove a node from a bucket
  void removeNodeFromBuckets(ANode node) {
    // Remove the trait from the existing archetype storage
    final currentBucket = node.bucket;
    if (currentBucket != null) {
      final currentBucketList = archetypeBuckets[currentBucket]!;
      currentBucketList.remove(node);
      node.bucket = null;

      // also remove from the non-emmpty bucket cache
      final index = nonEmptyBucketKeys.indexOf(currentBucket);
      if (index != -1) {
        // check if it's actually empty now
        if (nonEmptyBucketValues[index].isEmpty) {
          nonEmptyBucketKeys.removeAt(index);
          nonEmptyBucketValues.removeAt(index);
        }
      }
    }
  }

  /// Push a node into an existing archetype
  void putNodeIntoBucket(ANode node) {
    // Add the trait to the new archetype storage
    final archetype = node.archetype;
    if (archetype.length > 0) {
      if (archetypeBuckets.containsKey(archetype) == false) {
        throw Exception('Archetype $archetype is not registered');
      }
      archetypeBuckets[archetype]!.add(node);
      node.bucket = archetype;

      // if necessary add to the non-empty bucket cache
      final index = nonEmptyBucketKeys.indexOf(archetype);
      if (index == -1) {
        nonEmptyBucketKeys.add(archetype);
        nonEmptyBucketValues.add(archetypeBuckets[archetype]!);
      }
    }
  }

  /// Add a node to a Realm
  void registerNode<N extends ANode>(N node) {
    assert(node.isBackboneMounted == true,
        'Add the node to the realm via add or addAll. Do not call registerNode');
    final type = node.runtimeType;
    if (nodesByType.containsKey(type) == false) {
      nodesByType[type] = HashSet();
    }
    nodesByType[type]!.add(node);
    putNodeIntoBucket(node);
  }

  /// Remove an existing node from the realm
  void removeNode<N extends ANode>(N node) {
    final type = node.runtimeType;
    if (!nodesByType.containsKey(type)) {
      throw Exception('No nodes of type $type were ever added');
    }
    nodesByType[type]!.remove(node);
    node.realm = this;

    removeNodeFromBuckets(node);
  }

  /// Addd a trait to an existing node
  void addTraitToNode<C extends ATrait, N extends ANode>(C trait, N node) {
    if (node.realm != this) {
      throw Exception(
          'Node $node is not in this realm. It was added to another realm');
    }
    if (trait.node != null && trait.node != node) {
      throw Exception(
          'Trait $trait is already added to another node ${trait.node}');
    }

    removeNodeFromBuckets(node);
    putNodeIntoBucket(node);
  }

  /// Remove a trait from an existing node
  void removeTraitFromNode<C extends ATrait, N extends ANode>(C trait, N node) {
    if (node.realm != this) {
      throw Exception(
          'Node $node is not in this realm. It was added to another realm');
    }

    removeNodeFromBuckets(node);
    putNodeIntoBucket(node);
  }

  // Query
  /// Query the realm for a list of nodes
  MultiIterableView<ANode> query<N extends ANode, F extends AFilter>(F filter,
      {bool onlyLoaded = false}) {
    List<List<ANode>> result = [];
    final length = nonEmptyBucketKeys.length;
    for (var i = 0; i < length; i++) {
      final archetype = nonEmptyBucketKeys[i];
      final nodes = nonEmptyBucketValues[i];

      if (nodes.isNotEmpty && filter.matches(archetype)) {
        if (onlyLoaded) {
          result.add(nodes.where((node) => node.isLoaded).toList());
        } else {
          result.add(nodes);
        }
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
}
