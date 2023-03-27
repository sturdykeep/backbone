import 'package:backbone/builders.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/system.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_game.dart';

void testSystem(Realm<TestGame> realm) {}

void main() {
  group('System', () {
    var emptySystemRun = false;
    void emptySystem(Realm<TestGame> realm) {
      emptySystemRun = true;
    }

    var systemIntegerRun = false;
    double systemInteger(Realm<TestGame> realm) {
      systemIntegerRun = true;
      return 1.0;
    }

    var systemMultiplyTwoRun = false;
    double systemMultiplyTwo(Realm<TestGame> realm) {
      systemMultiplyTwoRun = true;
      var value = realm.checkOrRunSystem(systemInteger);
      return value * 2;
    }

    test('get system name works', () {
      expect(getSystemName(testSystem), 'testSystem');
    });
    test('run system without result', () {
      emptySystemRun = false;
      var realm = RealmBuilder<TestGame>().withSystem(emptySystem).build();
      expect(realm.systems.length, 1);
      expect(realm.systemResults.length, 0);
      realm.update(0.0);
      expect(realm.systemResults.keys.length, 1);
      expect(realm.systemResults[emptySystem], null);
      expect(emptySystemRun, true);
    });
    test('run system with result', () {
      systemIntegerRun = false;
      var realm = RealmBuilder<TestGame>().withSystem(systemInteger).build();
      expect(realm.systems.length, 1);
      expect(realm.systemResults.length, 0);
      realm.update(0.0);
      expect(realm.systemResults.keys.length, 1);
      expect(realm.systemResults[systemInteger], 1.0);
      expect(systemIntegerRun, true);
    });
    test('run system with result and dependency', () {
      systemIntegerRun = false;
      systemMultiplyTwoRun = false;
      var realm = RealmBuilder<TestGame>()
          .withSystem(systemInteger)
          .withSystem(systemMultiplyTwo)
          .build();
      expect(realm.systems.length, 2);
      expect(realm.systemResults.length, 0);
      realm.update(0.0);
      expect(realm.systemResults.keys.length, 2);
      expect(realm.systemResults[systemInteger], 1.0);
      expect(realm.systemResults[systemMultiplyTwo], 2.0);
      expect(systemIntegerRun, true);
      expect(systemMultiplyTwoRun, true);
    });
    test('run system with result and dependency in different order', () {
      systemIntegerRun = false;
      systemMultiplyTwoRun = false;
      var realm = RealmBuilder<TestGame>()
          .withSystem(systemMultiplyTwo)
          .withSystem(systemInteger)
          .build();
      expect(realm.systems.length, 2);
      expect(realm.systemResults.length, 0);
      realm.update(0.0);
      expect(realm.systemResults.keys.length, 2);
      expect(realm.systemResults[systemInteger], 1.0);
      expect(realm.systemResults[systemMultiplyTwo], 2.0);
      expect(systemIntegerRun, true);
      expect(systemMultiplyTwoRun, true);
    });
    test('systems are run next frame', () {
      systemIntegerRun = false;
      systemMultiplyTwoRun = false;
      var realm = RealmBuilder<TestGame>()
          .withSystem(systemMultiplyTwo)
          .withSystem(systemInteger)
          .build();

      expect(realm.systems.length, 2);
      expect(realm.systemResults.length, 0);
      realm.update(0.0);
      expect(realm.systemResults.keys.length, 2);
      expect(realm.systemResults[systemInteger], 1.0);
      expect(realm.systemResults[systemMultiplyTwo], 2.0);
      expect(systemIntegerRun, true);
      expect(systemMultiplyTwoRun, true);

      systemIntegerRun = false;
      systemMultiplyTwoRun = false;
      realm.update(0.0);
      expect(realm.systemResults.keys.length, 2);
      expect(realm.systemResults[systemInteger], 1.0);
      expect(realm.systemResults[systemMultiplyTwo], 2.0);
      expect(systemIntegerRun, true);
      expect(systemMultiplyTwoRun, true);
    });
    test('system is not run second time same frame', () {
      systemIntegerRun = false;
      systemMultiplyTwoRun = false;
      var realm = RealmBuilder<TestGame>()
          .withSystem(systemMultiplyTwo)
          .withSystem(systemInteger)
          .build();

      expect(realm.systems.length, 2);
      expect(realm.systemResults.length, 0);
      realm.update(0.0);
      expect(realm.systemResults.keys.length, 2);
      expect(realm.systemResults[systemInteger], 1.0);
      expect(realm.systemResults[systemMultiplyTwo], 2.0);
      expect(systemIntegerRun, true);
      expect(systemMultiplyTwoRun, true);

      systemIntegerRun = false;
      systemMultiplyTwoRun = false;
      realm.checkOrRunSystem(systemInteger);
      realm.checkOrRunSystem(systemMultiplyTwo);
      expect(systemIntegerRun, false);
      expect(systemMultiplyTwoRun, false);
    });
  });
}
