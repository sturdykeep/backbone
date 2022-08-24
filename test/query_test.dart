import 'package:backbone/builders.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/node.dart';
import 'package:flutter_test/flutter_test.dart';

class TestNode extends ANode {
  TestNode() : super();
}

class TestComponentA extends ATrait {}

class TestComponentB extends ATrait {}

class TestComponentC extends ATrait {}

class TestComponentD extends ATrait {}

void main() {
  group('Query', () {
    test('register [a] query [a] from [a]', () {
      var world = WorldBuilder().withTrait(TestComponentA).build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(TestComponentA());
      var result = world.query(Has([TestComponentA]));
      expect(result.length, 1);
      expect(result.first, node);
      expect(result.first.tryGet<TestComponentA>(), node.traits.first);
    });
    test('register [a] query [b] from [a]', () {
      var world = WorldBuilder().withTrait(TestComponentA).build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(TestComponentA());
      var result = world.query(Has([TestComponentB]));
      expect(result.length, 0);
    });
    test('register [a] query [a,b] from [a]', () {
      var world = WorldBuilder().withTrait(TestComponentA).build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(TestComponentA());
      var result = world.query(Has([TestComponentA, TestComponentB]));
      expect(result.length, 0);
    });
    test('register [a, b, c] query [a, b] from [a, b, c]', () {
      var world = WorldBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentB());
      node.addTrait(TestComponentC());
      var result = world.query(Has([TestComponentA, TestComponentB]));
      expect(result.length, 1);
      expect(result.first, node);
      expect(result.first.tryGet<TestComponentA>(), node.traits.first);
      expect(result.first.tryGet<TestComponentB>(), node.traits[1]);
    });
    test('register [a, b, c] query [a] or [b] without [c] from [a, b, c]', () {
      var world = WorldBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentB());
      node.addTrait(TestComponentC());
      var result = world.query(And([
        Or([
          Has([TestComponentA]),
          Has([TestComponentB])
        ]),
        Without([TestComponentC])
      ]));
      expect(result.length, 0);
    });
    test('register [a, b, c] query [a] or [b] without [c] from [a, b]', () {
      var world = WorldBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentB());
      var result = world.query(And([
        Or([
          Has([TestComponentA]),
          Has([TestComponentB])
        ]),
        Without([TestComponentC])
      ]));
      expect(result.length, 1);
      expect(result.first, node);
      expect(result.first.tryGet<TestComponentA>(), node.traits.first);
      expect(result.first.tryGet<TestComponentB>(), node.traits.last);
    });
    test('register [a, b, c] query [a] or [b] without [c] from [a, c]', () {
      var world = WorldBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentC());
      var result = world.query(And([
        Or([
          Has([TestComponentA]),
          Has([TestComponentB])
        ]),
        Without([TestComponentC])
      ]));
      expect(result.length, 0);
    });
    test('register [a, b, c] query [a] or [b] without [c] from [b, c]', () {
      var world = WorldBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(TestComponentB());
      node.addTrait(TestComponentC());
      var result = world.query(And([
        Or([
          Has([TestComponentA]),
          Has([TestComponentB])
        ]),
        Without([TestComponentC])
      ]));
      expect(result.length, 0);
    });
    test('cannot query [a] from [a, b, c] after it was removed', () {
      var world = WorldBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentB());
      node.addTrait(TestComponentC());
      var result = world.query(Has([TestComponentA]));
      expect(result.length, 1);
      world.removeNode(node);
      result = world.query(Has([TestComponentA]));
      expect(result.length, 0);
    });
    test('cannot query [a] from [a, b, c] after [a] is removed', () {
      var world = WorldBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentB());
      node.addTrait(TestComponentC());
      var result = world.query(Has([TestComponentA]));
      expect(result.length, 1);
      node.removeTrait<TestComponentA>();
      result = world.query(Has([TestComponentA]));
      expect(result.length, 0);
    });
    test('can query [a] from [a, b, c] after [a] is removed and added back',
        () {
      var world = WorldBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentB());
      node.addTrait(TestComponentC());
      var result = world.query(Has([TestComponentA]));
      expect(result.length, 1);
      node.removeTrait<TestComponentA>();
      result = world.query(Has([TestComponentA]));
      expect(result.length, 0);
      node.addTrait(TestComponentA());
      result = world.query(Has([TestComponentA]));
      expect(result.length, 1);
    });
  });
}
