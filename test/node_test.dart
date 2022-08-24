import 'package:backbone/archetype.dart';
import 'package:backbone/builders.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/node.dart';
import 'package:backbone/world.dart';
import 'package:flutter_test/flutter_test.dart';

class IntComponent extends ATrait {
  final int value;
  IntComponent(this.value);
}

class TestNode extends ANode {
  TestNode() : super();
}

void main() {
  group('Node', () {
    test('basic empty node', () {
      var world = WorldBuilder().withTrait(IntComponent).build();
      var node = TestNode();
      world.addNode(node);

      expect(node.traits.length, 0);
      expect(node.traits.any((comp) => comp is IntComponent), false);
      expect(world.nodesByType[TestNode]!.length, 1);
      expect(world.archetypeBuckets[Archetype([IntComponent])]!.length, 0);
    });
    test('basic node with component', () {
      var world = WorldBuilder().withTrait(IntComponent).build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(IntComponent(1));
      expect(node.traits.length, 1);
      expect(node.traits.any((comp) => comp is IntComponent), true);
      expect(world.nodesByType[TestNode]!.length, 1);
      expect(world.archetypeBuckets[Archetype([IntComponent])]!.length, 1);
    });
    test('basic node with component and remove', () {
      var world = WorldBuilder().withTrait(IntComponent).build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(IntComponent(1));
      expect(node.traits.length, 1);
      expect(node.traits.any((comp) => comp is IntComponent), true);
      expect(world.nodesByType[TestNode]!.length, 1);
      expect(world.archetypeBuckets[Archetype([IntComponent])]!.length, 1);
      node.removeTrait<IntComponent>();
      expect(node.traits.length, 0);
      expect(node.traits.any((comp) => comp is IntComponent), false);
      expect(world.nodesByType[TestNode]!.length, 1);
      expect(world.archetypeBuckets[Archetype([IntComponent])]!.length, 0);
    });
    test('basic node add and remove', () {
      var world = WorldBuilder().withTrait(IntComponent).build();
      var node = TestNode();
      world.addNode(node);
      node.addTrait(IntComponent(1));
      expect(node.traits.length, 1);
      expect(node.traits.any((comp) => comp is IntComponent), true);
      expect(world.nodesByType[TestNode]!.length, 1);
      expect(world.archetypeBuckets[Archetype([IntComponent])]!.length, 1);
      world.removeNode(node);
      expect(node.traits.length, 1);
      expect(node.traits.any((comp) => comp is IntComponent), true);
      expect(world.nodesByType[TestNode]!.length, 0);
      expect(world.archetypeBuckets[Archetype([IntComponent])]!.length, 0);
    });
  });
}
