import 'package:backbone/builders.dart';
import 'package:backbone/filter.dart';
import 'package:backbone/node.dart';
import 'package:backbone/trait.dart';
import 'package:benchmark/benchmark.dart';

// Components
class TestTraitA extends ATrait {
  final int value;

  TestTraitA(this.value);
}

class TestTraitB extends ATrait {
  final int value;

  TestTraitB(this.value);
}

class TestTraitC extends ATrait {
  final int value;

  TestTraitC(this.value);
}

// Node
class TestNode extends ANode {
  TestNode();
}

BenchmarkFunction backbonePureMillion() {
  final realm = RealmBuilder()
      .withTrait(TestTraitA)
      .withTrait(TestTraitB)
      .withTrait(TestTraitC)
      .build();

  // Setup 100000 nodes
  for (var i = 0; i < 100000; i++) {
    final node = TestNode();
    node.realm = realm;
    node.isBackboneMounted = true;
    realm.registerNode(node);
    node.addTrait(TestTraitA(10));
  }

  return () {
    var result = 0;
    final fromQuery = realm.query(Has([TestTraitA]));
    for (var node in fromQuery) {
      final component = node.tryGet<TestTraitA>();
      result += component?.value ?? 0;
    }
    return result;
  };
}
