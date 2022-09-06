import 'package:backbone/archetype.dart';
import 'package:backbone/builders.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/trait.dart';
import 'package:backbone/node.dart';
import 'package:backbone/world.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'testGame.dart';

class IntComponent extends ATrait {
  final int value;
  IntComponent(this.value);
}

class StringTrait extends ATrait {
  final String value;
  StringTrait(this.value);
}

class TestNode extends ANode {
  TestNode() : super();
}

Future<void> basicSetup(TestGame game, WidgetTester _) async {
  await game.ready();
  await game.ensureAdd(WorldBuilder().withTrait(IntComponent).build());
}

void main() {
  group('Node', () {
    // Setup
    TestWidgetsFlutterBinding.ensureInitialized();
    final gameTester = FlameTester(() => TestGame());
    gameTester.testGameWidget('checks if a trait exists in this node',
        setUp: (TestGame game, WidgetTester _) async {
      await game.ready();
      await game.ensureAdd(WorldBuilder()
          .withTrait(IntComponent)
          .withTrait(StringTrait)
          .build());
    }, verify: (game, tester) async {
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      world.add(node);
      game.update(0);
      expect(node.hasTrait<IntComponent>(), false);
      node.addTrait(IntComponent(5));
      expect(node.hasTrait<IntComponent>(), true);
      final result = world.query(Has([IntComponent]), onlyLoaded: true);
      expect(result.length, 1);
      node.addTrait(StringTrait('SturdyKeep rocks'));
      expect(node.hasTrait<IntComponent>(), true);
      expect(node.hasTrait<StringTrait>(), true);
    });

    gameTester.testGameWidget('gets an existing trait or adds the one returned',
        setUp: (TestGame game, WidgetTester _) async {
      await game.ready();
      await game.ensureAdd(WorldBuilder()
          .withTrait(IntComponent)
          .withTrait(StringTrait)
          .build());
    }, verify: (game, tester) async {
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      world.add(node);
      game.update(0);
      expect(node.getOrElse<IntComponent>(() => IntComponent(5)),
          isA<IntComponent>());
      node.addTrait(StringTrait('SturdyKeep rocks'));
      expect(node.getOrElse<StringTrait>(() => StringTrait('5')).value,
          'SturdyKeep rocks');
    });
    gameTester.testGameWidget('get an existing trait otherwise throws',
        setUp: basicSetup, verify: (game, tester) async {
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      world.add(node);
      game.update(0);
      expect(() => node.get<IntComponent>(), throwsA(isA<Exception>()));
      node.addTrait(IntComponent(5));
      expect(node.get<IntComponent>(), isA<IntComponent>());
      expect(() => node.get<StringTrait>(), throwsA(isA<Exception>()));
    });
    gameTester.testGameWidget('get all child components of the node',
        setUp: basicSetup, verify: (game, tester) async {
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      world.add(node);
      game.update(0);
      expect(node.findChildren(), isEmpty);
      node.add(Component());
      game.update(0);
      expect(node.findChildren(), isNotEmpty);
      node.add(Component());
      game.update(0);
      expect(node.findChildren().length, 2);
    });
    gameTester.testGameWidget(
        'get the parent of the node, it might return null',
        setUp: basicSetup, verify: (game, tester) async {
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      world.add(node);
      game.update(0);
      expect(node.findNodeParent(), isNull);
      final nestedNode = TestNode();
      node.add(nestedNode);
      game.update(0);
      expect(nestedNode.findNodeParent(), isNotNull);
      final childOfchild = TestNode();
      nestedNode.add(childOfchild);
      expect(childOfchild.findNodeParent(), isA<TestNode>());
    });
    gameTester.testGameWidget('add and remove traits from a node',
        setUp: (TestGame game, WidgetTester _) async {
      await game.ready();
      await game.ensureAdd(
        WorldBuilder().withTrait(IntComponent).withTrait(StringTrait).build(),
      );
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
      expect(node.traits.isEmpty, true);
      expect(node.sortedTraits.isEmpty, true);
      node.addTrait(IntComponent(5));
      expect(node.traits.isEmpty, false);
      expect(node.sortedTraits.isEmpty, false);
      node.removeTrait<IntComponent>();
      expect(node.traits.isEmpty, true);
      expect(node.sortedTraits.isEmpty, true);
      node.addTrait(IntComponent(5));
      node.addTrait(StringTrait('Sturdy keep rulze'));
      expect(node.traits.length, 2);
      expect(node.sortedTraits.length, 2);
      node.removeTrait<IntComponent>();
      expect(node.traits.length, 1);
      expect(node.sortedTraits.length, 1);
      expect(node.sortedTraits.first.runtimeType, StringTrait);
    });
    gameTester.testGameWidget('get sorted traits from node',
        setUp: (TestGame game, WidgetTester _) async {
      await game.ready();
      await game.ensureAdd(
        WorldBuilder().withTrait(IntComponent).withTrait(StringTrait).build(),
      );
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
      var sortedTraits = node.sortedTraits;
      expect(sortedTraits.length, 0);
      node.addTrait(IntComponent(5));
      sortedTraits = node.sortedTraits;
      expect(sortedTraits.length, 1);
      node.addTrait(StringTrait('SturdyKeep rulez'));
      expect(node.sortedTraits.length, 2);
      expect(node.sortedTraits.first.runtimeType, IntComponent);
      expect(node.sortedTraits[1].runtimeType, StringTrait);
      node.removeTrait<IntComponent>();
      expect(node.sortedTraits.first.runtimeType, StringTrait);
    });
    gameTester.testGameWidget('basic empty node', setUp: basicSetup,
        verify: (game, tester) async {
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

    gameTester.testGameWidget('basic empty node', setUp: basicSetup,
        verify: (game, tester) async {
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
    gameTester.testGameWidget('basic node with component', setUp: basicSetup,
        verify: (game, tester) async {
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
        setUp: basicSetup, verify: (game, tester) async {
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
    gameTester.testGameWidget('basic node add and remove', setUp: basicSetup,
        verify: (game, tester) async {
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
      expect(() => node.addTrait(StringTrait('SturdyKeep rocks')),
          throwsA(isA<Exception>()));
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
        setUp: basicSetup, verify: (game, tester) async {
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
    gameTester.testGameWidget('add a node to the world', setUp: basicSetup,
        verify: (game, tester) async {
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
        setUp: basicSetup, verify: (game, tester) async {
      expect(game.children.length, 1);
      expect(game.children.first, isA<World>());
      final world = game.children.first as World;
      var node = TestNode();
      expect(() => world.registerNode(node), throwsA(isA<AssertionError>()));
    });
  });
}
