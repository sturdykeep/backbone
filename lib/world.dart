import 'dart:collection';

import 'package:backbone/archetype.dart';
import 'package:backbone/prelude/time.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/message.dart';
import 'package:backbone/node.dart';
import 'package:backbone/system.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

class World extends Component with HasGameRef {
  int nextUniqueId = 0;
  int getNextUniqueId() => nextUniqueId++;
  late final HashSet<Type> registeredTraits;
  late final HashMap<Archetype, List<ANode>> archetypeBuckets;
  late final List<System> systems;
  late final List<MessageSystem> messageSystems;
  late final HashMap<Type, dynamic> resources;
  final HashMap<Type, HashSet<ANode>> nodesByType = HashMap();

  World(this.registeredTraits, this.archetypeBuckets, this.systems,
      this.messageSystems, this.resources) {
    addResource(Time());
  }

  // Message system
  bool messageSystemPaused = false;
  final Queue<AMessage> messageQueue = Queue();
  void pushMessage(AMessage message) {
    messageQueue.add(message);
  }

  void pushMessageToFront(AMessage message) {
    messageQueue.addFirst(message);
  }

  void pushMessagesToFrontInOrder(Iterable<AMessage> messages) {
    // messages: [a, b, c]
    // messageQueue: [c, b, a] (reverse, but execute in order)
    var messagesReverse = messages.toList().reversed;
    for (var message in messagesReverse) {
      messageQueue.addFirst(message);
    }
  }

  AMessage peekMessage() {
    return messageQueue.first;
  }

  AMessage popMessage() {
    return messageQueue.removeFirst();
  }

  bool get hasMessage => messageQueue.isNotEmpty;

  void pauseMessageSystem() {
    messageSystemPaused = true;
  }

  void resumeMessageSystem() {
    messageSystemPaused = false;
  }

  // Resources
  void addResource<R extends dynamic>(R resource) {
    resources[R] = resource;
  }

  R? tryGetResource<R extends dynamic>() {
    return resources[R] as R?;
  }

  R getResource<R extends dynamic>() {
    return resources[R]! as R;
  }

  R? removeResource<R extends dynamic>() {
    return resources.remove(R) as R?;
  }

  // Traits and nodes
  void removeNodeFromBuckets(ANode node) {
    // Remove the trait from the existing archetype storage
    final currentBucket = node.bucket;
    if (currentBucket != null) {
      final currentBucketList = archetypeBuckets[currentBucket]!;
      currentBucketList.remove(node);
      node.bucket = null;
    }
  }

  void putNodeIntoBucket(ANode node) {
    // Add the trait to the new archetype storage
    final archetype = node.archetype;
    if (archetype.length > 0) {
      if (archetypeBuckets.containsKey(archetype) == false) {
        throw Exception('Archetype $archetype is not registered');
      }
      archetypeBuckets[archetype]!.add(node);
      node.bucket = archetype;
    }
  }

  void addNode<N extends ANode>(N node) {
    final type = node.runtimeType;
    if (!nodesByType.containsKey(type)) {
      nodesByType[type] = HashSet();
    }
    nodesByType[type]!.add(node);
    node.world = this;

    putNodeIntoBucket(node);
  }

  void removeNode<N extends ANode>(N node) {
    final type = node.runtimeType;
    if (!nodesByType.containsKey(type)) {
      throw Exception('No nodes of type $type were ever added');
    }
    nodesByType[type]!.remove(node);
    node.world = this;

    removeNodeFromBuckets(node);
  }

  void addTraitToNode<C extends ATrait, N extends ANode>(C trait, N node) {
    if (node.world != this) {
      throw Exception(
          'Node $node is not in this world. It was added to another world');
    }

    removeNodeFromBuckets(node);
    putNodeIntoBucket(node);
  }

  void removeTraitFromNode<C extends ATrait, N extends ANode>(C trait, N node) {
    if (node.world != this) {
      throw Exception(
          'Node $node is not in this world. It was added to another world');
    }

    removeNodeFromBuckets(node);
    putNodeIntoBucket(node);
  }

  // Query
  List<ANode> query<N extends ANode, F extends AFilter>(F filter,
      {bool onlyLoaded = false}) {
    List<ANode> result = [];
    for (final archetype in archetypeBuckets.keys) {
      final nodes = archetypeBuckets[archetype]!;
      if (filter.matches(archetype)) {
        result.addAll(nodes);
      }
    }

    if (onlyLoaded) {
      result.retainWhere((node) => node.isLoaded);
    }
    return result;
  }

  // The update loop
  @override
  void update(double dt) {
    getResource<Time>().delta = dt;

    // Update all the systems
    for (final system in systems) {
      system(this);
    }

    // Proccess the message queue
    // ...and try to keep at least 60 fps
    final messagesProcessStartTime = DateTime.now();
    while (messageSystemPaused == false) {
      if (messageQueue.isEmpty) break;
      if (DateTime.now().difference(messagesProcessStartTime).inMilliseconds >
          8) break;

      final currentMessage = popMessage();
      final messageProcessTimeStart = DateTime.now();

      for (final system in messageSystems) {
        if (system(this, currentMessage)) break;
      }

      // Debug code for development
      if (kDebugMode) {
        final messageExecutionTime =
            DateTime.now().difference(messageProcessTimeStart);
        if (messageExecutionTime.inMilliseconds > 2) {
          print(
              '(Warning) Message ${currentMessage.runtimeType} took too long (${messageExecutionTime.inMilliseconds} ms) to process');
        }
      }
    }
  }
}
