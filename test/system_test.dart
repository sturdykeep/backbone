import 'package:backbone/builders.dart';
import 'package:backbone/realm.dart';
import 'package:backbone/system.dart';
import 'package:flutter_test/flutter_test.dart';

void testSystem(Realm realm) {}

void main() {
  group('System', () {
    var emptySystemRun = false;
    void emptySystem(Realm realm) {
      emptySystemRun = true;
    }

    var systemIntegerRun = false;
    double systemInteger(Realm realm) {
      systemIntegerRun = true;
      return 1.0;
    }

    var systemMultiplyTwoRun = false;
    double systemMultiplyTwo(Realm realm) {
      systemMultiplyTwoRun = true;
      var value = realm.runDependency(systemInteger);
      return value * 2;
    }

    test('get system name works', () {
      expect(getSystemName(testSystem), 'testSystem');
    });
    test('run system without result', () {
      emptySystemRun = false;
      var realm = RealmBuilder().withSystem(emptySystem).build();
      expect(realm.systems.length, 1);
      expect(realm.systemResults.length, 0);
      realm.update(0.0);
      expect(realm.systemResults.keys.length, 1);
      expect(realm.systemResults[emptySystem], null);
      expect(emptySystemRun, true);
    });
    test('run system with result', () {
      systemIntegerRun = false;
      var realm = RealmBuilder().withSystem(systemInteger).build();
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
      var realm = RealmBuilder()
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
      var realm = RealmBuilder()
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
      var realm = RealmBuilder()
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
      var realm = RealmBuilder()
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
      realm.runDependency(systemInteger);
      realm.runDependency(systemMultiplyTwo);
      expect(systemIntegerRun, false);
      expect(systemMultiplyTwoRun, false);
    });
  });
}
