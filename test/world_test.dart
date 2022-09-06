import 'dart:io';

import 'package:backbone/archetype.dart';
import 'package:backbone/builders.dart';
import 'package:backbone/message.dart';
import 'package:backbone/node.dart';
import 'package:flutter_test/flutter_test.dart';

import 'node_test.dart';

class WorldTestMessage extends AMessage {
  WorldTestMessage(this.value);
  final int value;
}

class ExampleResource {}

class ExampleResource2 {}

class SecondTestNode extends ANode {}

void main() {
  group('World', () {
    test('simple builder', () {
      var world = WorldBuilder()
          .withTrait(String)
          .withTrait(int)
          .withMessageSystem((world, message) => false)
          .withResource(ExampleResource, ExampleResource())
          .withSystem((world) {})
          .withPlugin((builder) {
        builder.withResource(ExampleResource2, ExampleResource2());
      }).build();
      expect(world.registeredTraits.length, 2);
      expect(world.registeredTraits.contains(String), true);
      expect(world.registeredTraits.contains(int), true);
      expect(world.archetypeBuckets.length, 3);
      expect(world.archetypeBuckets.keys.toList().contains(Archetype([String])),
          true);
      expect(world.archetypeBuckets.keys.toList().contains(Archetype([int])),
          true);
      expect(
          world.archetypeBuckets.keys
              .toList()
              .contains(Archetype([String, int])),
          true);
      expect(world.messageSystems.length, 1);
      expect(world.resources.length, 4); //2 are added by default
      expect(world.systems.length, 1);
    });
    test('simple system', () {
      var success = false;
      var world = WorldBuilder().withSystem((world) => success = true).build();
      world.update(0.0);
      expect(success, true);
    });

    test('get unique ids', () {
      var world = WorldBuilder().build();
      var a = world.getNextUniqueId();
      var b = world.getNextUniqueId();
      expect(a != b, true);
    });

    test('remove nodes from world', () {
      var world = WorldBuilder().build();
      final node = TestNode();
      node.world = world;
      node.isBackboneMounted = true;
      world.registerNode(node);
      expect(world.nodesByType.length, 1);
      expect(() => world.removeNode<TestNode>(node),
          isNot(throwsA(isA<Exception>())));
      expect(() => world.removeNode<SecondTestNode>(SecondTestNode()),
          throwsA(isA<Exception>()));
    });

    test('simple message system', () {
      var resultValue = 0;
      var world = WorldBuilder().withMessageSystem((world, message) {
        if (message is WorldTestMessage) {
          resultValue = message.value;
          return true;
        }
        return false;
      }).build();
      world.pushMessage(WorldTestMessage(1));
      world.update(0.0);
      expect(resultValue, 1);
      world.pushMessage(WorldTestMessage(1));
      expect(world.hasMessage, true);
      var topMessage = world.peekMessage();
      expect(topMessage, isA<WorldTestMessage>());
      expect((topMessage as WorldTestMessage).value, 1);
      world.pushMessageToFront(WorldTestMessage(2));
      topMessage = world.peekMessage();
      expect((topMessage as WorldTestMessage).value, 2);
      world.pushMessagesToFrontInOrder(
          [WorldTestMessage(4), WorldTestMessage(3)]);
      topMessage = world.peekMessage();
      expect((topMessage as WorldTestMessage).value, 4);
      world.update(0.0);
      expect(world.hasMessage, false);
      world.pauseMessageSystem();
      world.pushMessage(WorldTestMessage(1));
      world.update(0.0);
      expect(world.hasMessage, true);
      world.resumeMessageSystem();
      world.update(0.0);
      expect(world.hasMessage, false);
    });
    test('two message systems one matches', () {
      var resultValueOne = 0;
      var resultValueTwo = 0;
      var world = WorldBuilder().withMessageSystem((world, message) {
        if (message is WorldTestMessage) {
          resultValueOne = message.value;
          return true;
        }
        return false;
      }).withMessageSystem((world, message) {
        if (message is WorldTestMessage) {
          resultValueTwo = message.value;
          return true;
        }
        return false;
      }).build();
      world.pushMessage(WorldTestMessage(1));
      world.update(0.0);
      expect(resultValueOne, 1);
      expect(resultValueTwo, 0);
    });
    test('two message systems both match', () {
      var resultValueOne = 0;
      var resultValueTwo = 0;
      var world = WorldBuilder().withMessageSystem((world, message) {
        if (message is WorldTestMessage) {
          resultValueOne = message.value;
        }
        return false;
      }).withMessageSystem((world, message) {
        if (message is WorldTestMessage) {
          resultValueTwo = message.value;
          return true;
        }
        return false;
      }).build();
      world.pushMessage(WorldTestMessage(1));
      world.update(0.0);
      expect(resultValueOne, 1);
      expect(resultValueTwo, 1);
    });
    test('message only processed once', () {
      var resultValue = 0;
      var world = WorldBuilder().withMessageSystem((world, message) {
        if (message is WorldTestMessage) {
          if (message.value == 1) {
            resultValue += message.value;
            return true;
          } else if (message.value == 5) {
            //This will tirgger a slow message warning
            sleep(const Duration(milliseconds: 5));
            return true;
          }
        }
        return false;
      }).build();
      world.pushMessage(WorldTestMessage(1));
      world.update(0.0);
      world.update(0.0);
      expect(resultValue, 1);
      var slowMessageFound = false;
      world.slowMessageDebugCallback = ((slowMessage) {
        slowMessageFound = true;
      });
      world.pushMessage(WorldTestMessage(5));
      world.update(0.0);
      expect(resultValue, 1);
      expect(slowMessageFound, true);
    });
  });
}
