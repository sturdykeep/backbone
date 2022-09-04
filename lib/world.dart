import 'dart:collection';

import 'package:backbone/archetype.dart';
import 'package:backbone/iterable.dart';
import 'package:backbone/prelude/input.dart';
import 'package:backbone/prelude/time.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/message.dart';
import 'package:backbone/node.dart';
import 'package:backbone/system.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// World is the main entry point for all backbone systems
/// You can have multiple worlds in your game
class World extends Component with HasGameRef {
  int _nextUniqueId = 0;

  /// Get a unique id for this wolrd instance
  /// ID's are only unqiue by world
  int getNextUniqueId() => _nextUniqueId++;

  /// All type of trais registered in this world
  late final HashSet<Type> registeredTraits;

  /// ???
  late final HashMap<Archetype, List<ANode>> archetypeBuckets;

  /// List of all registered systems
  late final List<System> systems;

  /// List of all messages systems
  late final List<MessageSystem> messageSystems;

  /// Map of types with the connected resource
  late final HashMap<Type, dynamic> resources;

  /// ???
  final HashMap<Type, HashSet<ANode>> nodesByType = HashMap();

  /// Create a new world and provide the traids, ???, systems, messages and resources
  World(this.registeredTraits, this.archetypeBuckets, this.systems,
      this.messageSystems, this.resources) {
    addResource(Time());
    addResource(Input());
  }

  // Message system
  bool _messageSystemPaused = false;
  final Queue<AMessage> _messageQueue = Queue();

  /// Push a new message to the end of the queue
  void pushMessage(AMessage message) {
    _messageQueue.add(message);
  }

  /// Push a message to the first pposition in the queue
  void pushMessageToFront(AMessage message) {
    _messageQueue.addFirst(message);
  }

  /// Push multiple messages to the queue
  void pushMessagesToFrontInOrder(Iterable<AMessage> messages) {
    // messages: [a, b, c]
    // messageQueue: [c, b, a] (reverse, but execute in order)
    var messagesReverse = messages.toList().reversed;
    for (var message in messagesReverse) {
      _messageQueue.addFirst(message);
    }
  }

  /// Get the first message in the queue without removing it
  AMessage peekMessage() {
    return _messageQueue.first;
  }

  /// Get the first message in the queue and remove it
  AMessage popMessage() {
    return _messageQueue.removeFirst();
  }

  /// Is there any message in the queue
  bool get hasMessage => _messageQueue.isNotEmpty;

  /// Pause the message system
  void pauseMessageSystem() {
    _messageSystemPaused = true;
  }

  /// Resum the message system
  void resumeMessageSystem() {
    _messageSystemPaused = false;
  }

  // Add a new resource to the world
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

  // Traits and nodes

  /// Remove a node from a bucket
  void removeNodeFromBuckets(ANode node) {
    // Remove the trait from the existing archetype storage
    final currentBucket = node.bucket;
    if (currentBucket != null) {
      final currentBucketList = archetypeBuckets[currentBucket]!;
      currentBucketList.remove(node);
      node.bucket = null;
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
    }
  }

  /// Add a node to a world
  void registerNode<N extends ANode>(N node) {
    assert(node.isBackboneMounted == true,
        'Add the node to the world via add or addAll. Do not call registerNode');
    final type = node.runtimeType;
    if (!nodesByType.containsKey(type)) {
      nodesByType[type] = HashSet();
    }
    nodesByType[type]!.add(node);
    putNodeIntoBucket(node);
  }

  /// Remove an existing node from the world
  void removeNode<N extends ANode>(N node) {
    final type = node.runtimeType;
    if (!nodesByType.containsKey(type)) {
      throw Exception('No nodes of type $type were ever added');
    }
    nodesByType[type]!.remove(node);
    node.world = this;

    removeNodeFromBuckets(node);
  }

  /// Addd a trait to an existing node
  void addTraitToNode<C extends ATrait, N extends ANode>(C trait, N node) {
    if (node.world != this) {
      throw Exception(
          'Node $node is not in this world. It was added to another world');
    }

    removeNodeFromBuckets(node);
    putNodeIntoBucket(node);
  }

  /// Remove a trait from an existing node
  void removeTraitFromNode<C extends ATrait, N extends ANode>(C trait, N node) {
    if (node.world != this) {
      throw Exception(
          'Node $node is not in this world. It was added to another world');
    }

    removeNodeFromBuckets(node);
    putNodeIntoBucket(node);
  }

  // Query
  /// Querry the world for a list of nodes
  MultiIterableView<ANode> query<N extends ANode, F extends AFilter>(F filter,
      {bool onlyLoaded = false}) {
    List<List<ANode>> result = [];
    for (final archetype in archetypeBuckets.keys) {
      final nodes = archetypeBuckets[archetype]!;
      if (filter.matches(archetype)) {
        if (onlyLoaded) {
          result.add(nodes.where((node) => node.isLoaded).toList());
        } else {
          result.add(nodes);
        }
      }
    }
    return MultiIterableView(result);
  }

  // Input System
  /// Should be called by the game in the `onKeyEvent` for the world's input system
  /// to become aware of keyboard events.
  void onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final input = getResource<Input>();
    input.keysPressed = keysPressed;
  }

  /// Should be called by the game in the `onMouseMove` for the world's input system
  /// to become aware of mouse movement.
  void onMouseMove(PointerHoverInfo info) {
    final input = getResource<Input>();
    input.pointerMove = info;
    input.mousePosition = info.eventPosition.game;
  }

  /// Should be called by the game in the `onTapDown` for the world's input system
  /// to become aware of taps and clicks.
  void onTapDown(int pointerId, TapDownInfo info) {
    final input = getResource<Input>();
    input.taps.putIfAbsent(pointerId, () => info);
    input.taps[pointerId] = info;
  }

  /// Should be called by the game in the `onTapUp` for the world's input system
  /// to become aware of taps and clicks.
  void onTapUp(int pointerId, TapUpInfo info) {
    final input = getResource<Input>();
    input.tapUps.add(pointerId);
    input.taps[pointerId]!.handled = info.handled;
  }

  /// Should be called by the game in the `onTapCancel` for the world's input system
  /// to become aware of taps and clicks.
  void onTapCancel(int pointerId) {
    final input = getResource<Input>();
    input.tapCancels.add(pointerId);
  }

  // Update Loop
  /// Update all details of the world, called by Flame
  @override
  void update(double dt) {
    // Update the time
    getResource<Time>().delta = dt;

    // Update all the systems
    for (final system in systems) {
      system(this);
    }

    // Update the input system
    final input = getResource<Input>();
    input.keysPressed = {};
    input.pointerMove = null;
    input.taps = input.taps
      ..removeWhere((pointerId, _) => input.tapUps.contains(pointerId))
      ..removeWhere((pointerId, _) => input.tapCancels.contains(pointerId));
    input.tapUps = HashSet();
    input.tapCancels = HashSet();

    // Proccess the message queue
    // ...and try to keep at least 60 fps
    final messagesProcessStartTime = DateTime.now();
    while (_messageSystemPaused == false) {
      if (_messageQueue.isEmpty) break;
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
