import 'package:backbone/archetype.dart';
import 'package:backbone/builders.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/node.dart';
import 'package:backbone/world.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'testGame.dart';

class IntComponent extends ATrait {
  final int value;
  IntComponent(this.value);
}

class TestNode extends ANode {
  TestNode() : super();
}

void main() {
  group('Node', () {
    // Setup
    TestWidgetsFlutterBinding.ensureInitialized();
    final gameTester = FlameTester(() => TestGame());

    gameTester.testGameWidget('basic empty node', setUp: (game, _) async {
      await game.ready();
      await game.ensureAdd(WorldBuilder().withTrait(IntComponent).build());
    }, verify: (game, tester) async {
      expect(
        find.byGame<TestGame>(),
        findsOneWidget,
      );
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      world.add(node);
      game.update(0);

      expect(node.traits.length, 0);
      expect(node.traits.any((comp) => comp is IntComponent), false);
      expect(world.nodesByType[TestNode]!.length, 1);
      expect(world.archetypeBuckets[Archetype([IntComponent])]!.length, 0);
    });
    gameTester.testGameWidget('basic node with component',
        setUp: (game, _) async {
      await game.ready();
      await game.ensureAdd(WorldBuilder().withTrait(IntComponent).build());
    }, verify: (game, tester) async {
      expect(
        find.byGame<TestGame>(),
        findsOneWidget,
      );
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      world.add(node);
      game.update(0);

      node.addTrait(IntComponent(1));
      expect(node.traits.length, 1);
      expect(node.traits.any((comp) => comp is IntComponent), true);
      expect(world.nodesByType[TestNode]!.length, 1);
      expect(world.archetypeBuckets[Archetype([IntComponent])]!.length, 1);
    });
    gameTester.testGameWidget('basic node with component and remove',
        setUp: (game, _) async {
      await game.ready();
      await game.ensureAdd(WorldBuilder().withTrait(IntComponent).build());
    }, verify: (game, tester) async {
      expect(
        find.byGame<TestGame>(),
        findsOneWidget,
      );
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      world.add(node);
      game.update(0);
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
    gameTester.testGameWidget('basic node add and remove',
        setUp: (game, _) async {
      await game.ready();
      await game.ensureAdd(WorldBuilder().withTrait(IntComponent).build());
    }, verify: (game, tester) async {
      expect(
        find.byGame<TestGame>(),
        findsOneWidget,
      );
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      world.add(node);
      game.update(0);
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
    gameTester.testGameWidget('node with child nodes add and remove',
        setUp: (game, _) async {
      await game.ready();
      await game.ensureAdd(WorldBuilder().withTrait(IntComponent).build());
    }, verify: (game, tester) async {
      expect(
        find.byGame<TestGame>(),
        findsOneWidget,
      );
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      node.addTrait(IntComponent(1));
      world.add(node);
      game.update(0);
      final nodesInWorld = world.query(Has([IntComponent]));
      expect(nodesInWorld.iterables.length, 1);
      expect(node.findNodeChildren().length, 0);
      final childNode = TestNode();
      node.add(childNode);
      game.update(0);
      expect(node.findNodeChildren().length, 1);
      childNode.removeFromParent();
      game.update(0);
      expect(node.findNodeChildren().length, 0);
    });
    gameTester.testGameWidget('add a node to the world',
        setUp: (game, _) async {
      await game.ready();
      await game.ensureAdd(WorldBuilder().withTrait(IntComponent).build());
    }, verify: (game, tester) async {
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      world.add(node);
      game.update(0);
      expect(world.nodesByType[TestNode]!.length, 1);
      expect(world.archetypeBuckets[Archetype([IntComponent])]!.length, 0);
    });

    gameTester.testGameWidget('wrongly add a node to the world',
        setUp: (game, _) async {
      await game.ready();
      await game.ensureAdd(WorldBuilder().withTrait(IntComponent).build());
    }, verify: (game, tester) async {
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      expect(() => world.registerNode(node), throwsA(isA<AssertionError>()));
    });
  });
}
