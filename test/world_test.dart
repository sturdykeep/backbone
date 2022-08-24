import 'package:backbone/archetype.dart';
import 'package:backbone/builders.dart';
import 'package:backbone/message.dart';
import 'package:flutter_test/flutter_test.dart';

class WorldTestMessage extends AMessage {
  WorldTestMessage(this.value);
  final int value;
}

void main() {
  group('World', () {
    test('simple builder', () {
      var world = WorldBuilder().withTrait(String).withTrait(int).build();
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
    });
    test('simple system', () {
      var success = false;
      var world = WorldBuilder().withSystem((world) => success = true).build();
      world.update(0.0);
      expect(success, true);
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
          resultValue += message.value;
          return true;
        }
        return false;
      }).build();
      world.pushMessage(WorldTestMessage(1));
      world.update(0.0);
      world.update(0.0);
      expect(resultValue, 1);
    });
  });
}
