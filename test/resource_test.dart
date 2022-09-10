import 'package:backbone/builders.dart';
import 'package:flutter_test/flutter_test.dart';

class TestResource {
  final int value;
  TestResource(this.value);
}

void main() {
  group('Resource', () {
    test('can get resource', () {
      var realm = RealmBuilder().build();
      var resource = TestResource(1);
      realm.addResource(resource);
      expect(realm.tryGetResource<TestResource>(), resource);
    });
    test('cannot get resource if not added', () {
      var realm = RealmBuilder().build();
      expect(realm.tryGetResource<TestResource>(), null);
    });
    test('doesn\' get resource of wrong type', () {
      var realm = RealmBuilder().build();
      var resource = TestResource(1);
      realm.addResource(resource);
      expect(realm.tryGetResource<int>(), null);
    });
    test('resources is removed', () {
      var realm = RealmBuilder().build();
      var resource = TestResource(1);
      realm.addResource(resource);
      var removedResource = realm.removeResource<TestResource>();
      expect(realm.tryGetResource<TestResource>(), null);
      expect(removedResource, resource);
    });
    test('can access resource from a system', () {
      var resultValue = 0;
      var realm = RealmBuilder().withSystem((realm) {
        resultValue = realm.getResource<TestResource>().value;
      }).build();
      var resource = TestResource(1);
      realm.addResource(resource);
      realm.update(0.0);
      expect(resultValue, 1);
    });
  });
}
