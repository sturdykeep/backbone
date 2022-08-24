import 'package:backbone/builders.dart';
import 'package:flutter_test/flutter_test.dart';

class TestResource {
  final int value;
  TestResource(this.value);
}

void main() {
  group('Resource', () {
    test('can get resource', () {
      var world = WorldBuilder().build();
      var resource = TestResource(1);
      world.addResource(resource);
      expect(world.tryGetResource<TestResource>(), resource);
    });
    test('cannot get resource if not added', () {
      var world = WorldBuilder().build();
      expect(world.tryGetResource<TestResource>(), null);
    });
    test('doesn\' get resource of wrong type', () {
      var world = WorldBuilder().build();
      var resource = TestResource(1);
      world.addResource(resource);
      expect(world.tryGetResource<int>(), null);
    });
    test('resources is removed', () {
      var world = WorldBuilder().build();
      var resource = TestResource(1);
      world.addResource(resource);
      var removedResource = world.removeResource<TestResource>();
      expect(world.tryGetResource<TestResource>(), null);
      expect(removedResource, resource);
    });
    test('can access resource from a system', () {
      var resultValue = 0;
      var world = WorldBuilder().withSystem((world) {
        resultValue = world.getResource<TestResource>().value;
      }).build();
      var resource = TestResource(1);
      world.addResource(resource);
      world.update(0.0);
      expect(resultValue, 1);
    });
  });
}
