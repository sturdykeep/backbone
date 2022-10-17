import 'dart:collection';

import 'package:backbone/archetype.dart';
import 'package:backbone/iterable.dart';
import 'package:backbone/prelude/input/mod.dart';
import 'package:backbone/prelude/time.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/message.dart';
import 'package:backbone/node.dart';
import 'package:backbone/system.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

typedef SlowMessageDebugCallback = void Function(AMessage slowMessage);

// Notes about the Flame input system:
// * TapDown is always first before LongTapDown
// * TapDown and TapCancel are always before DragStart
// * TapDown and DragStart have different pointerIds, but same positions
// * While drag is happening, hover events are not sent
// * Hover events use a device identifier, that can be reused

// So, how do we track things?
// 1. When tap down happens, we search for a hover with the same position and update it as a tapdown, otherwise create a new one
// 2. LongTapDown just updates the state of the pointer with the same pointerId
// 3. DragStart searches for pointer with cancelled state and exact same position, then updates it

// Longest lifecycle of a pointer looks like this:
// HoverEnter -> Hover -> TapDown -> TapCancel -> LongTapDown -> DragStart -> DragUpdate -> DragEnd

/// A mixin that allows you to add a SINGLE [Realm] to your [FlameGame].
/// It automatically hooks up the input events to the [Realm].
mixin HasRealm
    on HasTappableComponents, HasDraggableComponents, KeyboardEvents {
  late Realm realm;
  bool realmReady = false;

  @override
  void onTapDown(TapDownEvent event) {
    if (realmReady) {
      realm.getResource<Input>().onTapDown(event);
    }

    super.onTapDown(event);
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    if (realmReady) {
      realm.getResource<Input>().onLongTapDown(event);
    }
    super.onLongTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (realmReady) {
      realm.getResource<Input>().onTapUp(event);
    }
    super.onTapUp(event);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (realmReady) {
      realm.getResource<Input>().onTapCancel(event);
    }
    super.onTapCancel(event);
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (realmReady) {
      realm.getResource<Input>().onDragStart(event);
    }
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (realmReady) {
      realm.getResource<Input>().onDragUpdate(event);
    }
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (realmReady) {
      realm.getResource<Input>().onDragEnd(event);
    }
    super.onDragEnd(event);
  }

  @override
  KeyEventResult onKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (realmReady) {
      realm.getResource<Input>().onKeyEvent(event, keysPressed);
    }
    super.onKeyEvent(event, keysPressed);
    return KeyEventResult.handled;
  }
}

/// Realm is the main entry point for all backbone systems
/// You can have multiple realm in your game
class Realm extends Component with HasGameRef {
  int nextUniqueId = 0;

  /// Get a unique id for this wolrd instance
  /// ID's are only unqiue by realm
  int getNextUniqueId() => nextUniqueId++;

  /// All type of trais registered in this Realm
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

  bool logPerformanceData = false;

  /// Create a new Realm and provide the traids, ???, systems, messages and resources
  Realm(this.registeredTraits, this.archetypeBuckets, this.systems,
      this.messageSystems, this.resources) {
    addResource(Time());
    addResource(Input());
  }

  /// Used for debugging
  SlowMessageDebugCallback? slowMessageDebugCallback;

  // Message system
  bool messageSystemPaused = false;
  final Queue<AMessage> messageQueue = Queue();

  /// Push a new message to the end of the queue
  void pushMessage(AMessage message) {
    messageQueue.add(message);
  }

  /// Push a message to the first pposition in the queue
  void pushMessageToFront(AMessage message) {
    messageQueue.addFirst(message);
  }

  /// Push multiple messages to the queue
  void pushMessagesToFrontInOrder(Iterable<AMessage> messages) {
    // messages: [a, b, c]
    // messageQueue: [c, b, a] (reverse, but execute in order)
    var messagesReverse = messages.toList().reversed;
    for (var message in messagesReverse) {
      messageQueue.addFirst(message);
    }
  }

  /// Get the first message in the queue without removing it
  AMessage peekMessage() {
    return messageQueue.first;
  }

  /// Get the first message in the queue and remove it
  AMessage popMessage() {
    return messageQueue.removeFirst();
  }

  /// Is there any message in the queue
  bool get hasMessage => messageQueue.isNotEmpty;

  /// Pause the message system
  void pauseMessageSystem() {
    messageSystemPaused = true;
  }

  /// Resum the message system
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
    for (final archetype in archetypeBuckets.keys) {
      if (filter.matches(archetype)) {
        final nodes = archetypeBuckets[archetype]!;
        if (onlyLoaded) {
          result.add(nodes.where((node) => node.isLoaded).toList());
        } else {
          result.add(nodes);
        }
      }
    }
    return MultiIterableView(result);
  }

  @override
  void onMount() {
    if (logPerformanceData) {
      logPerformance('Running', 'true');
    }
  }

  @override
  void renderTree(Canvas canvas) {
    final renderStart = DateTime.now();
    super.renderTree(canvas);
    logPerformance('Render',
        DateTime.now().difference(renderStart).inMilliseconds.toString());
  }

  // Update Loop
  /// Update all details of the realm, called by Flame
  @override
  void update(double dt) {
    final updateStart = DateTime.now();
    // Update the time
    getResource<Time>().delta = dt;

    // Update all the systems
    for (final system in systems) {
      final systemsStartTime = DateTime.now();
      system(this);
      if (logPerformanceData) {
        final systemExecutionTime = DateTime.now().difference(systemsStartTime);
        logPerformance('Systems',
            '${system.toString()},${systemExecutionTime.inMicroseconds}');
      }
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
      if (logPerformanceData) {
        final messageExecutionTime =
            DateTime.now().difference(messageProcessTimeStart);
        if (messageExecutionTime.inMilliseconds > 2) {
          debugPrint(
              '(Warning) Message ${currentMessage.runtimeType} took too long (${messageExecutionTime.inMilliseconds} ms) to process');
          slowMessageDebugCallback?.call(currentMessage);
        }
      }
    }

    // Clear the inputs
    final input = getResource<Input>();
    input.clear();
    logPerformance('Update',
        DateTime.now().difference(updateStart).inMilliseconds.toString());
  }

  void logPerformance(String category, String value) {
    debugPrint('prefmon:$category->$value:prefmon');
  }
}
