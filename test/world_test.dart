import 'dart:io';

import 'package:backbone/archetype.dart';
import 'package:backbone/builders.dart';
import 'package:backbone/message.dart';
import 'package:backbone/node.dart';
import 'package:flutter_test/flutter_test.dart';

import 'node_test.dart';

class RealmTestMessage extends AMessage {
  RealmTestMessage(this.value);
  final int value;
}

class ExampleResource {}

class ExampleResource2 {}

class SecondTestNode extends ANode {}

void main() {
  group('Realm', () {
    test('simple builder', () {
      var realm = RealmBuilder()
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
      var realm = RealmBuilder().withSystem((realm) => success = true).build();
      realm.update(0.0);
      expect(success, true);
    });

    test('get unique ids', () {
      var realm = RealmBuilder().build();
      var a = realm.getNextUniqueId();
      var b = realm.getNextUniqueId();
      expect(a != b, true);
    });

    test('remove nodes from realm', () {
      var realm = RealmBuilder().build();
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
      var realm = RealmBuilder().withMessageSystem((realm, message) {
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
      var realm = RealmBuilder().withMessageSystem((realm, message) {
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
      var realm = RealmBuilder().withMessageSystem((realm, message) {
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
    test('message only processed once', () {
      var resultValue = 0;
      var realm = RealmBuilder().withMessageSystem((realm, message) {
        if (message is RealmTestMessage) {
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
      realm.pushMessage(RealmTestMessage(1));
      realm.update(0.0);
      realm.update(0.0);
      expect(resultValue, 1);
      var slowMessageFound = false;
      realm.slowMessageDebugCallback = ((slowMessage) {
        slowMessageFound = true;
      });
      realm.pushMessage(RealmTestMessage(5));
      realm.update(0.0);
      expect(resultValue, 1);
      expect(slowMessageFound, true);
    });
  });
}
