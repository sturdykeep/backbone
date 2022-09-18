import 'package:backbone/builders.dart';
import 'package:backbone/component_node.dart';
import 'package:backbone/iterable.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/node.dart';
import 'package:flutter_test/flutter_test.dart';

class TestNode extends ComponentNode {
  TestNode() : super();
}

class TestComponentA extends ATrait {}

class TestComponentB extends ATrait {}

class TestComponentC extends ATrait {}

class TestComponentD extends ATrait {}

void main() {
  group('Query', () {
    test('register [a] query [a] from [a]', () {
      var realm = RealmBuilder().withTrait(TestComponentA).build();
      var node = TestNode();
      node.isBackboneMounted = true;
      node.realm = realm;
      realm.registerNode(node);
      node.addTrait(TestComponentA());
      var result = realm.query(Has([TestComponentA]));
      expect(result.length, 1);
      expect(result.first, node);
      expect(result.first.tryGet<TestComponentA>(), node.traits.first);
    });
    test('register [a] query [b] from [a]', () {
      var realm = RealmBuilder().withTrait(TestComponentA).build();
      var node = TestNode();
      node.isBackboneMounted = true;
      node.realm = realm;
      realm.registerNode(node);
      node.addTrait(TestComponentA());
      var result = realm.query(Has([TestComponentB]));
      expect(result.length, 0);
    });
    test('register [a] query [a,b] from [a]', () {
      var realm = RealmBuilder().withTrait(TestComponentA).build();
      var node = TestNode();
      node.isBackboneMounted = true;
      node.realm = realm;
      realm.registerNode(node);
      node.addTrait(TestComponentA());
      var result = realm.query(Has([TestComponentA, TestComponentB]));
      expect(result.length, 0);
    });
    test('register [a, b, c] query [a, b] from [a, b, c]', () {
      var realm = RealmBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      node.isBackboneMounted = true;
      node.realm = realm;
      realm.registerNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentB());
      node.addTrait(TestComponentC());
      var result = realm.query(Has([TestComponentA, TestComponentB]));
      expect(result.length, 1);
      expect(result.first, node);
      expect(result.first.tryGet<TestComponentA>(), node.traits.first);
      expect(result.first.tryGet<TestComponentB>(), node.traits[1]);
    });
    test('register [a, b, c] query [a] or [b] without [c] from [a, b, c]', () {
      var realm = RealmBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      node.isBackboneMounted = true;
      node.realm = realm;
      realm.registerNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentB());
      node.addTrait(TestComponentC());
      var result = realm.query(And([
        Or([
          Has([TestComponentA]),
          Has([TestComponentB])
        ]),
        Without([TestComponentC])
      ]));
      expect(result.length, 0);
    });
    test('register [a, b, c] query [a] or [b] without [c] from [a, b]', () {
      var realm = RealmBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      node.isBackboneMounted = true;
      node.realm = realm;
      realm.registerNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentB());
      var result = realm.query(And([
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
      var realm = RealmBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      node.isBackboneMounted = true;
      node.realm = realm;
      realm.registerNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentC());
      var result = realm.query(And([
        Or([
          Has([TestComponentA]),
          Has([TestComponentB])
        ]),
        Without([TestComponentC])
      ]));
      expect(result.length, 0);
    });
    test('register [a, b, c] query [a] or [b] without [c] from [b, c]', () {
      var realm = RealmBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      node.isBackboneMounted = true;
      node.realm = realm;
      realm.registerNode(node);
      node.addTrait(TestComponentB());
      node.addTrait(TestComponentC());
      var result = realm.query(And([
        Or([
          Has([TestComponentA]),
          Has([TestComponentB])
        ]),
        Without([TestComponentC])
      ]));
      expect(result.length, 0);
    });
    test('cannot query [a] from [a, b, c] after it was removed', () {
      var realm = RealmBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      node.isBackboneMounted = true;
      node.realm = realm;
      realm.registerNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentB());
      node.addTrait(TestComponentC());
      var result = realm.query(Has([TestComponentA]));
      expect(result.length, 1);
      realm.removeNode(node);
      result = realm.query(Has([TestComponentA]));
      expect(result.length, 0);
    });
    test('cannot query [a] from [a, b, c] after [a] is removed', () {
      var realm = RealmBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      node.isBackboneMounted = true;
      node.realm = realm;
      realm.registerNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentB());
      node.addTrait(TestComponentC());
      var result = realm.query(Has([TestComponentA]));
      expect(result.length, 1);
      node.removeTrait<TestComponentA>();
      result = realm.query(Has([TestComponentA]));
      expect(result.length, 0);
    });
    test('can query [a] from [a, b, c] after [a] is removed and added back',
        () {
      var realm = RealmBuilder()
          .withTrait(TestComponentA)
          .withTrait(TestComponentB)
          .withTrait(TestComponentC)
          .build();
      var node = TestNode();
      node.isBackboneMounted = true;
      node.realm = realm;
      realm.registerNode(node);
      node.addTrait(TestComponentA());
      node.addTrait(TestComponentB());
      node.addTrait(TestComponentC());
      var result = realm.query(Has([TestComponentA]));
      expect(result.length, 1);
      node.removeTrait<TestComponentA>();
      result = realm.query(Has([TestComponentA]));
      expect(result.length, 0);
      node.addTrait(TestComponentA());
      result = realm.query(Has([TestComponentA]));
      expect(result.length, 1);
      final multiIterator =
          (result.iterator as MultiIterableViewIterator<ANode>);
      expect(multiIterator.totalLength, 1);
      result = realm.query(HasAny([TestComponentA, TestComponentC]));
      expect(result.length, 1);
    });
  });
}
