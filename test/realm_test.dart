import 'dart:io';

import 'package:backbone/archetype.dart';
import 'package:backbone/builders.dart';
import 'package:backbone/component_node.dart';
import 'package:backbone/message.dart';
import 'package:flutter_test/flutter_test.dart';

import 'node_test.dart';
import 'test_game.dart';

class RealmTestMessage extends AMessage<int> {
  RealmTestMessage(this.value);
  final int value;
}

class VoidMessage extends AMessage<void> {}

class ExampleResource {}

class ExampleResource2 {}

class SecondTestNode extends ComponentNode<TestGame> {}

void main() {
  group('Realm', () {
    test('simple builder', () {
      var realm = RealmBuilder<TestGame>()
          .withTrait(String)
          .withTrait(int)
          .withMessageSystem((realm, message) => false)
          .withResource(ExampleResource, ExampleResource())
          .withSystem((realm) {})
          .withPlugin((builder) {
        builder.withResource(ExampleResource2, ExampleResource2());
      }).build();
      expect(realm.registeredTraits.length, 2);
      expect(realm.registeredTraits.contains(String), true);
      expect(realm.registeredTraits.contains(int), true);
      expect(realm.archetypeBuckets.length, 3);
      expect(realm.archetypeBuckets.keys.toList().contains(Archetype([String])),
          true);
      expect(realm.archetypeBuckets.keys.toList().contains(Archetype([int])),
          true);
      expect(
          realm.archetypeBuckets.keys
              .toList()
              .contains(Archetype([String, int])),
          true);
      expect(realm.messageSystems.length, 1);
      expect(realm.resources.length, 4); //2 are added by default
      expect(realm.systems.length, 1);
    });
    test('simple system', () {
      var success = false;
      var realm = RealmBuilder<TestGame>()
          .withSystem((realm) => success = true)
          .build();
      realm.update(0.0);
      expect(success, true);
    });

    test('get unique ids', () {
      var realm = RealmBuilder<TestGame>().build();
      var a = realm.getNextUniqueId();
      var b = realm.getNextUniqueId();
      expect(a != b, true);
    });

    test('remove nodes from realm', () {
      var realm = RealmBuilder<TestGame>().build();
      final node = TestNode();
      node.realm = realm;
      node.isBackboneMounted = true;
      realm.registerNode(node);
      expect(realm.nodesByType.length, 1);
      expect(() => realm.removeNode<TestNode>(node),
          isNot(throwsA(isA<Exception>())));
      expect(() => realm.removeNode<SecondTestNode>(SecondTestNode()),
          throwsA(isA<Exception>()));
    });

    test('simple message system', () {
      var resultValue = 0;
      var realm = RealmBuilder<TestGame>().withMessageSystem((realm, message) {
        if (message is RealmTestMessage) {
          resultValue = message.value;
          return true;
        }
        return false;
      }).build();
      realm.pushMessage(RealmTestMessage(1));
      realm.update(0.0);
      expect(resultValue, 1);
      realm.pushMessage(RealmTestMessage(1));
      expect(realm.hasMessage, true);
      var topMessage = realm.peekMessage();
      expect(topMessage, isA<RealmTestMessage>());
      expect((topMessage as RealmTestMessage).value, 1);
      realm.pushMessageToFront(RealmTestMessage(2));
      topMessage = realm.peekMessage();
      expect((topMessage as RealmTestMessage).value, 2);
      realm.pushMessagesToFrontInOrder(
          [RealmTestMessage(4), RealmTestMessage(3)]);
      topMessage = realm.peekMessage();
      expect((topMessage as RealmTestMessage).value, 4);
      realm.update(0.0);
      expect(realm.hasMessage, false);
      realm.pauseMessageSystem();
      realm.pushMessage(RealmTestMessage(1));
      realm.update(0.0);
      expect(realm.hasMessage, true);
      realm.resumeMessageSystem();
      realm.update(0.0);
      expect(realm.hasMessage, false);
    });
    test('two message systems one matches', () {
      var resultValueOne = 0;
      var resultValueTwo = 0;
      var realm = RealmBuilder<TestGame>().withMessageSystem((realm, message) {
        if (message is RealmTestMessage) {
          resultValueOne = message.value;
          return true;
        }
        return false;
      }).withMessageSystem((realm, message) {
        if (message is RealmTestMessage) {
          resultValueTwo = message.value;
          return true;
        }
        return false;
      }).build();
      realm.pushMessage(RealmTestMessage(1));
      realm.update(0.0);
      expect(resultValueOne, 1);
      expect(resultValueTwo, 0);
    });
    test('two message systems both match', () {
      var resultValueOne = 0;
      var resultValueTwo = 0;
      var realm = RealmBuilder<TestGame>().withMessageSystem((realm, message) {
        if (message is RealmTestMessage) {
          resultValueOne = message.value;
        }
        return false;
      }).withMessageSystem((realm, message) {
        if (message is RealmTestMessage) {
          resultValueTwo = message.value;
          return true;
        }
        return false;
      }).build();
      realm.pushMessage(RealmTestMessage(1));
      realm.update(0.0);
      expect(resultValueOne, 1);
      expect(resultValueTwo, 1);
    });
    test('message only processed once and slow warning works', () {
      var resultValue = 0;
      var realm = RealmBuilder<TestGame>().withMessageSystem((realm, message) {
        if (message is RealmTestMessage) {
          if (message.value == 1) {
            resultValue += message.value;
            return true;
          } else {
            //This will tirgger a slow message warning
            sleep(Duration(milliseconds: message.value));
            return true;
          }
        }
        return false;
      }).build();
      realm.pushMessage(RealmTestMessage(1));
      realm.update(0.0);
      realm.update(0.0);
      expect(resultValue, 1);
      var slowMessageFound = false;
      realm.slowMessageDebugCallback = ((slowMessage) {
        slowMessageFound = true;
      });
      realm.messageSystemTimeBudget = 20;

      realm.pushMessage(RealmTestMessage(2));
      realm.update(0.0);
      expect(resultValue, 1);
      expect(slowMessageFound, false);

      realm.pushMessage(RealmTestMessage(15));
      realm.pushMessage(RealmTestMessage(15));
      realm.update(0.0);
      expect(resultValue, 1);
      expect(slowMessageFound, false);

      slowMessageFound = false;
      realm.pushMessage(RealmTestMessage(30));
      realm.update(0.0);
      expect(resultValue, 1);
      expect(slowMessageFound, true);
    });
    test('await a message', () async {
      var realm = RealmBuilder<TestGame>().withMessageSystem((realm, message) {
        if (message is RealmTestMessage) {
          return realm.resolveMessage(message, message.value);
        }
        return false;
      }).build();
      final returnedFuture = realm.pushMessage(RealmTestMessage(1));
      realm.update(0.0);
      expect(await returnedFuture, 1);
    });
    test('await multiple messages', () async {
      var realm = RealmBuilder<TestGame>().withMessageSystem((realm, message) {
        if (message is RealmTestMessage) {
          return realm.resolveMessage(message, message.value);
        }
        return false;
      }).build();
      final returnedFutureOne = realm.pushMessage(RealmTestMessage(1));
      final returnedFutureTwo = realm.pushMessage(RealmTestMessage(2));
      realm.update(0.0);
      expect(await returnedFutureOne, 1);
      expect(await returnedFutureTwo, 2);
    });
    test('void message', () async {
      var executed = false;
      var realm = RealmBuilder<TestGame>().withMessageSystem((realm, message) {
        if (message is VoidMessage) {
          executed = true;
          return true;
        }
        return false;
      }).build();
      final returnedFuture = realm.pushMessage(VoidMessage());
      realm.update(0.0);
      await returnedFuture;
      expect(executed, true);
    });
  });
}
